# New KMS key specifically for RDS exports
resource "aws_kms_key" "rds_export_key" {
  description             = "${var.bespoke_account}-temporal Key for RDS exports"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        "Sid" : "AllowRootAccountAccess",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        Sid    = "Allow RDS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key for RDS export"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.rds_export_role.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        "Sid" : "AllowLambdaRoleAccess",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.glue_rds_trigger_role.arn
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowLambdaDecrypt",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.lambda_crawler_trigger_role.arn
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_kms_alias" "rds_export_key_alias" {
  name          = "alias/${var.bespoke_account}-temporal/rds-export"
  target_key_id = aws_kms_key.rds_export_key.key_id
}

# Update the IAM role for RDS export to use the new KMS key
resource "aws_iam_role_policy" "rds_s3_export_kms_policy" {
  name = "datateam-rds-s3-export-kms-policy"
  role = aws_iam_role.rds_export_role.id

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


