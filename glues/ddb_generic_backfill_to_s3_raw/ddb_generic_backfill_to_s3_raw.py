# Generic backfill lambda (DynamoDB >> Athena/S3)
# BECAREFUL: double check function arguments before execution
import ast
import logging
import re
import sys
import time
from datetime import date
from datetime import datetime
from datetime import timezone
from typing import Optional

import awswrangler as wr
import boto3
import numpy as np
import pandas as pd
from awsglue.utils import getResolvedOptions
from flatten_json import flatten
from data_catalog import schemas


def setup_logger(
    name: Optional[str] = None,
    level: int = logging.INFO,
    format: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    filename: Optional[str] = None,
) -> logging.Logger:
    """
    Sets up a logger with the specified configuration.

    Parameters:
    - name (Optional[str]): Name of the logger. If None, the root logger is used.
    - level (int): Logging level (e.g., logging.INFO, logging.DEBUG).
    - format (str): Log message format.
    - filename (Optional[str]): If specified, logs will be written to this file. Otherwise, logs are written to stdout.

    Returns:
    - logging.Logger: Configured logger instance.
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)

    if filename:
        handler = logging.FileHandler(filename)
    else:
        handler = logging.StreamHandler(sys.stdout)

    handler.setLevel(level)
    formatter = logging.Formatter(format)
    handler.setFormatter(formatter)

    # To avoid duplicate handlers being added
    if not logger.hasHandlers():
        logger.addHandler(handler)

    return logger


logger = setup_logger("glue_migration")


def get_actual_dtypes(df) -> dict:
    """Takes a target dataframe, returns the schemas dict
    to be used while creating aws glue table,
    data types references from https://docs.aws.amazon.com/athena/latest/ug/data-types.html
    """
    result_dict = {}
    for column_name in df.columns:
        column_values = (
            df[column_name].replace("None", None).replace("", None).dropna().astype(str)
        )
        try:
            if "date" not in column_name.lower():
                column_values = pd.Series(
                    [
                        ast.literal_eval(entry.capitalize())
                        for entry in column_values.values
                    ]
                )
            else:
                raise Exception

        except Exception:
            try:
                column_values = pd.Series(
                    [pd.to_datetime(entry) for entry in column_values.values]
                )
            except Exception:
                pass

        try:
            if pd.api.types.is_integer_dtype(column_values):
                max_value = column_values.max()
                if max_value >= -(2**31) and max_value <= (2**31 - 1):
                    athena_dtype = "int"
                else:
                    athena_dtype = "bigint"
            elif pd.api.types.is_float_dtype(column_values):
                max_value = column_values.max()
                if str(max_value.dtype) == "float32":
                    athena_dtype = "float"
                else:
                    athena_dtype = "double"
            elif pd.api.types.is_bool_dtype(column_values):
                athena_dtype = "boolean"
            elif (
                pd.api.types.is_datetime64_any_dtype(column_values)
                and column_name != "date"
            ):
                if column_values.equals(column_values.dt.normalize()):
                    athena_dtype = "date"
                else:
                    athena_dtype = "timestamp"

            else:
                athena_dtype = "string"

        except Exception:
            athena_dtype = "string"

        result_dict[column_name] = athena_dtype

    return result_dict


def apply_iso_format(timestamp_column: pd.Series) -> pd.Series:
    """
    Apply ISO format to a timestamp column, trying multiple formats for each record.

    Args:
        timestamp_column (pd.Series): Series with timestamp data to be processed.

    Returns:
        pd.Series: Series with ISO formatted timestamps.
    """
    # Define the list of date formats to try
    date_formats = [
        "ISO8601",  # ISO8601 format
        "%m/%d/%Y %I:%M:%S %p",  # Ex: 7/30/2024 6:27:00 PM
        "%Y-%m-%d %H:%M:%S",  # Ex: 2024-07-30 18:27:00
        "%d-%m-%Y %H:%M:%S",  # Ex: 30-07-2024 18:27:00
    ]

    def parse_date(date_str):
        # Check if the value is numeric (likely a Unix timestamp)
        if isinstance(date_str, (int, float, str)) and str(date_str).isdigit():
            try:
                # Handle Unix timestamps in milliseconds
                if len(str(date_str)) > 10:
                    return pd.to_datetime(int(date_str), unit="ms", utc=True)
                # Handle Unix timestamps in seconds
                return pd.to_datetime(int(date_str), unit="s", utc=True)
            except Exception as e:
                raise ValueError(f"Unable to parse Unix timestamp: {date_str}") from e

        for date_format in date_formats:
            try:
                return pd.to_datetime(
                    date_str, format=date_format, utc=True, errors="raise"
                )
            except (ValueError, TypeError):
                continue

        raise ValueError(
            f"Error processing date {date_str} in {timestamp_column.name}: Unable to parse date with provided formats"
        )

    return timestamp_column.apply(parse_date)


def apply_schema(df: pd.DataFrame, schema: dict) -> pd.DataFrame:
    """
    Apply specified data types to the columns of a DataFrame based on the input schema

    Args:
        df (pd.DataFrame): DataFrame with generic data types.
        schema (dict): athena df schema containing columns' dtypes

    Returns:
        pd.DataFrame: DataFrame with data types specified in the schema.
    """

    # Drop duplicated columns (keep first occurrence only)
    if df.columns.duplicated().any():
        dup_cols = df.columns[df.columns.duplicated()].tolist()
        logger.warning(
            "Dropping duplicate columns (keeping first occurrence): %s", dup_cols
        )
        df = df.loc[:, ~df.columns.duplicated()]
        # also remove duplicates from schema
        for c in dup_cols:
            if c in schema:
                schema.pop(c, None)

    # Drop columns that include an underscore + >2 digits + underscore
    pattern = re.compile(r"_\d{3,}_")
    drop_cols = [col for col in df.columns if pattern.search(col)]
    if drop_cols:
        logger.info("Dropping columns matching pattern '_<3+digits>_': %s", drop_cols)
        # drop from dataframe
        df = df.drop(columns=drop_cols)
        # remove from schema if present
        for c in drop_cols:
            if c in schema:
                schema.pop(c, None)

    # Add any df columns missing in schema as strings (after dropping unwanted columns)
    for column in df.columns:
        if column not in schema.keys():
            logger.warning(f"{column} not in schema, consider as string.")
            schema[column] = "string"

    # Mapping schema types to pandas dtypes
    schema_type_mapping = {
        "int": "int32",
        "bigint": "int64",
        "string": "string[python]",
        "timestamp": "datetime64[ns]",
        "double": "float64",
        "boolean": "bool",
        "date": "datetime64[ns]",
    }

    for column, dtype in schema.items():
        if column in df.columns:
            pandas_dtype = schema_type_mapping.get(dtype, "string[python]")
            if dtype in ["timestamp", "date"]:
                # Handle Unix timestamps in milliseconds
                if df[column].dtype == "int64" or df[column].dtype == "float64":
                    df[column] = pd.to_datetime(df[column], unit="ms", utc=True)
                else:
                    df[column] = apply_iso_format(df[column])
            elif dtype in ["int", "bigint", "double"]:
                df[column] = pd.to_numeric(df[column], errors="coerce").fillna(0)
            else:
                df[column] = df[column].astype(pandas_dtype)

    return df, schema


def write_to_s3(
    df, target_athena_table, s3_bucket_name, wrangler_write_mode, athena_schema
):
    """
    Write the given DataFrame to S3 as a Parquet file.
    """

    path = f"s3://{s3_bucket_name}/{target_athena_table}/"
    logger.info("Athena schema:  %s", athena_schema)
    logger.info("Pandas DF shape:  %s", str(df.shape))
    logger.info("Uploading to S3 bucket:  %s", s3_bucket_name)
    logger.info("Uploading to S3 location:  %s", path)

    try:
        wr.s3.to_parquet(
            df=df,
            path=path,
            index=False,
            dataset=True,
            mode=wrangler_write_mode,
            compression="snappy",
            partition_cols=["date"],
            database="datalake_raw",
            table=target_athena_table,
            schema_evolution="true",
            dtype=athena_schema,
        )
        logger.info("Uploaded to S3 location: %s", path)
    except Exception as e:
        logger.error("Failed uploading to S3 location: %s", path)
        logger.error("Exception occurred: %s", e)
        raise


def process_json(json_string, dyanmo_partition_column):
    """
    Parse and flatten the JSON data.
    """
    frames = []
    try:
        for item in json_string:
            flat_json = flatten(item)
            frames.append(flat_json)
        df = pd.DataFrame(frames)

        # Drop totally empty columns
        df = df.dropna(axis=1, how="all")

        # Fill empty strings
        df = df.replace("", np.nan)

        # Adjust column names
        df = df.add_prefix("dynamodb_NewImage_")
        try:
            df[f"dynamodb_Keys_{dyanmo_partition_column}_S"] = df[
                f"dynamodb_NewImage_{dyanmo_partition_column}_S"
            ]
        except KeyError:
            error_msg = f"[{dyanmo_partition_column}] is not the right dynamo table partitioning id, please correct and try again."
            logger.error(error_msg)
            raise error_msg

        # Convert CamelCase to snake_case
        df.columns = [
            re.sub("(?!^)([A-Z]+)", r"_\1", col).lower().replace("__", "_")
            for col in df.columns
        ]

        # replace dashes '-' with '' in column names
        df.columns = [col.replace("-", "") for col in df.columns]

        # Add partitioning and metadata columns
        if "dynamodb_new_image_updated_at_n" in df.columns:
            df["date"] = pd.to_datetime(
                df["dynamodb_new_image_updated_at_n"], unit="ms"
            ).dt.strftime("%Y-%m-%d")
        else:
            df["date"] = date.today().strftime("%Y-%m-%d")
        df["event_source"] = "aws:backfill"
        df["timestamp_extracted"] = datetime.now(timezone.utc)

        return df
    except Exception as e:
        logger.error("Error processing JSON data: %s", e)
        raise


def main():
    try:
        # STEP_1: Initialize global variables
        args = getResolvedOptions(
            sys.argv,
            [
                "TARGET_DYNAMO_TABLE",
                "DYNAMO_PRTITION_COLUMN",
                "INCREMENTAL_MODE",
                "RESULT_ATHENA_TABLE",
                "S3_BUCKET_NAME",
                "WRANGLER_WRITE_MODE",
                "START_DATE",
                "AUTO_SCHEMA",
            ],
        )
        dynamo_table_name = args["TARGET_DYNAMO_TABLE"]
        dyanmo_partition_column = args["DYNAMO_PRTITION_COLUMN"]
        target_athena_table = args["RESULT_ATHENA_TABLE"]
        s3_bucket_name = args["S3_BUCKET_NAME"]
        wrangler_write_mode = args["WRANGLER_WRITE_MODE"]
        start_date = args.get("START_DATE")
        incremental_mode = ast.literal_eval(args["INCREMENTAL_MODE"])
        auto_schema = ast.literal_eval(args["AUTO_SCHEMA"])

        if wrangler_write_mode not in {
            "append",
            "overwrite_partitions",
        }:  # Adjust to allowed modes
            raise ValueError(
                "Invalid write mode. Please use 'append' or 'overwrite_partitions'."
            )

        logger.info(
            "Starting migration from DynamoDB table: %s to Athena table: %s stored in s3://%s",
            dynamo_table_name,
            target_athena_table,
            s3_bucket_name,
        )

        # STEP_2: Fetch data from DynamoDB
        client = boto3.client("dynamodb")
        scan_kwargs = {"TableName": dynamo_table_name}

        # STEP_3: Add time filter if provided
        try:
            start_date_obj = datetime.strptime(start_date, "%d-%m-%Y")
            start_epoch_time = int(time.mktime(start_date_obj.timetuple()))
            scan_kwargs["FilterExpression"] = "updatedAt > :ts"
            scan_kwargs["ExpressionAttributeValues"] = {
                ":ts": {"N": str(start_epoch_time)}
            }
        except ValueError:
            logger.warning(
                f"Start date ({start_date}) is not formatted in %d-%m-%Y, backfilling without filters."
            )

        done = False
        start_key = None
        total_items = 0
        total_rows = 0

        if incremental_mode:
            logger.info(
                "\nIncremental mode ON, each scan page will be saved separately."
            )
            # STEP_4: Pagination loop for scanning DynamoDB
            while not done:
                # If table data is bigger than 1 iteration, write mode shifted to append.
                if start_key:
                    scan_kwargs["ExclusiveStartKey"] = start_key
                    wrangler_write_mode = "append"

                logger.info("Scanning DynamoDB...")
                json_string = client.scan(**scan_kwargs)
                total_items += len(json_string["Items"])

                df = process_json(json_string["Items"], dyanmo_partition_column)

                # STEP_5: Generate Athena schema and apply it to the DataFrame
                if auto_schema:
                    athena_schema = get_actual_dtypes(df)
                else:
                    athena_schema = schemas[target_athena_table]
                df, schema = apply_schema(df, athena_schema)

                total_rows += df.shape[0]

                # STEP_6: Load DataFrame to S3
                write_to_s3(
                    df,
                    target_athena_table,
                    s3_bucket_name,
                    wrangler_write_mode,
                    schema,
                )

                logger.info("Writing to S3 succeeded, proceeding to next iteration...")
                start_key = json_string.get("LastEvaluatedKey", None)
                done = start_key is None
        else:
            logger.info("\nIncremental mode OFF, all scan pages will be saved in bulk.")
            all_pages = []
            # STEP_4: Pagination loop for scanning DynamoDB
            while not done:
                # If table data is bigger than 1 iteration.
                if start_key:
                    scan_kwargs["ExclusiveStartKey"] = start_key

                logger.info("Scanning DynamoDB...")
                json_string = client.scan(**scan_kwargs)
                all_pages.extend(json_string["Items"])
                total_items += len(json_string["Items"])

                start_key = json_string.get("LastEvaluatedKey", None)
                done = start_key is None

            df = process_json(all_pages, dyanmo_partition_column)

            # STEP_5: Generate Athena schema and apply it to the DataFrame
            if auto_schema:
                athena_schema = get_actual_dtypes(df)
            else:
                athena_schema = schemas[target_athena_table]
            df, schema = apply_schema(df, athena_schema)

            total_rows += df.shape[0]

            # STEP_6: Load DataFrame to S3
            write_to_s3(
                df,
                target_athena_table,
                s3_bucket_name,
                wrangler_write_mode,
                schema,
            )

            logger.info("Writing to S3 succeeded, proceeding to next iteration...")

        logger.info("Total items read from DynamoDB: %d", total_items)
        logger.info("Total rows written to S3/Athena: %d", total_rows)

        res = (
            f"[Success] Finished processing migration from DynamoDB table: {dynamo_table_name} "
            f"to Athena table: {target_athena_table} stored in s3://{s3_bucket_name}"
        )
        logger.info(res)
        return res
    except Exception as e:
        logger.error("Error in Glue job: %s", e)
        raise


if __name__ == "__main__":
    main()
