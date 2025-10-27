import ast
import base64
import io
import json
import logging
import os
import re
import sys
from datetime import date
from datetime import datetime
from typing import Optional

import awswrangler as wr
import boto3
import numpy as np
import pandas as pd
from botocore.exceptions import ClientError
from flatten_json import flatten


class DataProcessor:
    def __init__(self, target_athena_glue_table):
        self.target_athena_glue_table = target_athena_glue_table
        self.database = "datalake_raw"
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        self.s3_raw = os.environ.get("S3_RAW")
        self.s3_athena = os.environ.get("S3_ATHENA")
        self.glue_client = boto3.client("glue")
        self.athena_client = boto3.client("athena")
        self.s3_resource = boto3.resource("s3")

    def set_pandas_display_options(self) -> None:
        """Set pandas display options."""
        display = pd.options.display

        display.max_columns = 1000
        display.max_rows = 1000
        display.max_colwidth = 199
        display.width = 1000

    def get_schema(self, df, datetime_columns):
        """
        Accepts a Pandas Dataframe, casts each column to correct datatype, and produces
        the Athena schema for each column in a dict.
        :param df: The Pandas Dataframe
        :return: The athena schema and new pandas dataframe
        """
        athena_schema = {}

        for c in df.columns:
            c_list = c.split("_")
            data_type_len = len(c_list)
            data_type = c_list[data_type_len - 1].lower()
            try:
                if data_type == "bool":
                    athena_schema[c] = "boolean"
                    df[c] = df[c].astype(bool)
                elif data_type == "n":
                    try:
                        if c in datetime_columns:
                            athena_schema[c] = "timestamp"
                            df[c] = pd.to_datetime(df[c], unit="ms")
                        else:
                            athena_schema[c] = "int"
                            df[c] = pd.to_numeric(df[c], downcast="integer")
                            df[c] = df[c].fillna(0).astype(np.int64)
                    except ValueError as e:
                        self.logger.info(e)
                        athena_schema[c] = "string"
                        continue
                elif data_type == "s" and "_date_" in c:
                    if "_date_time" in c:
                        athena_schema[c] = "timestamp"
                    else:
                        athena_schema[c] = "date"
                    df[c] = df[c].astype(str)
                elif c == "dynamodb_ApproximateCreationDateTime":
                    athena_schema[c] = "timestamp"
                    df[c] = pd.to_datetime(df[c], unit="ms")
                else:
                    athena_schema[c] = "string"
                    df[c] = df[c].astype(str)
            except Exception as e:
                self.logger.error("column:  %s", c)
                self.logger.error("column value:  %s", df[c])
                self.logger.error("data_type:  %s", data_type)
                self.logger.error("Exception occurred:  %s", e)
                return e

        self.logger.info("Finished setting up schema.")
        df["date"] = date.today().strftime("%Y-%m-%d")
        athena_schema["date"] = "date"

        df["timestamp_extracted"] = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        athena_schema["timestamp_extracted"] = "timestamp"
        df["timestamp_extracted"] = pd.to_datetime(df["timestamp_extracted"])

        return athena_schema, df

    def parse_payload(self, event):
        """
        Accepts event
        :param event: Event from stream
        :return: A pandas dataframe
        """
        frames = []

        for record in event["Records"]:
            try:
                self.logger.info("Base 64 decoding data...")
                payload = base64.b64decode(record["kinesis"]["data"])
                payload = payload.decode("UTF-8")
                self.logger.info("Successfully decoded payload!")
            except Exception as e:
                self.logger.error("Event:  %s", event)
                self.logger.error("Payload:  %s", payload)
                self.logger.error("Exception occurred:  %s", e)
                return e

            try:
                self.logger.info("Dealing with empty child elements...")
                payload = payload.replace("{}", "null").replace("[]", "null")
                self.logger.info("Successfully dealt with empty child elements!")
            except Exception as e:
                self.logger.error("Payload:  %s", payload)
                self.logger.error("Exception occurred:  %s", e)
                return e

            try:
                # Flatten JSON and convert to pandas
                self.logger.info("Flattening JSON...")
                json_payload = json.loads(payload)
                flat_json = flatten(json_payload)
                self.logger.info("Success in flattening JSON!")
                frames.append(flat_json)
            except Exception as e:
                self.logger.error("Flat JSON:  %s", flat_json)
                self.logger.error("Exception occurred:  %s", e)
                return e

        final_df = pd.DataFrame(frames)
        # fix nulls with empty string
        final_df = final_df.fillna("")
        return final_df

    def fallback_write_to_s3(self, tempdf: pd.DataFrame, athena_table: str, s3_bucket: str):
        """
        Fallback Boto3 writing to S3.
        :param tempdf: Pandas DF to write to S3
        :type tempdf: pd.DataFrame
        :param athena_table: Table to write to (it will be suffixed with _fallback)
        :type athena_table: str
        :param s3_bucket: The S3 Bucket to write to
        :type s3_bucket: str
        """

        dt = datetime.utcnow()
        date = dt.strftime("%Y%m%d")
        time = dt.strftime("%H%M%S")

        csv_buffer = io.StringIO()
        tempdf.to_csv(csv_buffer)
        # s3_resource = boto3.resource("s3")

        fallback_path = f"{athena_table}_fallback/{date}/{time}.csv"
        self.logger.info(f"Error occurred so uploading to S3 location: {fallback_path} as CSV...")

        self.s3_resource.Object(s3_bucket, fallback_path).put(Body=csv_buffer.getvalue())

    def write_to_s3(self, tempdf, athena_table, athena_schema, partition_columns, s3_bucket=None):
        """
        AWS Data Wrangler writing to S3
        :param tempdf: Pandas DF to write to S3
        :param athena_table: Table to write to
        :param athena_schema: Athena Schema
        :param partition_columns: The columns to use for partitioning the data
        :return: result
        """
        if s3_bucket is None:
            s3_bucket = self.s3_raw

        self.logger.info("Uploading to S3 bucket:  %s", s3_bucket)
        self.logger.info("Pandas DF shape:  %s", tempdf.shape)
        path = "s3://" + s3_bucket + "/" + athena_table + "/"
        self.logger.info("Uploading to S3 location:  %s", path)

        columns = []
        for col in tempdf.columns:
            x = re.sub("(?!^)([A-Z]+)", r"_\1", col).lower().replace("__", "_")
            columns.append(x)
        tempdf.columns = columns
        try:
            # issue write command to s3
            res = wr.s3.to_parquet(
                df=tempdf,
                path=path,
                index=False,
                dataset=True,
                mode="append",
                compression="snappy",
                partition_cols=partition_columns,
            )
            return res, path
        except Exception as e:
            self.logger.error("Athena schema:  %s", athena_schema)
            self.logger.error("Failed uploading to S3 location:  %s", path)
            self.logger.error("Exception occurred:  %s", e)

            try:
                self.logger.info("Writing to fallback...")
                self.fallback_write_to_s3(tempdf, athena_table, s3_bucket)
            except Exception as e2:
                self.logger.error(f"Failed fallback with Exception: {e2}")

            return e

    def get_glue_table_columns(self, table_name):
        """
        Retrieves column names from the AWS Glue Data Catalog for a given table.
        Args:
            table_name (str): The name of the table.
        Returns:
            list: A list of column names.
        """
        try:
            # Get table metadata
            response = self.glue_client.get_table(DatabaseName=self.database, Name=table_name)
        except ClientError as e:
            if e.response["Error"]["Code"] == "EntityNotFoundException":
                print(f"Table '{table_name}' not found in database '{self.database}'.")
                return None
            else:
                print(f"An error occurred: {e.response['Error']['Message']}")
                return None
        except Exception as e:
            print(f"An error occurred: {str(e)}")
            return None
        # Extract column names
        columns = [col["Name"] for col in response["Table"]["StorageDescriptor"]["Columns"]]
        return columns

    def delete_glue_table(self, table_name):
        """
        Deletes a table from the AWS Glue Data Catalog.
        Args:
            table_name (str): The name of the table to delete.
        Returns:
            bool: True if the table is successfully deleted, False otherwise.
        """
        try:
            # Delete the table
            self.glue_client.delete_table(DatabaseName=self.database, Name=table_name)
            self.logger.info(f"Table {table_name} deleted successfully.")
            return True
        except self.glue_client.exceptions.EntityNotFoundException as e:
            self.logger.info(f"Table {table_name} not found in database {self.database}.")
            self.logger.error("EntityNotFoundException occurred:  %s", e)
            return False
        except Exception as e:
            self.logger.error("Exception occurred:  %s", e)
            return False

    def create_athena_table(self, table_name, schema, column_comments, partition_keys, s3_bucket=None):
        if s3_bucket is None:
            s3_bucket = self.s3_raw
        s3_location = "s3://" + s3_bucket + "/" + table_name + "/"
        self.logger.info("Raw bucket path:  %s", s3_location)
        self.logger.info("Athena bucket Name:  %s", self.s3_athena)
        # Construct the CREATE TABLE query with schema and column comments
        create_table_query = f"""
        CREATE EXTERNAL TABLE IF NOT EXISTS {table_name} (
            {", ".join([f"{column} {data_type} COMMENT '{column_comments.get(column)}'" for column, data_type in schema.items()])}
        )
        {"PARTITIONED BY (" + ", ".join([f"{column} {data_type}" for column, data_type in partition_keys.items()]) + ")" if partition_keys else ""}
        ROW FORMAT SERDE "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
        STORED AS INPUTFORMAT "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
        OUTPUTFORMAT "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
        LOCATION "{s3_location}"
        TBLPROPERTIES ("classification"="parquet", "compressionType"="snappy", "projection.enabled"="false", "typeOfData"="file")
        """
        # Execute the query
        response = self.athena_client.start_query_execution(
            QueryString=create_table_query,
            QueryExecutionContext={"Database": self.database},
            ResultConfiguration={"OutputLocation": f"s3://{self.s3_athena}/output/"},
        )
        self.logger.info("Athena table creation response:  %s", response)

    def athena_table_metadata_refresh(self, table_name):
        query = f"MSCK REPAIR TABLE {self.database}.{table_name}"
        self.logger.info("Athena MSCK query:  %s", query)
        # Execute the query
        response = self.athena_client.start_query_execution(
            QueryString=query,
            ResultConfiguration={"OutputLocation": f"s3://{self.s3_athena}/output/"},
        )
        self.logger.info("MSCK repair table response:  %s", response)


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


def get_actual_dtypes(df) -> dict:
    """Takes a target dataframe, returns the schemas dict
    to be used while creating aws glue table,
    data types references from https://docs.aws.amazon.com/athena/latest/ug/data-types.html
    """
    result_dict = {}
    for column_name in df.columns:
        column_values = df[column_name].replace("None", None).replace("", None).dropna().astype(str)
        try:
            if "date" not in column_name.lower():
                column_values = pd.Series([ast.literal_eval(entry.capitalize()) for entry in column_values.values])
            else:
                raise Exception

        except Exception:
            try:
                column_values = pd.Series([pd.to_datetime(entry) for entry in column_values.values])
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
            elif pd.api.types.is_datetime64_any_dtype(column_values) and column_name != "date":
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


def apply_schema(df: pd.DataFrame, schema: dict) -> pd.DataFrame:
    """
    Apply specified data types to the columns of a DataFrame based on the input schema

    Args:
        df (pd.DataFrame): DataFrame with generic data types.
        schema (dict): athena df schema containing columns' dtypes

    Returns:
        pd.DataFrame: DataFrame with data types specified in the schema.
    """

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
            if dtype in ["timestamp", "date"] and column != "date":
                df[column] = apply_iso_format(df[column])
            elif dtype in ["int", "bigint", "double"]:
                df[column] = pd.to_numeric(df[column], errors="coerce").fillna(0)
            else:
                df[column] = df[column].astype(pandas_dtype)

    return df


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
        for date_format in date_formats:
            try:
                return pd.to_datetime(date_str, format=date_format, utc=True, errors="raise")
            except (ValueError, TypeError):
                continue
        raise ValueError(f"Error processing date {date_str} in {timestamp_column.name}: Unable to parse date with provided formats")

    return timestamp_column.apply(parse_date)
