import boto3
import logging
from datetime import datetime
from dateutil import tz
from typing import List, Dict, Optional, Tuple, Union

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize the S3 client
s3_client = boto3.client("s3")


def list_object_versions(
    bucket_name: str, prefix: Optional[str] = None
) -> List[Dict[str, Union[str, int, bool, datetime]]]:
    """
    List all object versions in an S3 bucket for a given prefix.

    Args:
        bucket_name (str): Name of the S3 bucket.
        prefix (Optional[str]): Prefix to filter the objects. Defaults to None.

    Returns:
        List[Dict[str, Union[str, int, bool, datetime]]]: A list of dictionaries containing object version details.
    """

    def process_versions(versions: List[Dict]) -> List[Dict]:
        """Helper to process version entries."""
        return [
            {
                "Key": version["Key"],
                "VersionId": version["VersionId"],
                "IsLatest": version["IsLatest"],
                "LastModified": version["LastModified"],
                "Size": version["Size"],
                "IsDeleteMarker": False,
            }
            for version in versions
        ]

    def process_delete_markers(delete_markers: List[Dict]) -> List[Dict]:
        """Helper to process delete marker entries."""
        return [
            {
                "Key": delete_marker["Key"],
                "VersionId": delete_marker["VersionId"],
                "IsLatest": delete_marker["IsLatest"],
                "LastModified": delete_marker["LastModified"],
                "IsDeleteMarker": True,
            }
            for delete_marker in delete_markers
        ]

    versions = []
    paginator = s3_client.get_paginator("list_object_versions")
    pagination_config = {"PageSize": 1000}
    pages = paginator.paginate(
        Bucket=bucket_name, Prefix=prefix, PaginationConfig=pagination_config
    )

    for page in pages:
        if "Versions" in page:
            versions.extend(process_versions(page["Versions"]))
        if "DeleteMarkers" in page:
            versions.extend(process_delete_markers(page["DeleteMarkers"]))

    return versions


def convert_to_utc_components(date_string: str) -> Tuple[int, int, int, int, int, int]:
    """
    Convert a datetime string with timezone information to UTC components.

    Args:
        date_string (str): The input datetime string (e.g., "November 20, 2024, 19:07:25 (UTC+02:00)").

    Returns:
        Tuple[int, int, int, int, int, int]: A tuple of (year, month, day, hour, minute, second) in UTC.
    """
    cleaned_date_string = date_string.replace(" (", " ").replace(")", "")
    datetime_obj = datetime.strptime(cleaned_date_string, "%B %d, %Y, %H:%M:%S %Z%z")
    datetime_obj_utc = datetime_obj.astimezone(tz.tzutc())

    return (
        datetime_obj_utc.year,
        datetime_obj_utc.month,
        datetime_obj_utc.day,
        datetime_obj_utc.hour,
        datetime_obj_utc.minute,
        datetime_obj_utc.second,
    )


def filter_object_versions_by_date(
    object_versions: List[Dict[str, Union[str, bool, datetime]]],
    start_date: datetime,
    end_date: datetime,
) -> List[Dict]:
    """
    Filter object versions within a specified date range, excluding delete markers.

    Args:
        object_versions (List[Dict]): List of object versions.
        start_date (datetime): Start date for filtering.
        end_date (datetime): End date for filtering.

    Returns:
        List[Dict]: A list of filtered object versions.
    """
    return [
        obj
        for obj in object_versions
        if not obj.get("IsDeleteMarker", False)
        and start_date <= obj["LastModified"].replace(tzinfo=None) <= end_date
    ]


def copy_object_with_new_key(bucket_name: str, obj: Dict, prefix: str) -> None:
    """
    Copy an S3 object to a new key with a modified name.

    Args:
        bucket_name (str): Name of the S3 bucket.
        obj (Dict): Object details including Key, VersionId, IsLatest, and IsDeleteMarker.
        prefix (str): Target path prefix for the object.
    """
    # Skip delete markers
    if obj.get("IsDeleteMarker", False):
        logger.info(
            f"Skipping delete marker for object {obj['Key']} (version {obj['VersionId']})."
        )
        return

    key = obj["Key"]
    version_id = obj["VersionId"]
    is_latest = obj["IsLatest"]

    if is_latest:
        return

    if key.endswith(".snappy.parquet"):
        base_key = key[: -len(".snappy.parquet")]
        new_key = f"{base_key}_restored_{version_id}.snappy.parquet"
    else:
        file_extension = key.split(".")[-1]
        base_key = key[: -(len(file_extension) + 1)]
        new_key = f"{base_key}_restored_{version_id}.{file_extension}"

    try:
        s3_client.copy_object(
            Bucket=bucket_name,
            CopySource={"Bucket": bucket_name, "Key": key, "VersionId": version_id},
            Key=new_key,
        )
        logger.info(
            f"Copied object {key} (version {version_id}) to {new_key} in bucket {bucket_name}/{prefix}."
        )
    except Exception as e:
        logger.error(f"Failed to copy object {key} (version {version_id}): {str(e)}")
        raise


def lambda_handler(event: Dict, context: Optional[object]) -> bool:
    """
    AWS Lambda function entry point.

    Args:
        event (Dict): Event data containing S3 bucket name, target path, and date range.
        context (Optional[object]): Lambda context object.

    Returns:
        bool: True if the operation completes successfully.

    Raises:
        Exception: Propagates exceptions for AWS Lambda to handle.
    """
    try:
        bucket_name = event["s3_bucket"]
        prefix = f"{event['target_path']}/"

        object_versions = list_object_versions(bucket_name, prefix)
        logger.info(
            f"Retrieved {len(object_versions)} object versions from bucket {bucket_name} with prefix {prefix}."
        )

        start_date = datetime(*convert_to_utc_components(event["start_date"]))
        end_date = datetime(*convert_to_utc_components(event["end_date"]))

        filtered_objects = filter_object_versions_by_date(
            object_versions, start_date, end_date
        )
        logger.info(
            f"Filtered {len(filtered_objects)} object versions between {start_date} and {end_date}."
        )

        for obj in filtered_objects:
            copy_object_with_new_key(bucket_name, obj, prefix)

        logger.info("Successfully processed all objects.")
        return True

    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        raise
