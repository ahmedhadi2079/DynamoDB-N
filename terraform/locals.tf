locals {
  project_name                  = "ddb-integration"
  prefix                        = "datalake-${local.project_name}"
  lambda_layer_aws_wrangler_arn = "arn:aws:lambda:${var.region}:336392948345:layer:AWSSDKPandas-Python312:8"
  raw_datalake_bucket_name      = "bb2-${var.bespoke_account}-datalake-raw"
  raw_datalake_bucket_arn       = "arn:aws:s3:::bb2-sandbox-datalake-raw"
  athena_results_bucket_name    = "bb2-${var.bespoke_account}-datalake-athena-results"
  reconciliation_bucket_name    = "bb2-${var.bespoke_account}-datalake-reconciliation"
  aws_glue_bucket_name          = data.aws_ssm_parameter.aws_glue_bucket_name.value
}
