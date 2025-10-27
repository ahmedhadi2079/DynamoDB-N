
# IAM Role for Glue Crawler
resource "aws_iam_role" "rds_glue_crawler_role" {
  name        = "rds-glue-crawler-role"
  description = "Role for Glue crawler with KMS and Lake Formation permissions"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policies
resource "aws_iam_policy" "glue_kms_permissions" {
  name        = "GlueKMSPermissions"
  description = "Permissions for Glue to use KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.rds_export_key.arn
      }
    ]
  })
}

resource "aws_iam_policy" "glue_lake_formation_permissions" {
  name        = "GlueLakeFormationPermissions"
  description = "Permissions for Glue to access Lake Formation resources"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lakeformation:GetDataAccess",
          "lakeformation:GrantPermissions"
        ],
        Resource = "*"
      }
    ]
  })
}

# Policy Attachments
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.rds_glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.rds_glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "kms_permissions" {
  role       = aws_iam_role.rds_glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_kms_permissions.arn
}

resource "aws_iam_role_policy_attachment" "lake_formation_permissions" {
  role       = aws_iam_role.rds_glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_lake_formation_permissions.arn
}

# Glue Security Configuration
resource "aws_glue_security_configuration" "example_security_config" {
  name = "glue-security-config"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = aws_kms_key.rds_export_key.arn
    }
  }
}

# Glue Crawler
resource "aws_glue_crawler" "rds_export_crawler" {
  database_name          = "datalake_raw"
  name                   = "rds-export-crawler"
  role                   = aws_iam_role.rds_glue_crawler_role.arn
  security_configuration = aws_glue_security_configuration.example_security_config.name
  table_prefix           = "rds_"

  s3_target {
    path       = "s3://bb2-${var.bespoke_account}-datalake-raw/temporal/sandbox/export/${formatdate("YYYY-MM-DD", timestamp())}"
    exclusions = ["**", "!**.parquet"]
  }

  schema_change_policy {
    delete_behavior = "LOG"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
      Tables = {
        AddOrUpdateBehavior = "MergeNewColumns"
      }
    }
  })
}


resource "aws_lakeformation_permissions" "database_lakeformation_permissions_glue_etl" {
  principal   = aws_iam_role.rds_glue_crawler_role.arn
  permissions = ["CREATE_TABLE"]

  database {
    name = "datalake_raw"
  }

  lifecycle {
    ignore_changes = [permissions]
  }
}

resource "aws_lakeformation_permissions" "tables_lakeformation_permissions_glue_etl" {
  for_each    = toset(["datalake_raw"])
  permissions = ["SELECT", "DESCRIBE", "ALTER", "INSERT"]
  principal   = aws_iam_role.rds_glue_crawler_role.arn

  table {
    database_name = each.key
    wildcard      = true
  }

  lifecycle {
    ignore_changes = [permissions]
  }
}
