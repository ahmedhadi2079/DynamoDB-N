import sys
import time
import json
import boto3
import asyncio
import logging
from botocore.exceptions import ClientError
from awsglue.utils import getResolvedOptions
from datetime import datetime, timezone, timedelta

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def retrieve_args():
    try:
        logger.info(f"Retrieving parameters...")
        args = getResolvedOptions(
            sys.argv,
            [
                "S3_BUCKET_NAME",
                "IAM_ROLE_ARN",
                "KMS_KEY_ID",
                "EXPORT_ONLY",
                "RDS_ENVIRONMENT",
                "DB_CLUSTER_IDENTIFIER",
                "RDS_AWS_REGION",
                "RDS_AWS_ACCOUNT_ID",
            ],
        )
        s3_bucket_name = args["S3_BUCKET_NAME"]
        db_cluster_identifier = args["DB_CLUSTER_IDENTIFIER"]
        export_only = args["EXPORT_ONLY"]

        # logging parameters
        logger.info(f"S3 Bucket Name: {s3_bucket_name}")
        logger.info(f"Export Only Tables: {export_only}")
        logger.info(f"DB Cluster Identifier: {db_cluster_identifier}")

        return args

    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e


def create_db_snapshot(args, rds_client, snapshot_identifier):
    try:
        db_cluster_identifier = args["DB_CLUSTER_IDENTIFIER"]

        logger.info(f"Creating DB cluster snapshot: {snapshot_identifier}")
        rds_client.create_db_cluster_snapshot(
            DBClusterSnapshotIdentifier=snapshot_identifier,
            DBClusterIdentifier=db_cluster_identifier,
            Tags=[
                {"Key": "CreatedBy", "Value": "GlueJob"},
                {"Key": "GlueJobName", "Value": "datalake-ddb-integration-rds-trigger-daily-snapshot-glue"}
            ]
        )
        logger.info("Triggering RDS export task...")
    except ClientError as e:
        logger.error(f"Failed to Create RDS Snapshot: {e}")
        raise e
    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e


def export_old_snapshot_to_s3(snapshot_id, args, rds_client):
    try:
        export_task_identifier = f"backup-export-{snapshot_id}-{int(time.time())}"
        aws_region = args["RDS_AWS_REGION"]
        aws_account_id = args["RDS_AWS_ACCOUNT_ID"]
        s3_bucket_name = args["S3_BUCKET_NAME"]
        iam_role_arn = args["IAM_ROLE_ARN"]
        kms_key_id = args["KMS_KEY_ID"]
        rds_env = args["RDS_ENVIRONMENT"]

        source_arn = f"arn:aws:rds:{aws_region}:{aws_account_id}:cluster-snapshot:{snapshot_id}"
        s3_prefix = f"temporal/{rds_env}/backup/{snapshot_id}/"

        logger.info(f"Exporting old snapshot {snapshot_id} to S3 before deletion...")

        response = rds_client.start_export_task(
            ExportTaskIdentifier=export_task_identifier,
            SourceArn=source_arn,
            S3BucketName=s3_bucket_name,
            IamRoleArn=iam_role_arn,
            KmsKeyId=kms_key_id,
            S3Prefix=s3_prefix
        )

        logger.info(f"Export task started for {snapshot_id}, task ID: {export_task_identifier}")
        logger.info(f"Export task status: {response.get('Status')}")
        return export_task_identifier

    except Exception as e:
        logger.error(f"Failed to export snapshot {snapshot_id} before deletion: {e}")
        raise


def delete_old_snapshots(rds_client, cluster_id, args, keep_most_recent=90):
    try:
        logger.info("Checking for all manual DB cluster snapshots...")

        # Retrieve all manual snapshots for the cluster
        snapshots = rds_client.describe_db_cluster_snapshots(
            DBClusterIdentifier=cluster_id,
            SnapshotType='manual'
        )['DBClusterSnapshots']

        if len(snapshots) <= keep_most_recent:
            logger.info(f"Total manual snapshots: {len(snapshots)} — no deletion needed.")
            return

        # Sort snapshots by creation time (oldest first)
        snapshots.sort(key=lambda s: s['SnapshotCreateTime'])

        # Determine how many need deletion
        excess_count = len(snapshots) - keep_most_recent
        snapshots_to_delete = snapshots[:excess_count]

        for snapshot in snapshots_to_delete:
            snapshot_id = snapshot['DBClusterSnapshotIdentifier']
            logger.info(f"Deleting snapshot: {snapshot_id}")
            rds_client.delete_db_cluster_snapshot(DBClusterSnapshotIdentifier=snapshot_id)

        logger.info(f"Deleted {len(snapshots_to_delete)} old snapshots to stay within quota.")

    except Exception as e:
        logger.error(f"Failed to clean up old snapshots: {e}")
        raise


async def wait_for_snapshot(rds_client, snapshot_identifier):
    try:
        logger.info(f"Waiting for snapshot {snapshot_identifier} to become available...")

        sleep_time = 30  # seconds
        while True:
            response = await asyncio.to_thread(
                rds_client.describe_db_cluster_snapshots,
                DBClusterSnapshotIdentifier=snapshot_identifier
            )
            status = response['DBClusterSnapshots'][0]['Status']
            if status == 'available':
                logger.info(f"Snapshot {snapshot_identifier} is now available.")
                break
            elif status in ['failed', 'deleted']:
                raise Exception(f"Snapshot creation failed. Status: {status}")
            else:
                logger.info(f"Snapshot status: {status}. Retrying in {sleep_time} seconds...")
                await asyncio.sleep(30)
    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e


def start_export_task(args, rds_client, export_task_identifier, snapshot_identifier):
    try:
        aws_region = args["RDS_AWS_REGION"]
        aws_account_id = args["RDS_AWS_ACCOUNT_ID"]
        rds_env = args["RDS_ENVIRONMENT"]
        export_only = args["EXPORT_ONLY"]
        s3_bucket_name = args["S3_BUCKET_NAME"]
        iam_role_arn = args["IAM_ROLE_ARN"]
        kms_key_id = args["KMS_KEY_ID"]

        source_arn = f"arn:aws:rds:{aws_region}:{aws_account_id}:cluster-snapshot:{snapshot_identifier}"
        s3_prefix = f"temporal/{rds_env}/export/{time.strftime('%Y-%m-%d')}"

        logger.info(f"Starting export task with identifier: {export_task_identifier}")

        if export_only:
            export_only_list = json.loads(export_only)
            response = rds_client.start_export_task(
                ExportTaskIdentifier=export_task_identifier,
                SourceArn=source_arn,
                S3BucketName=s3_bucket_name,
                IamRoleArn=iam_role_arn,
                KmsKeyId=kms_key_id,
                S3Prefix=s3_prefix,
                ExportOnly=export_only_list
            )

            logger.info(f"Export task triggered successfully: {response}")
        else:
            logger.error("Empty export only list!")
            raise ValueError("ExportOnly list is empty!")

    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e


async def main():
    # Step 1: Initialize variables
    args = retrieve_args()
    rds_env = args["RDS_ENVIRONMENT"]
    db_cluster_identifier = args["DB_CLUSTER_IDENTIFIER"]
    export_task_identifier = f"data-team-export-{rds_env}-temporal-{time.strftime('%Y-%m-%d-%H-%M')}"
    snapshot_identifier = f"data-team-snapshot-{rds_env}-temporal-{time.strftime('%Y-%m-%d-%H-%M')}"

    # Step 2: open connection to RDS
    rds_client = boto3.client('rds')

    # 🧼 Step: Delete old snapshots to stay under quota
    delete_old_snapshots(rds_client, db_cluster_identifier, args)
    # Step 3: Create Database Snapshot
    create_db_snapshot(args, rds_client, snapshot_identifier)

    # Step 4: Wait until the snapshot becomes available
    await wait_for_snapshot(rds_client, snapshot_identifier)

    # Step 5: Create export job from RDS Snapshot to S3 Bucket
    start_export_task(args, rds_client, export_task_identifier, snapshot_identifier)


if __name__ == "__main__":
    asyncio.run(main())
