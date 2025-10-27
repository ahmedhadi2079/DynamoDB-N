# Data source to get RDS cluster information
data "aws_rds_cluster" "postgresql" {
  cluster_identifier = "home-financing-db"
}

# Data source to get S3 bucket information
data "aws_s3_bucket" "export_bucket" {
  bucket = "bb2-${var.bespoke_account}-datalake-raw"
}

# IAM role for RDS to export to S3
resource "aws_iam_role" "rds_export_role" {
  name = "datateam-rds-export-role-${var.bespoke_account}-temporal"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "export.rds.amazonaws.com"
      }
    }]
  })
}

# IAM policy for RDS export role
resource "aws_iam_role_policy" "rds_export_policy" {
  name = "datateam-rds-export-policy-${var.bespoke_account}-temporal"
  role = aws_iam_role.rds_export_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject*",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          data.aws_s3_bucket.export_bucket.arn,
          "${data.aws_s3_bucket.export_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.rds_export_key.arn
      }
    ]
  })
}


data "aws_iam_role" "iam_for_glue" {
  name = "data_lake_iam_for_glue"
}

resource "aws_iam_policy" "kms_decrypt_policy" {
  name        = "glue_kms_decrypt"
  description = "Allows Glue to decrypt S3 objects using KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.rds_export_key.arn
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "attach_kms_decrypt_policy" {
  name       = "glue_kms_decrypt_attachment"
  roles      = [aws_iam_role.iam_for_glue.name]
  policy_arn = aws_iam_policy.kms_decrypt_policy.arn
}

# Glue job to trigger the rds snapshot
resource "aws_glue_job" "glue_ddb_trigger_daily_snapshot" {
  name        = "${local.prefix}-rds-trigger-daily-snapshot-glue"
  description = "A glue job to trigger daily snapshot from RDS postgres DB"

  command {
    name            = "pythonshell"
    script_location = "s3://${local.aws_glue_bucket_name}/scripts/ddb_rds_trigger_daily_snapshot/ddb_rds_trigger_snapshot_export_glue.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--S3_BUCKET_NAME"        = data.aws_s3_bucket.export_bucket.id
    "--IAM_ROLE_ARN"          = aws_iam_role.rds_export_role.arn
    "--KMS_KEY_ID"            = aws_kms_key.rds_export_key.id
    "--EXPORT_ONLY"           = jsonencode(var.export_only_tables)
    "--RDS_ENVIRONMENT"       = var.bespoke_account
    "--DB_CLUSTER_IDENTIFIER" = data.aws_rds_cluster.postgresql.id
    "--RDS_AWS_REGION"        = data.aws_region.current.name
    "--RDS_AWS_ACCOUNT_ID"    = data.aws_caller_identity.current.account_id
  }
  timeout  = "720"
  role_arn = aws_iam_role.glue_rds_trigger_role.arn
}

# Glue Trigger to Schedule the Job
resource "aws_glue_trigger" "daily_schedule" {
  name     = "ddb_rds_daily_snapshot_trigger"
  type     = "SCHEDULED" #
  schedule = "cron(0 4 * * ? *)"

  actions {
    job_name = aws_glue_job.glue_ddb_trigger_daily_snapshot.name
  }

  start_on_creation = false
}

resource "aws_iam_policy" "kms_access_policy" {
  name = "kms-access-policy"
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


# IAM Policy for Glue to interact with RDS and CloudWatch
resource "aws_iam_policy" "glue_rds_trigger_policy" {
  name = "glue-rds-trigger-policy"
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Action : [
          "rds:StartExportTask"
        ]
        Effect : "Allow"
        Resource : "*"
      },
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
        Action : [
          "rds:StartExportTask",
          "rds:DescribeDBClusterSnapshots",
          "rds:CreateDBClusterSnapshot",
          "rds:ListTagsForResource",
          "rds:AddTagsToResource",
          "rds:DeleteDBClusterSnapshot"
        ],
        "Resource" : [
          data.aws_rds_cluster.postgresql.arn,
          "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*"
        ]
      }
    ]
  })
}

# IAM Role for the glue function
resource "aws_iam_role" "glue_rds_trigger_role" {
  name = "glue-rds-trigger-role"
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


resource "aws_iam_role_policy_attachment" "glue_kms_attachment" {
  role       = aws_iam_role.glue_rds_trigger_role.name
  policy_arn = aws_iam_policy.kms_access_policy.arn
}

# Attach policy to IAM Role
resource "aws_iam_role_policy_attachment" "glue_rds_trigger_attachment" {
  role       = aws_iam_role.glue_rds_trigger_role.name
  policy_arn = aws_iam_policy.glue_rds_trigger_policy.arn
}
