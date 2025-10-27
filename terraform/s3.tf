resource "aws_s3_object" "glue_scripts_files" {
  bucket                 = local.aws_glue_bucket_name
  for_each               = fileset("${path.module}/../glues/", "**")
  source                 = "${path.module}/../glues/${each.value}"
  etag                   = filemd5("${path.module}/../glues/${each.value}")
  key                    = "/scripts/${each.value}"
  acl                    = "private"
  server_side_encryption = "AES256"
}

resource "aws_s3_object" "glue_extra_py_files" {
  bucket                 = local.aws_glue_bucket_name
  for_each               = fileset("${path.module}/../common/", "*.py")
  source                 = "${path.module}/../common/${each.value}"
  etag                   = filemd5("${path.module}/../common/${each.value}")
  key                    = "/scripts/ddb_common/${each.value}"
  acl                    = "private"
  server_side_encryption = "AES256"
}

resource "aws_s3_object" "glue_generic_lambda_py_files" {
  bucket                 = local.aws_glue_bucket_name
  for_each               = fileset("${path.module}/../lambdas/dynamodb_lambda_to_s3_raw/", "*.py")
  source                 = "${path.module}/../lambdas/dynamodb_lambda_to_s3_raw/${each.value}"
  etag                   = filemd5("${path.module}/../lambdas/dynamodb_lambda_to_s3_raw/${each.value}")
  key                    = "/scripts/ddb_generic/${each.value}"
  acl                    = "private"
  server_side_encryption = "AES256"
}
