# README for S3 Object Version Handling Lambda Function

# Overview

This AWS Lambda function is designed to interact with an Amazon S3 bucket, retrieve object version information, filter object versions by a specified date range, and restore specific versions of objects based on predefined criteria. It is particularly useful for managing and restoring historical versions of files in S3.

# Features

	•	Retrieves all object versions (including delete markers) from a specified S3 bucket and prefix.
	•	Filters object versions based on a given date range.
	•	Handles specific file extensions like .snappy.parquet for restoration.
	•	Copies filtered object versions to new keys with a custom naming convention.

# Function Input

The Lambda function expects an event object with the following structure:
```
{
  "s3_bucket": "your-bucket-name",
  "target_path": "optional-prefix",
  "start_date": "November 20, 2024, 19:07:25 (UTC+02:00)",
  "end_date": "November 25, 2024, 19:07:25 (UTC+02:00)"
}
```
# Parameters:

	•	s3_bucket: The name of the S3 bucket.
	•	target_path: (Optional) The prefix of the objects to retrieve.
	•	start_date: The start of the date range (in the format: Month Day, Year, Hour:Minute:Second (TimeZone)).
	•	end_date: The end of the date range (in the same format as start_date).

# Sample Event
```
{
    "s3_bucket":"bb2-sandbox-datalake-raw",
    "target_path":"dynamo_sls_home_financing_mortgage",
    "start_date":"February 26, 2024, 04:00:17 (UTC+02:00)",
    "end_date":"February 26, 2024, 04:00:17 (UTC+02:00)"
}
```
# Output

Logs are generated to provide insights into the following:
	•	Retrieved object versions.
	•	Filtered object versions.
	•	Restoration actions performed.
```
INFO: {'Key': 'example.snappy.parquet', 'VersionId': '123456789', 'IsLatest': False, 'LastModified': datetime(2024, 11, 20, 19, 7, 25, tzinfo=tzutc()), 'Size': 1024}
Copied object example.snappy.parquet (version 123456789) to example_restored_123456789.snappy.parquet in bucket your-bucket-name/prefix.
```
# Notes

	•	Ensure the S3 bucket has versioning enabled; otherwise, this function will not retrieve object versions.
	•	Test the function in a staging environment before using it in production.
