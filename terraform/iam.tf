###########################################################
# IAM Role for AWS Lambda
###########################################################
resource "aws_iam_role" "iam_for_lambda" {
  name = "${local.prefix}-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "dynamodb_policy" {
  name   = "dynamodb"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.dynamodb.json
}

resource "aws_iam_role_policy" "s3_policy" {
  name   = "s3"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_role_policy" "athena_policy" {
  name   = "athena"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.athena.json
}

resource "aws_iam_role_policy" "glue_policy" {
  name   = "glue"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.glue.json
}

resource "aws_iam_role_policy" "kinesis_policy" {
  name   = "kinesis"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.kinesis.json
}

resource "aws_iam_role_policy" "translate_policy" {
  name   = "translate"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.translate.json
}

resource "aws_iam_role_policy" "logs_policy" {
  name   = "logs"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_role_policy" "xray_policy" {
  name   = "xray"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.xray.json
}

###########################################################
# IAM Role for AWS Glue
###########################################################
resource "aws_iam_role" "iam_for_glue" {
  name = "${local.prefix}-glue"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "glue.amazonaws.com"
          ]
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "dynamodb_policy_glue" {
  name   = "dynamodb"
  role   = aws_iam_role.iam_for_glue.name
  policy = data.aws_iam_policy_document.dynamodb.json
}


resource "aws_iam_role_policy" "s3_policy_glue" {
  name   = "s3"
  role   = aws_iam_role.iam_for_glue.name
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_role_policy" "athena_policy_glue" {
  name   = "athena"
  role   = aws_iam_role.iam_for_glue.name
  policy = data.aws_iam_policy_document.athena.json
}

resource "aws_iam_role_policy" "glue_policy_glue" {
  name   = "glue"
  role   = aws_iam_role.iam_for_glue.name
  policy = data.aws_iam_policy_document.glue.json
}

resource "aws_iam_role_policy" "logs_policy_glue" {
  name   = "logs"
  role   = aws_iam_role.iam_for_glue.name
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_role_policy" "xray_policy_glue" {
  name   = "xray"
  role   = aws_iam_role.iam_for_glue.name
  policy = data.aws_iam_policy_document.xray.json
}

data "aws_iam_policy_document" "dynamodb" {
  statement {
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams",
      "dynamodb:DescribeTable",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:Get*",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:dynamodb:${var.region}:${var.aws_account_id}:table/sls*",
      "arn:aws:dynamodb:${var.region}:${var.aws_account_id}:table/sls*/*",
      "arn:aws:dynamodb:${var.region}:${var.aws_account_id}:table/${data.aws_ssm_parameter.cards_fast_messages_table_name.value}",
    ]
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ListObjects",
      "s3:ListObjectVersions",
      "s3:Get*",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${local.raw_datalake_bucket_name}",
      "arn:aws:s3:::${local.raw_datalake_bucket_name}/*",
      "arn:aws:s3:::${local.athena_results_bucket_name}",
      "arn:aws:s3:::${local.athena_results_bucket_name}/*",
      "arn:aws:s3:::${local.reconciliation_bucket_name}",
      "arn:aws:s3:::${local.reconciliation_bucket_name}/*",
      "arn:aws:s3:::${local.aws_glue_bucket_name}",
      "arn:aws:s3:::${local.aws_glue_bucket_name}/*",
    ]
  }
}

data "aws_iam_policy_document" "athena" {
  statement {
    actions   = ["athena:*"]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "glue" {
  statement {
    actions = [
      "glue:*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "lakeformation:*",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kinesis" {
  statement {
    actions = [
      "kinesis:Describe*",
      "kinesis:Get*",
      "kinesis:List*",
      "kinesis:SubscribeToShard",
      "kinesis:PutRecords"
    ]
    effect    = "Allow"
    resources = ["arn:aws:kinesis:${var.region}:${var.aws_account_id}:stream/datalake*"]
  }
}

data "aws_iam_policy_document" "translate" {
  statement {
    effect    = "Allow"
    actions   = ["translate:TranslateText"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "xray" {
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
}


# Datalake raw permissions
resource "aws_lakeformation_permissions" "lambda_datalake_raw_database" {
  principal   = aws_iam_role.iam_for_lambda.arn
  permissions = ["CREATE_TABLE"]

  database {
    name = "datalake_raw"
  }
}

resource "aws_lakeformation_permissions" "lambda_datalake_raw_tables" {
  permissions = [
    "SELECT",
    "DESCRIBE",
    "INSERT",
    "DELETE",
    "DROP",
    "ALTER",
  ]

  principal = aws_iam_role.iam_for_lambda.arn

  table {
    database_name = "datalake_raw"
    wildcard      = true
  }

  lifecycle {
    ignore_changes = [permissions]
  }
}

# Datalake Curated permissions
resource "aws_lakeformation_permissions" "lambda_datalake_curated_database" {
  principal   = aws_iam_role.iam_for_lambda.arn
  permissions = ["CREATE_TABLE"]

  database {
    name = "datalake_curated"
  }
}

resource "aws_lakeformation_permissions" "lambda_datalake_curated_tables" {
  permissions = [
    "SELECT",
    "DESCRIBE",
    "INSERT",
    "DELETE",
    "DROP",
    "ALTER",
  ]

  principal = aws_iam_role.iam_for_lambda.arn

  table {
    database_name = "datalake_curated"
    wildcard      = true
  }

  lifecycle {
    ignore_changes = [permissions]
  }
}


# Datalake Reconciliation permissions
resource "aws_lakeformation_permissions" "lambda_datalake_reconciliation_database" {
  principal   = aws_iam_role.iam_for_lambda.arn
  permissions = ["CREATE_TABLE"]

  database {
    name = "datalake_reconciliation"
  }
}

resource "aws_lakeformation_permissions" "lambda_datalake_reconciliation_tables" {
  permissions = [
    "SELECT",
    "DESCRIBE",
    "INSERT",
    "DELETE",
    "DROP",
    "ALTER",
  ]

  principal = aws_iam_role.iam_for_lambda.arn

  table {
    database_name = "datalake_reconciliation"
    wildcard      = true
  }

  lifecycle {
    ignore_changes = [permissions]
  }
}

resource "aws_lakeformation_permissions" "glue_datalake_raw_database" {
  principal   = aws_iam_role.iam_for_glue.arn
  permissions = ["CREATE_TABLE"]

  database {
    name = "datalake_raw"
  }
}

resource "aws_lakeformation_permissions" "glue_datalake_raw_tables" {
  permissions = [
    "SELECT",
    "DESCRIBE",
    "INSERT",
    "DELETE",
    "DROP",
    "ALTER",
  ]

  principal = aws_iam_role.iam_for_glue.arn

  table {
    database_name = "datalake_raw"
    wildcard      = true
  }

  lifecycle {
    ignore_changes = [permissions]
  }
}
