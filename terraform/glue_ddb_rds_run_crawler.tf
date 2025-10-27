# Data source to get S3 bucket information
data "aws_s3_bucket" "rds_export_bucket" {
  bucket = "bb2-${var.bespoke_account}-datalake-raw"
}

resource "aws_glue_job" "glue_ddb_rds_run_crawler" {
  name        = "${local.prefix}-rds-run-crawler-glue"
  description = "A glue job to run the glue crawler from RDS exported S3 files"

  command {
    name            = "pythonshell"
    script_location = "s3://${local.aws_glue_bucket_name}/scripts/ddb_rds_run_crawler/ddb_rds_run_crawler_glue.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--S3_BUCKET_NAME"   = data.aws_s3_bucket.rds_export_bucket.id
    "--S3_KEY"           = "temporal/${var.bespoke_account}/export/"
    "--RDS_CRAWLER_NAME" = aws_glue_crawler.rds_export_crawler.name
  }
  timeout  = "720"
  role_arn = aws_iam_role.glue_run_crawler_role.arn
}

# IAM Role for the glue function
resource "aws_iam_role" "glue_run_crawler_role" {
  name = "glue-run-crawler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "kms_access_run_crawler_policy" {
  name = "kms-run-crawler-access-policy"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
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

resource "aws_iam_role_policy_attachment" "glue_kms_run_crawler_attachment" {
  role       = aws_iam_role.glue_run_crawler_role.name
  policy_arn = aws_iam_policy.kms_access_run_crawler_policy.arn
}

# IAM Policy for Glue to interact with RDS and CloudWatch
resource "aws_iam_policy" "glue_run_crawler_policy" {
  name = "glue-rds-run-crawler-policy"
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListObjects"
        ],
        "Resource" : [
          "arn:aws:s3:::${data.aws_ssm_parameter.aws_glue_bucket_name.value}",
          "arn:aws:s3:::${data.aws_ssm_parameter.aws_glue_bucket_name.value}/*"
        ]
      },
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
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect : "Allow"
        Resource : "*"
      },
      {
        Action : "iam:PassRole"
        Effect : "Allow"
        Resource : aws_iam_role.rds_export_role.arn
      },
      {
        "Effect" : "Allow",
        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler",
          "glue:UpdateCrawler",
          "glue:UpdateJob"
        ]
        "Resource" : [
          aws_glue_crawler.rds_export_crawler.arn
        ]
      }
    ]
  })
}

# Attach policy to IAM Role
resource "aws_iam_role_policy_attachment" "glue_run_crawler_attachment" {
  role       = aws_iam_role.glue_run_crawler_role.name
  policy_arn = aws_iam_policy.glue_run_crawler_policy.arn
}

