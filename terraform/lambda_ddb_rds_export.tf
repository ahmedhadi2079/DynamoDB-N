data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# Lambda function
module "lambda_ddb_trigger_crawler_rds_export" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.1"

  function_name = "${local.prefix}-ddb-rds-trigger-glue-crawler"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  layers        = [local.lambda_layer_aws_wrangler_arn]
  timeout       = 900
  memory_size   = var.lambda_ddb_rds_memory_size

  source_path = [
    {
      path             = "../src/lambdas/ddb_rds_export_trigger_crawler"
      pip_requirements = true,
      patterns = [
        "!README.md",
        "!tests/.*",
        "!scripts/.*",
      ]
    }
  ]

  environment_variables = {
    GLUE_CRAWLER_NAME = "rds-export-crawler"
  }

  create_role  = false
  lambda_role  = aws_iam_role.lambda_crawler_trigger_role.arn
  tracing_mode = "Active"
}

resource "aws_iam_role" "lambda_crawler_trigger_role" {
  # IAM role for Lambda
  name = "lambda-crawler-trigger-role-${var.bespoke_account}-temporal"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_crawler_trigger_policy" {
  name = "lambda-crawler-trigger-policy-${var.bespoke_account}-temporal"
  role = aws_iam_role.lambda_crawler_trigger_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          data.aws_s3_bucket.export_bucket.arn,
          "${data.aws_s3_bucket.export_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJob",
          "glue:BatchStopJobRun",
          "glue:StartCrawler",
          "glue:GetCrawler",
          "glue:UpdateCrawler",
          "glue:UpdateJob"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect : "Allow",
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource : aws_kms_key.rds_export_key.arn
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "s3_eventbridge_notification" {
  bucket      = data.aws_s3_bucket.export_bucket.id
  eventbridge = true
}

# EventBridge rule for S3 object creation events
resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name        = "rds-s3-object-created-rule"
  description = "Trigger Lambda on S3 object creation"

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : {
        "name" : [data.aws_s3_bucket.export_bucket.id]
      },
      "object" : {
        "key" : [{
          "wildcard" : "temporal/${var.bespoke_account}/export/*.json"
        }]
      }
    }
  })
}

resource "aws_iam_policy" "rds_eventbridge_to_lambda_policy" {
  name        = "rds-eventbridge-to-lambda-policy"
  description = "Policy to allow EventBridge to start Lambda Function"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "lambda:InvokeFunction"
        ],
        Effect : "Allow",
        Resource : module.lambda_ddb_trigger_crawler_rds_export.lambda_function_arn
      }
    ]
  })
}

resource "aws_iam_role" "rds_eventbridge_to_lambda_role" {
  name = "rds-eventbridge-to-glue-role"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          Service : "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_to_lambda_attachment" {
  role       = aws_iam_role.rds_eventbridge_to_lambda_role.name
  policy_arn = aws_iam_policy.rds_eventbridge_to_lambda_policy.arn
}

# EventBridge target to trigger Lambda
resource "aws_cloudwatch_event_target" "rds_lambda_target" {
  rule       = aws_cloudwatch_event_rule.s3_event_rule.name
  target_id  = "lambda"
  arn        = module.lambda_ddb_trigger_crawler_rds_export.lambda_function_arn
  depends_on = [aws_cloudwatch_event_rule.s3_event_rule]
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "rds_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge-new"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_ddb_trigger_crawler_rds_export.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_event_rule.arn

  lifecycle {
    ignore_changes = [statement_id]
  }
}

# Lambda permission for S3
resource "aws_lambda_permission" "rds_allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_ddb_trigger_crawler_rds_export.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.export_bucket.arn
}
