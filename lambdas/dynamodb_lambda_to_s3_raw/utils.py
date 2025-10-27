import sys
import io
import os
import re
import json
import uuid
import base64
import logging
import data_catalog
import awswrangler as wr
import pandas as pd

from datetime import date
from datetime import datetime
from datetime import timezone
from dateutil import parser
from functools import wraps
from flatten_json import flatten
from typing import Any, Callable, Dict


logger = logging.getLogger()
logger.setLevel(logging.INFO)


DEFAULT_ATTRIBUTES = {
    "service": "dynamodb-to-s3",
    "environment": os.environ.get("ENVIRONMENT", "unknown"),
}


def log_event(level: str, event: str, message: str = "", **kwargs):
    """
    Logs an event with structured JSON format for Datadog.
    :param level: Log level ('info', 'error', 'warning', 'debug')
    :param event: A descriptive name of the event
    :param message: Optional message to include in the log
    :param kwargs: Additional attributes to include in the log
    """
    log_object = {
        **DEFAULT_ATTRIBUTES,
        "level": level.lower(),
        "event": event,
        "trace_id": str(uuid.uuid4()),
        "message": message,
        **kwargs,
    }

    log_json = json.dumps(log_object)

    log_methods = {
        "error": logger.error,
        "warning": logger.warning,
        "debug": logger.debug,
        "info": logger.info,
    }

    # Call appropriate logger method
    log_methods.get(level.lower(), logger.info)(log_json)


def log_function(func: Callable):
    @wraps(func)
    def wrapper(*args, **kwargs):
        func_name = func.__name__
        log_event("info", f"{func_name}_start", f"Entering function: {func_name}")
        try:
            result = func(*args, **kwargs)
            log_event("info", f"{func_name}_end", f"Exiting function: {func_name}")
            return result
        except Exception as e:
            log_event(
                "error", f"{func_name}_exception", f"Exception: {e}", exception=str(e)
            )
            raise

    return wrapper


def camel_to_snake_case(column_name):
    """
    Converts a string from CamelCase to snake_case.
    """
    return re.sub(r"(?!^)([A-Z]+)", r"_\1", column_name).lower().replace("__", "_")


@log_function
def parse_payload(event):
    """
    Accepts an event and returns a pandas DataFrame with snake_case column names.
    """
    frames = []

    for record in event["Records"]:
        log_event("info", "decode_payload", "Decoding payload from Base64...")
        payload = base64.b64decode(record["kinesis"]["data"]).decode("UTF-8")
        payload = payload.replace("{}", "null").replace("[]", "null")
        json_payload = json.loads(payload)

        if "OldImage" in json_payload.get("dynamodb", {}):
            del json_payload["dynamodb"]["OldImage"]

        flat_json = flatten(json_payload)
        frames.append(flat_json)

    final_df = pd.DataFrame(frames)

    # Drop totally empty columns
    final_df = final_df.dropna(axis=1, how="all")

    # Fill empty strings
    final_df = final_df.replace("", None)

    final_df.columns = [camel_to_snake_case(col) for col in final_df.columns]

    # replace dashes '-' with '' in column names
    final_df.columns = [col.replace("-", "") for col in final_df.columns]

    if "date" not in final_df.columns:
        final_df["date"] = date.today().strftime("%Y-%m-%d")

    if "timestamp_extracted" not in final_df.columns:
        final_df["timestamp_extracted"] = datetime.now(timezone.utc)

    return final_df


@log_function
def parse_date(value) -> pd.Timestamp:
    """
    Parse a single value into a valid datetime object.
    """
    if pd.isna(value):
        return pd.NaT

    if is_unix_timestamp(value):
        return parse_unix_timestamp(value)

    return parse_string_date(str(value))


@log_function
def is_unix_timestamp(value) -> bool:
    if isinstance(value, (int, float)) or str(value).replace(".", "", 1).isdigit():
        return True
    return False


@log_function
def parse_unix_timestamp(value) -> pd.Timestamp:
    value = float(value)
    log_event("info", "parse_unix_timestamp_input", f"Parsing value: {value}")
    if value > 1e12:
        return pd.to_datetime(int(value), unit="ms", errors="coerce", utc=True)
    else:
        return pd.to_datetime(int(value), unit="s", errors="coerce", utc=True)


@log_function
def parse_string_date(value: str) -> pd.Timestamp:
    """
    Use dateutil.parser to automatically parse string dates.
    """
    try:
        return pd.to_datetime(parser.parse(value), errors="coerce", utc=True)
    except (ValueError, TypeError):
        return pd.NaT


@log_function
def apply_schema(df: pd.DataFrame, schema: dict) -> pd.DataFrame:
    """
    Apply specified data types to the columns of a DataFrame based on the input schema.

    Args:
        df (pd.DataFrame): DataFrame with generic data types.
        schema (dict): Athena schema containing columns' dtypes.

    Returns:
        pd.DataFrame: DataFrame with data types specified in the schema.
    """
    schema_type_mapping = {
        "int": "int32",
        "bigint": "int64",
        "string": "string[python]",
        "timestamp": "datetime64[ns, UTC]",
        "double": "float64",
        "boolean": "bool",
        "date": "datetime64[ns]",
    }

    # Drop duplicated columns (keep first occurrence only)
    if df.columns.duplicated().any():
        dup_cols = df.columns[df.columns.duplicated()].tolist()
        log_event(
            "info",
            "Drop duplicate column",
            f"Dropping duplicate columns (keeping first occurrence): {dup_cols}",
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
        log_event(
            "info",
            "Drop redundant column",
            f"Dropping columns matching pattern '_<3+digits>_': {drop_cols}",
        )
        # drop from dataframe
        df = df.drop(columns=drop_cols)
        # remove from schema if present
        for c in drop_cols:
            if c in schema:
                schema.pop(c, None)

    # Add any df columns missing in schema as strings (after dropping unwanted columns)
    for column in df.columns:
        if column not in schema.keys():
            log_event(
                "info",
                "Unknown column",
                f"{column} not in schema, consider as string.",
            )
            schema[column] = "string"

    df = apply_type_conversions(df, schema, schema_type_mapping)

    return df


@log_function
def apply_type_conversions(
    df: pd.DataFrame, schema: dict, schema_type_mapping: dict
) -> pd.DataFrame:
    """
    Apply type conversions to DataFrame columns based on the schema.
    """
    for column, dtype in schema.items():
        if column in df.columns:
            pandas_dtype = schema_type_mapping.get(dtype, "string[python]")

            if dtype in ["timestamp", "date"]:
                log_event(
                    "info",
                    "before_datetime_conversion",
                    f"Before conversion: {df[column].head(5)}",
                )
                df[column] = handle_datetime_column(df[column])
                log_event(
                    "info",
                    "after_datetime_conversion",
                    f"After conversion: {df[column].head(5)}",
                )
            elif dtype in ["int", "bigint", "double"]:
                df[column] = (
                    pd.to_numeric(df[column], errors="coerce")
                    .fillna(0)
                    .astype(
                        "int32"
                        if dtype == "int"
                        else "int64" if dtype == "bigint" else "float64"
                    )
                )
            else:
                df[column] = df[column].astype(pandas_dtype)

    return df


@log_function
def handle_datetime_column(column: pd.Series) -> pd.Series:
    """
    Handle conversion of a column to datetime, supporting numeric timestamps and ISO strings.
    """
    if pd.api.types.is_datetime64_any_dtype(column):
        return column

    # Ensure the column is treated as numeric only if it doesn't already have datetime values
    numeric_column = pd.to_numeric(column, errors="coerce")

    return numeric_column.apply(
        lambda x: (
            pd.to_datetime(x, unit="ms", errors="coerce", utc=True)
            if x > 1e12
            else pd.to_datetime(x, unit="s", errors="coerce", utc=True)
        )
    )


@log_function
def write_processed_to_s3(
    df: pd.DataFrame, athena_table: str, s3_bucket=None
) -> Dict[str, Any]:
    """
    Writes processed data to S3 as a Parquet file and registers it with Athena.

    :param df: The DataFrame to write
    :param s3_bucket: The S3 bucket to write to
    :param athena_table: The Athena table name
    :return: The result of the write operation
    """
    if s3_bucket is None:
        s3_bucket = os.environ["S3_RAW"]
    processed_s3_path = f"s3://{s3_bucket}/{athena_table}/"

    log_event("info", "Writing data to Athena", {"path": processed_s3_path})

    res = wr.s3.to_parquet(
        df=df,
        path=processed_s3_path,
        index=False,
        dataset=True,
        compression="snappy",
        partition_cols=["date"],
        database="datalake_raw",
        table=athena_table,
        mode="append",
        schema_evolution="true",
        dtype=data_catalog.schemas[athena_table],
        glue_table_settings=wr.typing.GlueTableSettings(
            columns_comments=data_catalog.column_comments[athena_table]
        ),
    )

    return res
