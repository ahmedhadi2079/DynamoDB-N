import logging
import sys
import re
import boto3
from typing import Optional
import pandas as pd
import awswrangler as wr
from awsglue.utils import getResolvedOptions


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
                logger.info(
                    "info",
                    "before_datetime_conversion",
                    f"Before conversion: {df[column].head(5)}",
                )
                df[column] = handle_datetime_column(df[column])
                logger.info(
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
        logger.info(
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
        logger.info(
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
            logger.info(
                "info",
                "Unknown column",
                f"{column} not in schema, consider as string.",
            )
            schema[column] = "string"

    df = apply_type_conversions(df, schema, schema_type_mapping)

    return df


def get_athena_schema(database_name, table_name, glue_client):
    try:
        response = glue_client.get_table(DatabaseName=database_name, Name=table_name)
        columns = response["Table"]["StorageDescriptor"]["Columns"]

        schema = {col["Name"]: col["Type"] for col in columns}
        return schema

    except glue_client.exceptions.EntityNotFoundException:
        print(f"Table '{table_name}' not found in database '{database_name}'.")
        return None
    except Exception as e:
        print(f"Error fetching schema: {e}")
        return None


def write_processed_to_s3(df, file):

    print("info", "Writing data to Athena", {"path": file})

    res = wr.s3.to_parquet(
        df=df,
        path=file,
        index=False,
        dataset=False,
        compression="snappy",
    )
    return res


def main():
    try:
        # STEP_1: Initialize global variables
        args = getResolvedOptions(
            sys.argv,
            [
                "ATHENA_TABLE_NAME",
                "PRTITION_DATE",
                "S3_BUCKET_NAME",
            ],
        )

        athena_table_name = args["ATHENA_TABLE_NAME"]
        partition_date = args["PRTITION_DATE"]  # partition = "date=2025-01-31"
        s3_bucket_name = args["S3_BUCKET_NAME"]

        # Create glue client
        glue_client = boto3.client("glue")

        schema = get_athena_schema("datalake_raw", athena_table_name, glue_client)

        partition_prefix = f"s3://{s3_bucket_name}/{athena_table_name}/{partition_date}"
        files = wr.s3.list_objects(
            path=partition_prefix,
            suffix=".parquet",
        )

        for file in files:
            logger.info("********")
            logger.info(file)
            df = wr.s3.read_parquet(path=file)
            final_df = apply_schema(df, schema)
            write_processed_to_s3(final_df, file)
            logger.info("********")

        res = f"[Success] Finished processing apply schema from table: {athena_table_name} "
        logger.info(res)
        return res
    except Exception as e:
        logger.error("Error in Glue job: %s", e)
        raise


if __name__ == "__main__":
    main()
