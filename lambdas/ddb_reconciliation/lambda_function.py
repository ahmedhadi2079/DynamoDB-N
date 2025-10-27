import logging
import os
from datetime import date
from datetime import datetime
from typing import Dict

import awswrangler as wr
import boto3
import pandas as pd
from data_catalog import data_types

import config

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.client("dynamodb")


def read_athena(sql_path: str, input_database: str) -> pd.DataFrame:
    """
    Reads the total historical onboarding timeline customer -> status from Athena.
    :return: DataFrame containing all distinct customer ids
    :rtype: pd.DataFrame
    :param sql_path: path to the sql file containing the query
    :type sql_path: str
    :param input_database: The input database to read from
    :type input_database: str
    :return: Dataframe containing the result of the SQL query
    :rtype: pd.DataFrame
    """

    with open(sql_path, "r") as total_onboarding_status_timeline_sql_file:
        total_onboarding_status_timeline_sql = (
            total_onboarding_status_timeline_sql_file.read()
        )

    logger.info("Reading from Athena... ")

    df = wr.athena.read_sql_query(
        sql=total_onboarding_status_timeline_sql,
        database=input_database,
        workgroup="datalake_workgroup",
        ctas_approach=False,
    )

    return df


def generic_construct_count_dataframe(
    athena_df: pd.DataFrame, dynamo_count: int
) -> pd.DataFrame:
    """
    Constructs the output dataframe with structure status
    :rtype: pd.DataFrame
    """
    data = {
        "count_dynamo": [dynamo_count],
        "count_athena": [athena_df.shape[0]],
        "date": [date.today().strftime("%Y%m%d")],
        "timestamp_extract": [datetime.utcnow()],
    }

    return pd.DataFrame(
        data, columns=["count_dynamo", "count_athena", "date", "timestamp_extract"]
    )


def recon_check_counts(dynamo_count: int, athena_count: int, threshold: float) -> bool:
    """
    Checks the counts between dynamo and athena and reports an error accordingly.
    Due to timing of running the recon and getting the latest scanned count
    from Dynamo(which by nature is a number AWS produces every 6 hours)
    we usually get tiny incosistencies(i.e. 1,2 ) in our compared counts
    between Athena and Dynamo, therefore if that happens it shouldn't
    throw an error. The counts catch up, and the progress is captured in Athena
    datalake_reconciliation tables on a daily basis.
    In addition the live ETL Lambda functions are also configured to throw exceptions
    and produce alarms if there is any issue, so that part is also monitored for errors.
    In this function, there is a threshold property(configurable for each table),
    which allows a tiny room for some diff for these purposes.
    :param dynamo_count: The distinct count of the dynamo pk
    :type dynamo_count: int
    :param athena_count: The distinct count of the athena pk
    :type athena_count: int
    :return: Flag of whether count is as expected
    :rtype: bool
    """
    perc_dynamo_count = int(dynamo_count * threshold)
    if os.environ.get("IS_PRODUCTION"):
        if perc_dynamo_count > athena_count:
            logger.error(
                f"Row Counts Do Not Match: Data Lake Total Count = {athena_count}; Dynamo Total Count = {dynamo_count}"
            )
            return False
        else:
            logger.info(
                f"Row Counts Match or within defined threshold: Data Lake Total Count = {athena_count}; Dynamo Total Count = {dynamo_count}"
            )
            return True
    else:
        if perc_dynamo_count > athena_count:
            logger.warn(
                f"Row Counts Do Not Match: Data Lake Total Count = {athena_count}; Dynamo Total Count = {dynamo_count}"
            )
            return False
        else:
            logger.info(
                f"Row Counts Match: Data Lake Total Count = {athena_count}; Dynamo Total Count = {dynamo_count}"
            )
            return True


def construct_customers_count_dataframe(
    athena_df: pd.DataFrame, dynamo_count: int
) -> pd.DataFrame:
    """
    Constructs the output dataframe with structure count_of_users_athena | count_of_users_dynamo | date
    :param athena_df: The dataframe derived from Athena
    :type athena_df: pd.DataFrame
    :param dynamo_count: The dataframe derived from DynamoDB
    :type dynamo_count: int
    :return: Output dataframe combining Athena and DynamoDB counts
    :rtype: pd.DataFrame
    """
    now = datetime.utcnow()
    today = now.strftime("%Y-%m-%d")

    # filter for today for athena results
    athena_df = athena_df[athena_df["onboarding_status_date_"] == today]
    athena_df["status_"] = athena_df["status_"].fillna("UNKNOWN")

    # process athena results
    agg_athena = (
        athena_df.groupby(by=["status_", "onboarding_status_date_"])
        .count()
        .reset_index()
    )
    agg_athena = agg_athena.rename(
        columns={
            "status_": "status",
            "onboarding_status_date_": "date",
            "user": "count_of_users_athena",
        }
    )
    athena_count = agg_athena["count_of_users_athena"].sum()

    recon_check_counts(dynamo_count, athena_count, 0.9995)

    data = {
        "status": ["ALL"],
        "count_of_users_dynamo": [dynamo_count],
        "date": [date.today().strftime("%Y%m%d")],
        "count_of_users_athena": [athena_count],
        "timestamp": [datetime.utcnow()],
    }

    return pd.DataFrame(
        data,
        columns=[
            "status",
            "count_of_users_dynamo",
            "date",
            "count_of_users_athena",
            "timestamp",
        ],
    )


def create_database_if_not_exists(database_name: str) -> dict:
    """
    Creates a database in Athena with the name provided if it doesn't already exist
    :param database_name: The name of the database
    :type database_name: str
    :return: The response
    :rtype: dict
    """

    if database_name not in wr.catalog.databases().values:
        res = wr.catalog.create_database(database_name)

        return res


def write_to_s3(
    output_df: pd.DataFrame,
    athena_table: str,
    database_name: str,
    schema: Dict[str, str],
    s3_bucket: str = None,
    mode: str = "append",
) -> dict:
    """
    Writes the DataFrame to S3 and Athena using AWS Wrangler
    :param output_df: The Dataframe to write out to S3
    :type output_df: pd.DataFrame
    :param athena_table: The table in Athena to write to
    :type athena_table: str
    :param database_name: The database in Athena to write to
    :type database_name: str
    :param s3_bucket: The name of the bucket in S3, defaults to None
    :type s3_bucket: str, optional
    :return: The response
    :rtype: dict
    """

    if s3_bucket is None:
        s3_bucket = os.environ["S3_RECON"]

    logger.info(f"Uploading to S3 bucket: {s3_bucket}")
    logger.info(f"Pandas DataFrame Shape: {output_df.shape}")
    path = f"s3://{s3_bucket}/{athena_table}/"
    logger.info("Uploading to S3 location:  %s", path)

    create_database_if_not_exists(database_name)

    try:
        res = wr.s3.to_csv(
            df=output_df,
            path=path,
            index=False,
            dataset=True,
            database=database_name,
            table=athena_table,
            mode=mode,
            schema_evolution="true",
            dtype=schema,
        )

        return res

    except Exception as e:
        logger.error("Failed uploading to S3 location:  %s", path)
        logger.error("Exception occurred:  %s", e)

        return e


def write_reconcilication_to_s3(
    construct_count_dataframe,
    athena_df,
    latest_scanned_count_dynamo_df,
    target_athena_table,
    athena_database_name,
):
    dynamo_athena_merged_df = construct_count_dataframe(
        athena_df, latest_scanned_count_dynamo_df
    )

    res = write_to_s3(
        dynamo_athena_merged_df,
        athena_table=target_athena_table,
        database_name=athena_database_name,
        schema=data_types[target_athena_table],
    )

    logger.info(f"Result: {res}")
    return dynamo_athena_merged_df


def read_dynamo_aws_cli(dynamo_table_name: str = None):
    """
    Accepts the name of a Dynamo table and returns the latest scanned count using the AWS CLI
    :param dynamo_table_name: String representing the table name to get the count for
    :type dynamo_table_name: str
    """
    count_command = dynamodb.scan(
        TableName=dynamo_table_name,
    )

    logger.info("Dynamo count command:  %s", count_command["Count"])

    return count_command["ScannedCount"]


def generic_process_reconciliation(
    sql_filepath: str, athena_table_name: str, dynamo_table_name: str, threshold: float
):
    logger.info("Starting {0} reconciliation. ".format(athena_table_name))
    athena_df = read_athena(sql_filepath, "datalake_raw")
    dynamo_count = read_dynamo_aws_cli(dynamo_table_name)

    merged_df = write_reconcilication_to_s3(
        generic_construct_count_dataframe,
        athena_df,
        dynamo_count,
        athena_table_name,
        "datalake_reconciliation",
    )

    dynamo_count = merged_df["count_dynamo"].sum()
    athena_count = merged_df["count_athena"].sum()

    recon_check_counts(dynamo_count, athena_count, threshold)

    logger.info("Finished {0} reconciliation. ".format(athena_table_name))


def lambda_handler(event, context):
    # generic recon functions
    dynamo_recon_table = event["dynamo_recon_table"]
    logger.info(f"Start running for {dynamo_recon_table}...")
    generic_process_reconciliation(
        config.dynamo_tables[dynamo_recon_table]["reconcile_sql_path"],
        dynamo_recon_table,
        os.environ.get(
            config.dynamo_tables[dynamo_recon_table]["dynamo_table_env_var_name"]
        ),
        config.dynamo_tables[dynamo_recon_table]["threshold"],
    )

    logger.info(f"Finished running for {dynamo_recon_table}...")
