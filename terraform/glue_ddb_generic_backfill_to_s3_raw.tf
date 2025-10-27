# ###########################################################
# # AWS Glue job: Generic DynamoDB backfill glue job
# ###########################################################

resource "aws_glue_job" "dynamodb_to_athena_generic_backfill" {
  name         = "${local.prefix}-dynamodb-to-athena-migration-generic_backfill"
  role_arn     = aws_iam_role.iam_for_glue.arn
  max_capacity = 1.0
  max_retries  = "0"
  timeout      = 2880 # 48 hours

  command {
    name            = "pythonshell"
    script_location = "s3://${local.aws_glue_bucket_name}/scripts/ddb_generic_backfill_to_s3_raw/ddb_generic_backfill_to_s3_raw.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--S3_BUCKET_NAME"         = local.raw_datalake_bucket_name
    "--RESULT_ATHENA_TABLE"    = "sample_datalake_raw_table_name" // modify as your result athena table in datalake_raw
    "--TARGET_DYNAMO_TABLE"    = "sample_dynamo_table_name"       // modify as your target table to backfill
    "--DYNAMO_PRTITION_COLUMN" = "id"                             // ddb partitioning column, check readme for more info
    "--INCREMENTAL_MODE"       = "False"                          // bool
    "--WRANGLER_WRITE_MODE"    = "append"                         // mode for writing data to S3. Can be `append`, `overwrite`, or `overwrite_partitions`
    "--START_DATE"             = "01-07-2024"                     // in format %d-%m-%Y to filter records with property updatedAt > START_DATE
    "--AUTO_SCHEMA"            = "False"                          // bool, if True, schema will be auto inferred, else from generic lambda data_catalog


    "--extra-py-files"                   = "s3://${local.aws_glue_bucket_name}/scripts/ddb_generic/data_catalog.py"
    "--TempDir"                          = "s3://${local.aws_glue_bucket_name}/temporary/"
    "--additional-python-modules"        = "flatten-json==0.1.14"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-glue-datacatalog"          = "true"
  }
}
