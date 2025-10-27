import re
import sys
import time
import json
import boto3
import asyncio
import logging
from botocore.exceptions import ClientError
from awsglue.utils import getResolvedOptions

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
                "S3_KEY",
                "RDS_CRAWLER_NAME",
            ],
        )
        s3_bucket_name = args["S3_BUCKET_NAME"]
        s3_key = args["S3_KEY"]
        rds_crawler_name = args["RDS_CRAWLER_NAME"]

        # logging parameters
        logger.info(f"S3 Bucket Name: {s3_bucket_name}")
        logger.info(f"S3 Key: {s3_key}")
        logger.info(f"RDS Crawler Name: {rds_crawler_name}")

        return args

    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e

def wait_for_crawler(glue_session, crawler_name):
    """
            Waits until the glue job is ready to avoid concurrent runs

            :param glue_session: The Glue session that will be used
            :param crawler_name: The name of the glue crawler job
        """
    while True:
        crawler = glue_session.get_crawler(Name=crawler_name)
        state = crawler['Crawler']['State']
        logger.info(f"Crawler state: {state}")

        if state == 'READY':
            logger.info("Crawler is ready to start.. Double-checking!")
            time.sleep(10)
            crawler = glue_session.get_crawler(Name=crawler_name)
            state = crawler['Crawler']['State']
            if state == 'READY':
                logger.info("Crawler is ready to start.")
                break
        elif state == 'RUNNING':
            logger.info("Crawler is currently running. Waiting...")
            time.sleep(30)
        else:
            logger.warning(f"Crawler is not ready: {state}. Waiting...")
            time.sleep(30)

def check_file_exists(s3_client, bucket_name, file_key, region_name='eu-west-2'):
    """
    Check if a file exists in an S3 bucket.

    :param bucket_name: Name of the S3 bucket.
    :param file_key: Key (path) of the file in the S3 bucket.
    :param region_name: AWS region where the bucket is located.
    :return: True if the file exists, False otherwise.
    """
    try:
        s3_client.head_object(Bucket=bucket_name, Key=file_key)
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == "404":
            print(f"File '{file_key}' does not exist in bucket '{bucket_name}'.")
            return False
        else:
            print(f"Error occurred: {e}")
            raise

def check_folder_exists(bucket_name, folder_prefix):
    try:
        s3 = boto3.client('s3')
        response = s3.list_objects_v2(
            Bucket=bucket_name,
            Prefix=folder_prefix,
            MaxKeys=1  # Only need to check one object
        )

        if 'Contents' in response:
            print(f"Folder '{folder_prefix}' exists!")
            return True
        else:
            print(f"Folder '{folder_prefix}' does NOT exist.")
            return False
    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e


def list_files_in_s3(bucket_name, prefix):
    try:
        s3 = boto3.client('s3')
        paginator = s3.get_paginator('list_objects_v2')
        page_iterator = paginator.paginate(Bucket=bucket_name, Prefix=prefix)

        all_files = []

        for page in page_iterator:
            if 'Contents' in page:
                for obj in page['Contents']:
                    print(f"Found file: {obj['Key']}")
                    all_files.append(obj['Key'])

        return all_files
    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e

def glue_start_crawler(glue_session, crawler_name):
    """
            Starts the Glue Crawler job

            :param glue_session: The Glue session that will be used
            :param crawler_name: The name of the glue crawler job
        """
    try:
        logger.info("Starting the crawler...")
        response = glue_session.start_crawler(
            Name=crawler_name
        )
        return response
    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e

def glue_update_crawler(glue_session, crawler_path, crawler_name, s3_bucket):
    """
        Update the Glue Crawler's S3 target

        :param glue_session: The Glue session that will be used
        :param crawler_path: The S3 file path that the crawler will create an athena based on
        :param crawler_name: The name of the glue crawler job
        :param s3_bucket: The name of the S3 bucket
    """
    try:
        logger.info(f"Updating Glue Crawler: {crawler_name} with path: {crawler_path}")

        glue_session.update_crawler(
            Name=crawler_name,
            Targets={
                "S3Targets": [{"Path": f"s3://{s3_bucket}/{crawler_path}"}]
            }
        )
    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e

    logger.info("Crawler updated successfully")

def copy_s3_object(s3_client, bucket_name, source_key, destination_key):
    """
    Copy a file from one S3 location to another within the same bucket.

    :param bucket_name: Name of the S3 bucket
    :param source_key: The source file's key
    :param destination_key: The destination file's key
    """

    try:
        s3_client.copy_object(
            Bucket=bucket_name,
            CopySource={'Bucket': bucket_name, 'Key': source_key},
            Key=destination_key
        )
        print(f"File copied from {source_key} to {destination_key} successfully.")
    except Exception as e:
        logger.error(f"ERROR: An unexpected error occurred: {e}")
        raise e

def main():
    try:
        # Extract S3 bucket and key from the event
        args = retrieve_args()
        s3_bucket = args["S3_BUCKET_NAME"]
        s3_key = args["S3_KEY"]
        crawler_name = args["RDS_CRAWLER_NAME"]

        env = s3_key.split('/')[1]
        pattern = rf"temporal/{env}/export/\d{{4}}-\d{{2}}-\d{{2}}/data-team-export-{env}-temporal-\d{{4}}-\d{{2}}-\d{{2}}-\d{{2}}-\d{{2}}/export_info_data-team-export-{env}-temporal-\d{{4}}-\d{{2}}-\d{{2}}-\d{{2}}-\d{{2}}\.json"

        # handling the exported files from the snapshot
        if re.match(pattern, s3_key):
            s3_client = boto3.client('s3')
            response = s3_client.get_object(Bucket=s3_bucket, Key=s3_key)
            content = response['Body'].read().decode('utf-8')
            json_data = json.loads(content)
            export_only_list = json_data.get("exportOnly", [])
            exported_files_path = json_data.get("exportedFilesPath", [])

            for table in export_only_list:
                print(f"Processing table: {table} ...")

                # calculating extra variables
                table_name = table.split(".")[2]
                db_name = table.split('.')[1]
                rds_instance = table.split('.')[0]
                source_file_path = f"{exported_files_path}/{rds_instance}/{db_name}.{table_name}/"
                destination_folder = f"temporal/{env}/crawler/{rds_instance}/{db_name}/{table_name}"
                run_crawler = False

                if not check_folder_exists(s3_bucket,destination_folder):
                    run_crawler = True

                files_in_path = list_files_in_s3(s3_bucket, source_file_path)
                counter = 0
                for source_file in files_in_path:
                    if source_file.endswith(".gz.parquet"):
                        source_file_name = source_file
                        destination_file_name = f"{destination_folder}/{table_name}_{counter}_export.gz.parquet"
                        # copy the file from original path to the new path in the crawler path
                        copy_s3_object(s3_client, s3_bucket, source_file_name, destination_file_name)
                        counter+=1

                        if run_crawler:
                            logger.info(f"Athena table does not exist. Creating new {table_name} table...")
                            crawler_path = destination_folder

                            # Wait if crawler is already running
                            glue = boto3.client('glue')
                            wait_for_crawler(glue_session=glue, crawler_name=crawler_name)
                            # Update the crawler target path
                            glue_update_crawler(glue_session=glue, crawler_path=crawler_path, crawler_name=crawler_name,
                                                s3_bucket=s3_bucket)

                            # Start crawler
                            wait_for_crawler(glue_session=glue, crawler_name=crawler_name)
                            # start the glue crawler job
                            response = glue_start_crawler(glue_session=glue, crawler_name=crawler_name)
                            print('response', response)

                            logger.info(f"Crawler {crawler_name} started successfully for table {table_name}")

                        else:
                            logger.info(f"Athena table {table_name} exists. Data is updated!")

            return {
                'statusCode': 200,
                'body': f"Finished processing files!"
            }
        else:
            logger.info(f"Skipping path: {s3_key}")

    except Exception as e:
        logger.error(f"Error processing files: {str(e)}")
        raise e


if __name__ == "__main__":
    main()
