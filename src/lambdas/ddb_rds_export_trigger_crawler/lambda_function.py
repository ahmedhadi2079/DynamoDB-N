import re
import os
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get crawler name from environment variables
crawler_name = os.environ['GLUE_CRAWLER_NAME']

def trigger_glue_job(glue_job_name, s3_bucket_name, s3_key, rds_crawler_name):
    try:
        glue_client = boto3.client('glue')
        glue_job_name = glue_job_name
        job_parameters = {
            "--S3_BUCKET_NAME": s3_bucket_name,
            "--S3_KEY": s3_key,
            "--RDS_CRAWLER_NAME": rds_crawler_name
        }

        response = glue_client.start_job_run(
            JobName=glue_job_name,
            Arguments=job_parameters
        )
        logger.info(f"Glue job {glue_job_name} started with run ID: {response['JobRunId']}")

    except Exception as e:
        logger.error(f"Error starting Glue job: {str(e)}")
        raise e

def lambda_handler(event, context):
    logger.info(event)
    # logging event
    logger.info(f"Received event: {json.dumps(event, indent=2)}")

    # Extract S3 bucket and key from the event
    s3_bucket = event["detail"]["bucket"]["name"]
    s3_key = event["detail"]["object"]["key"]
    env = s3_key.split('/')[1]
    pattern = rf"temporal/{env}/export/\d{{4}}-\d{{2}}-\d{{2}}/data-team-export" \
              rf"-{env}-temporal-\d{{4}}-\d{{2}}-\d{{2}}-\d{{2}}-\d{{2}}/export_info_data-team-export" \
              rf"-{env}-temporal-\d{{4}}-\d{{2}}-\d{{2}}-\d{{2}}-\d{{2}}\.json"
    process_glue_name = 'datalake-ddb-integration-rds-run-crawler-glue'

    # handling the exported files from the snapshot
    if re.match(pattern, s3_key):
        trigger_glue_job(process_glue_name, s3_bucket, s3_key, crawler_name)
    else:
        logger.info(f"Skipping path: {s3_key}")
