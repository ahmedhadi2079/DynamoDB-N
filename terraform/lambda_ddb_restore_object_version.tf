# ###########################################################
# # AWS Lambda function: ddb_restore_object_version
# ###########################################################
module "lambda_ddb_restore_object_version" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.13.0"

  function_name = "${local.prefix}-restore-object-version"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  layers        = [local.lambda_layer_aws_wrangler_arn]
  timeout       = 900
  memory_size   = var.lambda_ddb_to_s3_memory_size

  source_path = [
    {
      path             = "../lambdas/ddb_restore_object_version"
      pip_requirements = true,
      patterns = [
        "!README.md",
        "!tests/.*",
        "!scripts/.*",
      ]
    }
  ]

  hash_extra   = "${local.prefix}-restore-object-version"
  create_role  = false
  lambda_role  = aws_iam_role.iam_for_lambda.arn
  tracing_mode = "Active"
}
