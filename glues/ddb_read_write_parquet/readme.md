# Read Write Parquet Glue Function
## Summary
This AWS Glue function is designed to process Parquet files in S3 by applying an Athena/Glue schema. The job retrieves the schema from the Glue Catalog, reads the Parquet files from the specified S3 partition, and enforces correct data types using Pandas. It handles datetime conversions, numeric casting, drops redundant/duplicate columns, and ensures unknown columns default to strings. The processed DataFrame is then written back to the same S3 path as Parquet with Snappy compression.

## Key Features

- Schema Enforcement: Retrieves Glue/Athena schema and applies it to ensure type consistency.

- Data Cleaning: Handles datetime conversions, numeric casting, and fills missing values.

- Column Management: Drops duplicate or redundant columns and treats unknown columns as strings.

- Seamless S3 Integration: Reads Parquet files from S3, processes them, and writes back with Snappy compression.

- Logging Support: Provides detailed logging for before/after conversions, dropped columns, and schema adjustments.

## Sample Arguments
Before triggering the Glue function, provide a specific arguments in the following format:
```
    "ATHENA_TABLE_NAME": "dynamo_sls_ias_recurring",
    "PRTITION_DATE": "date=2025-01-31", 
```

## Parameters (Be Careful with WRANGLER_WRITE_MODE)

- ### `ATHENA_TABLE_NAME`:
Name of the Athena table where the data will be stored.

- ### `PRTITION_DATE`:
We can use "date=2025-" to get year or "date=2025-01" to get month
