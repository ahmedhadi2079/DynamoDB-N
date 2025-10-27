###########################################################
# AWS Lambda function: DynamoDB Card fast messages to S3 Raw
###########################################################
module "lambda_dynamodb_to_s3_raw" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.1"

  function_name = "${local.prefix}-dynamodb-to-s3-raw"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  layers        = [local.lambda_layer_aws_wrangler_arn]
  timeout       = 900
  memory_size   = var.lambda_ddb_to_s3_memory_size

  source_path = [
    {
      path             = "../lambdas/dynamodb_lambda_to_s3_raw"
      pip_requirements = true,
      patterns = [
        "!README.md",
        "!tests/.*",
        "!scripts/.*",
      ]
    }
  ]

  environment_variables = {
    S3_RAW = local.raw_datalake_bucket_name
  }

  hash_extra   = "${local.prefix}-dynamodb-to-s3-raw"
  create_role  = false
  lambda_role  = aws_iam_role.iam_for_lambda.arn
  tracing_mode = "Active"
}

###########################################################
# AWS Lambda Triggers - customers
###########################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamocustomerstos3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customers_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 1000
  maximum_batching_window_in_seconds = 60
}

###########################################################
# AWS Lambda Triggers - notifications referral stream
###########################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_notifications_referral_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_notifications_referral_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

###########################################################
# AWS Lambda Triggers - notifications referral code stream
###########################################################
resource "aws_lambda_event_source_mapping" "lambda_new_kinesis_stream_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_notifications_referral_code_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer credentials change history code stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_credentials_change_history_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_credentials_change_history_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer verification attempt stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_verification_attempt_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_verification_attempt_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer block list stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_block_list_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_block_list_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}


#######################################################################
# AWS Lambda Triggers - sls-ddb-cards-card-rules stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_cards_rules_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_cards_rules_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - sls-ddb-cards-card-disabled-rules-history stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_cards_disabled_rules_history_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_cards_disabled_rules_history_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - sls-ddb-investments-model-portfolio stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_investments_model_portfolio_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_investments_model_portfolio_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

############################################################################
# AWS Lambda Triggers - sls-ddb-investments-model-portfolio-rebalance stream
############################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_investments_model_portfolio_rebalance_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_investments_model_portfolio_rebalance_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

############################################################################
# AWS Lambda Triggers - sls-ddb-investments-instrument stream
############################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_investments_instrument_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_investments_instrument_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

############################################################################
# AWS Lambda Triggers - sls-ddb-investments-dividend stream
############################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_investments_dividend_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_investments_dividend_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}
############################################################################
# AWS Lambda Triggers - sls-ddb-investments-daily-fees stream
############################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_investments_daily_fees_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_investments_daily_fees_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}
############################################################################
# AWS Lambda Triggers - sls-ddb-investments-monthly-fees stream
############################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_investments_monthly_fees_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_investments_monthly_fees_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}
#######################################################################
# AWS Lambda Triggers - sls-ddb-investments-order stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_investments_order_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_investments_order_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}
#######################################################################
# AWS Lambda Triggers - exchange rates stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_exchange_rates_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_exchange_rates_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}
############################################################################
# AWS Lambda Triggers - sls-ddb-instant-savings-accounts-products stream
############################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_instant_savings_accounts_products_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_instant_savings_accounts_products_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#################################################################################
# AWS Lambda Triggers - sls-ddb-scheduled-transfers-engine-recurring-rules stream
#################################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_ias_recurring_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_ddb_ias_recurring_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - risk score stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_riskscore_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_risk_score_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - risk crm stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_risk_crm_case_to_s3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_risk_crm_case_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - payment products stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_payments_payment_products_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_payments_payment_products_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - mortgage in principle stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_mortgage_in_principle_event_mapping" {
  count                              = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_mortgage_in_princ_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - default investment user stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_investments_user_event_mapping" {
  count                              = contains(["prod", "beta", "alpha", "sandbox"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_investments_user_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - investment sell stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_investment_sell_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_investments_sell_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - investment funds stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_investment_fund_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_investments_fund_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - home financing mortgage stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_financing_mortgage_event_mapping" {
  count                              = contains(["prod", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_finance_mortgage_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer risk US person stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_risk_us_person_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_risk_us_person_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

###########################################################
# AWS Lambda Triggers - payees_v2
###########################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_sls_payees_v2_tos3_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_sls_ddb_payees_payees_v2_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}
#######################################################################
# AWS Lambda Triggers - card orders
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_card_orders_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_cards_orders_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}
#######################################################################
# AWS Lambda Triggers - cards
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_cards_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_cards_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer passport number stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_passport_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_passport_number_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer identity stream
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_identity_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_identity_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer code challenge
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_reset_code_challenges_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_reset_code_challenges_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer address verification code
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_address_verification_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_address_verification_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - document verification
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_document_verification_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_document_verification_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - risk country score
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_risk_country_score_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_country_risk_score_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer address address
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_address_address_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_address_address_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer finances
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_finances_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_finances_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - onfido
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_onfido_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_onfido_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - customer risk form
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_customer_risk_form_event_mapping" {
  count                              = contains(["prod", "sandbox" ,"alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_customer_risk_form_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

# #######################################################################
# # AWS Lambda Triggers - reset tier history
# #######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_reset_tier_history_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_reset_tiers_history_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - clearbank transactions
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_clearbank_transactions_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_clearbank_transactions_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - confirmation_of_payee
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_confirmation_of_payee_event_mapping" {
  count                              = contains(["prod", "sandbox", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_confirmation_of_payee_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - card status history
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_card_status_history_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_cards_status_history_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - home financing mortgage application
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_home_financing_mortgage_application_event_mapping" {
  count                              = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_mortgage_app_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - card fast messages
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_card_fast_messages_event_mapping" {
  count                              = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_cards_fast_messages_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}

#######################################################################
# AWS Lambda Triggers - risk score history
#######################################################################
resource "aws_lambda_event_source_mapping" "lambda_dynamo_risk_score_history_event_mapping" {
  count                              = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  event_source_arn                   = aws_kinesis_stream.dynamodb_risk_score_hist_stream[0].arn
  function_name                      = module.lambda_dynamodb_to_s3_raw.lambda_function_arn
  starting_position                  = "LATEST"
  parallelization_factor             = 3
  batch_size                         = 10000
  maximum_batching_window_in_seconds = 300
}
