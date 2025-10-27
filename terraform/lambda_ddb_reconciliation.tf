# ###########################################################
# # AWS Lambda function: DynamoDB Recon
# ###########################################################
module "lambda_ddb_datalake_recon" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.1"

  function_name = "${local.prefix}-reconciliation"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 900
  layers        = [local.lambda_layer_aws_wrangler_arn]
  memory_size   = 10240

  source_path = [
    "../lambdas/ddb_reconciliation",
  ]

  environment_variables = {
    S3_RECON                          = local.reconciliation_bucket_name,
    DYNAMODB_CUSTOMERS                = data.aws_ssm_parameter.users_customers_table_name.value,
    DYNAMODB_CARD_FAST_MESSAGES       = data.aws_ssm_parameter.cards_fast_messages_table_name.value,
    DYNAMODB_CARDS                    = data.aws_ssm_parameter.cards_cards_table_name.value,
    DYNAMODB_RISKSCORE                = data.aws_ssm_parameter.customer_risk_score_table_name.value,
    DYNAMODB_RISKSCOREHIST            = data.aws_ssm_parameter.customer_risk_score_history_table_name.value,
    DYNAMODB_CARDORDERS               = data.aws_ssm_parameter.cards_orders_table_name.value,
    DYNAMODB_ONFIDO                   = data.aws_ssm_parameter.users_onfido_table_name.value,
    DYNAMODB_MORTGAGE_APP             = data.aws_ssm_parameter.home_financing_mortgage_application_table_name.value,
    DYNAMODB_MORTGAGE_IN_PRINC        = data.aws_ssm_parameter.home_financing_mortgage_in_principle_table_name.value,
    DYNAMODB_CUST_FINANCES            = data.aws_ssm_parameter.customer_finances_table_name.value,
    DYNAMODB_INVESTMENTUSER           = data.aws_ssm_parameter.investments_user_table_name.value,
    DYNAMODB_INVESTMENTSORDERS        = data.aws_ssm_parameter.sls_investments_monthly_fees_table_name.value,
    DYNAMODB_COUNTRYRISKSCORE         = data.aws_ssm_parameter.customer_risk_country_score_table_name.value,
    DYNAMODB_RISKSCRM                 = data.aws_ssm_parameter.customer_risk_crm_case_table_name.value,
    DYNAMODB_FINANCING_MORTGAGE       = data.aws_ssm_parameter.home_financing_mortgage_table_name.value,
    DYNAMODB_RESETTIERSHISTORY        = data.aws_ssm_parameter.customer_profile_orchestrations_passcode_reset_tiers_history_table_name.value,
    DYNAMODB_RESETCODECHALLENGES      = data.aws_ssm_parameter.customer_profile_orchestrations_passcode_reset_code_challenges_table_name.value,
    DYNAMODB_CUSTOMER_PASSPORT        = data.aws_ssm_parameter.users_customer_passport_number_table_name.value,
    DYNAMODB_CUSTOMER_RISKFORM        = data.aws_ssm_parameter.customer_risk_form_data_table_name.value,
    DYNAMODB_CUSTOMER_IDENTITY        = data.aws_ssm_parameter.customer_identity_identity_table_name.value,
    DYNAMODB_CARDS_STATUS_HISTORY     = data.aws_ssm_parameter.cards_status_history_table_name.value,
    DYNAMODB_CUSTOMER_ADDRESS_ADDRESS = data.aws_ssm_parameter.customer_address_address_table_name.value,
    DYNAMODB_EXCHANGE_RATES           = data.aws_ssm_parameter.exchange_rates_exchange_rates_table_name.value,
    DYNAMODB_PAYEES_V2                = data.aws_ssm_parameter.payees_payees_v2_table_name.value,
    DYNAMODB_DOCUMENT_VERIFICATION    = data.aws_ssm_parameter.document_verification_table_name.value,
    DYNAMODB_IAS_RECURRING            = data.aws_ssm_parameter.ias_recurring_transfers_table_name.value,
    DYNAMODB_CONFIRMATION_OF_PAYEE    = data.aws_ssm_parameter.confirmation_of_payee_table_name.value,
  }

  hash_extra   = "${local.prefix}-reconciliation"
  create_role  = false
  lambda_role  = aws_iam_role.iam_for_lambda.arn
  tracing_mode = "Active"
}

###########################################################
# AWS Event Bridge Rule
###########################################################

resource "aws_cloudwatch_event_rule" "schedule_ddb_datalake_recon" {
  for_each            = var.dynamo_recon_table_events
  name                = "datalake_raw_${each.key}_events"
  description         = "Schedule Lambda function execution for ${each.key} Reconciliation"
  schedule_expression = each.value.schedule
  state               = each.value.state
}

resource "aws_cloudwatch_event_target" "dynamodb_datalake_recon_lambdaexecution" {
  for_each = var.dynamo_recon_table_events
  arn      = module.lambda_ddb_datalake_recon.lambda_function_arn
  rule     = aws_cloudwatch_event_rule.schedule_ddb_datalake_recon[each.key].name

  input = jsonencode({
    dynamo_recon_table = each.key
  })
}

###########################################################
# AWS Lambda Trigger
###########################################################
resource "aws_lambda_permission" "dynamodb_datalake_recon_allow_cloudwatch_event_rule" {
  for_each      = var.dynamo_recon_table_events
  statement_id  = "AllowExecutionFromCloudWatch_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_ddb_datalake_recon.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_ddb_datalake_recon[each.key].arn
}
