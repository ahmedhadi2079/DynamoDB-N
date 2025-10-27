# ###########################################################
# # AWS Glue job: read write parquet glue job
# ###########################################################

resource "aws_glue_job" "read_write_parquet_1" {
  name         = "${local.prefix}-read-write-parquet-1"
  role_arn     = aws_iam_role.iam_for_glue.arn
  max_capacity = 1.0
  max_retries  = "0"
  timeout      = 2880 # 48 hours

  command {
    name            = "pythonshell"
    script_location = "s3://${local.aws_glue_bucket_name}/scripts/ddb_read_write_parquet/ddb_read_write_parquet.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--S3_BUCKET_NAME"    = local.raw_datalake_bucket_name
    "--ATHENA_TABLE_NAME" = "athena_table_name"
    "--PRTITION_DATE"     = "date=2025-01-31"
  
    "--TempDir"                          = "s3://${local.aws_glue_bucket_name}/temporary/"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-glue-datacatalog"          = "true"
  }
}
