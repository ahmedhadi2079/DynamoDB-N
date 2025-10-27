###########################################################
# DynamoDB Table and Kinesis integration = customers
###########################################################
resource "aws_kinesis_stream" "dynamodb_customers_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customers"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customers_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customers_stream[0].arn
  table_name = data.aws_ssm_parameter.users_customers_table_name.value
}

###########################################################
# DynamoDB Table and Kinesis integration = card fast messages
###########################################################
resource "aws_kinesis_stream" "dynamodb_cards_fast_messages_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-cards-fast-messages"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "cards_fast_messsages_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_cards_fast_messages_stream[0].arn
  table_name = data.aws_ssm_parameter.cards_fast_messages_table_name.value
}

#####################################
#### dynamo cards kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_cards_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-cards"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "cards_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_cards_stream[0].arn
  table_name = data.aws_ssm_parameter.cards_cards_table_name.value
}

#####################################
#### dynamo onfido kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_onfido_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-onfido"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "onfido_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_onfido_stream[0].arn
  table_name = data.aws_ssm_parameter.users_onfido_table_name.value
}

#####################################
#### dynamo mortgage app kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_mortgage_app_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-mortgage-application"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "mortgage_app_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_mortgage_app_stream[0].arn
  table_name = data.aws_ssm_parameter.home_financing_mortgage_application_table_name.value
}

#####################################
#### dynamo mortgage in principle kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_mortgage_in_princ_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-mortgage-in-principle"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "mortgage_in_princ_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_mortgage_in_princ_stream[0].arn
  table_name = data.aws_ssm_parameter.home_financing_mortgage_in_principle_table_name.value
}

###########################################################
# Kinesis Stream investment sell
###########################################################

resource "aws_kinesis_stream" "dynamodb_investments_sell_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-investments-sell"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "dynamodb_default_investments_sell_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_investments_sell_stream[0].arn
  table_name = data.aws_ssm_parameter.investments_sell_table_name.value
}

#####################################
#### dynamo cardorders kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_cards_orders_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-cards-orders"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "cards_orders_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_cards_orders_stream[0].arn
  table_name = data.aws_ssm_parameter.cards_orders_table_name.value
}

#####################################
#### dynamo risk_score_hist kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_risk_score_hist_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-risk-score-history"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "risk_score_hist_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_risk_score_hist_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_risk_score_history_table_name.value
}

#####################################
#### dynamo investment user kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_investments_user_stream" {
  count            = contains(["prod", "beta", "alpha", "sandbox"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-investments-user"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "investmentuser_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "alpha", "sandbox"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_investments_user_stream[0].arn
  table_name = data.aws_ssm_parameter.investments_user_table_name.value
}

#####################################
#### dynamo investment fund kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_investments_fund_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-investments-fund"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "investmentfund_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_investments_fund_stream[0].arn
  table_name = data.aws_ssm_parameter.investments_fund_table_name.value
}

###########################################################
# DynamoDB Table and Kinesis integration customer finances
###########################################################

resource "aws_kinesis_stream" "dynamodb_customer_finances_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-finances"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customer_finances_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_finances_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_finances_table_name.value
}

#####################################
#### dynamo risk_score kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_risk_score_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-risk-score"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "risk_score_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_risk_score_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_risk_score_table_name.value
}

#######################################################
#### dynamo document_verification kinesis stream ####
#######################################################

resource "aws_kinesis_stream" "dynamodb_document_verification_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-document-verification"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "document_verification_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_document_verification_stream[0].arn
  table_name = data.aws_ssm_parameter.document_verification_table_name.value
}

#####################################
#### dynamo countryrisk_score kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_country_risk_score_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-risk-country-score"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "country_risk_score_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_country_risk_score_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_risk_country_score_table_name.value
}

#####################################
#### dynamo risk_crm_case kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_risk_crm_case_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-risk-crm-case"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

data "aws_dynamodb_table" "riskcrmcasedynamodbtable" {
  name = "sls-ddb-customer-risk-crm-case"
}

resource "aws_dynamodb_kinesis_streaming_destination" "risk_crm_case_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_risk_crm_case_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_risk_crm_case_table_name.value
}
##################################################################################
#### dynamo profile_orchestration_passcode_reset_tiers_history kinesis stream ####
##################################################################################

resource "aws_kinesis_stream" "dynamodb_reset_tiers_history_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-reset-tiers-history"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "reset_tiers_history_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_reset_tiers_history_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_profile_orchestrations_passcode_reset_tiers_history_table_name.value
}

#####################################
#### dynamo customer-address-verification-code kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_customer_address_verification_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-address-verification"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customer_address_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_address_verification_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_address_verification_code_table_name.value
}

#####################################
#### dynamo customer-address-passport-number kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_customer_passport_number_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-passport"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customer_passport_number_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_passport_number_stream[0].arn
  table_name = data.aws_ssm_parameter.users_customer_passport_number_table_name.value
}

##################################################################################
#### dynamo profile_orchestration_passcode_reset_code_challenges kinesis stream ####
##################################################################################

resource "aws_kinesis_stream" "dynamodb_reset_code_challenges_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-reset-code-challenges"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "reset_code_challenges_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_reset_code_challenges_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_profile_orchestrations_passcode_reset_code_challenges_table_name.value
}

#####################################
#### dynamo customer risk_form_data kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_customer_risk_form_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-risk-form"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customer_risk_form__dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_risk_form_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_risk_form_data_table_name.value
}

########################################################
#### dynamo sls-ddb-payees-payees-v2 kinesis stream ####
########################################################

resource "aws_kinesis_stream" "dynamodb_sls_ddb_payees_payees_v2_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-ddb-payees-payees-v2"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_ddb_payees_payees_v2__dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_ddb_payees_payees_v2_stream[0].arn
  table_name = data.aws_ssm_parameter.payees_payees_v2_table_name.value
}

###############################################################
#### dynamo IAS-recurring-transfers kinesis stream ####
###############################################################

resource "aws_kinesis_stream" "dynamodb_sls_ddb_ias_recurring_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-ddb-ias-recurring"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "sls_ddb_ias_recurring_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_ddb_ias_recurring_stream[0].arn
  table_name = data.aws_ssm_parameter.ias_recurring_transfers_table_name.value
}

#####################################
#### dynamo customer risk_us_person_data kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_customer_risk_us_person_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-risk-us-person"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "customer_risk_us_person__dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_risk_us_person_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_risk_us_person_table_name.value
}

#################################################
#### dynamo customer-identity kinesis stream ####
#################################################

resource "aws_kinesis_stream" "dynamodb_customer_identity_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-identity"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "customer_identity_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_identity_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_identity_identity_table_name.value
}

#################################################
#### dynamo exchange-rates kinesis stream ####
#################################################

resource "aws_kinesis_stream" "dynamodb_exchange_rates_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-exchange-rates"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "exchange_rates_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_exchange_rates_stream[0].arn
  table_name = data.aws_ssm_parameter.exchange_rates_exchange_rates_table_name.value
}

#################################################
#### dynamo cards-status-history kinesis stream ####
#################################################

resource "aws_kinesis_stream" "dynamodb_cards_status_history_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-cards-status-history-identity"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "cards_status_history_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_cards_status_history_stream[0].arn
  table_name = data.aws_ssm_parameter.cards_status_history_table_name.value
}

#####################################
#### dynamo customer-address-address- kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_customer_address_address_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-address-address"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customer_address_address_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_address_address_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_address_address_table_name.value
}

#####################################
#### dynamo payment products kinesis stream ####
#####################################

resource "aws_kinesis_stream" "dynamodb_payments_payment_products_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-payments-payment-products"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "payments_payment_products_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_payments_payment_products_stream[0].arn
  table_name = data.aws_ssm_parameter.payments_payment_products_table_name.value
}

#######################################################
#### dynamo confirmation_of_payee kinesis stream ####
#######################################################

resource "aws_kinesis_stream" "dynamodb_confirmation_of_payee_stream" {
  count            = contains(["prod", "beta", "sandbox"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-confirmation-of-payee"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "confirmation_of_payee_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_confirmation_of_payee_stream[0].arn
  table_name = data.aws_ssm_parameter.confirmation_of_payee_table_name.value
}

######################################################
#### dynamo clearbank transactions kinesis stream ####
######################################################

resource "aws_kinesis_stream" "dynamodb_clearbank_transactions_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-clearbank-transactions"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "clearbank_transactions_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_clearbank_transactions_stream[0].arn
  table_name = data.aws_ssm_parameter.clearbank_transactions_table_name.value
}

######################################################
#### dynamo notifications referral kinesis stream ####
######################################################

resource "aws_kinesis_stream" "dynamodb_notifications_referral_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-notifications-referral"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "notifications_referral_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_notifications_referral_stream[0].arn
  table_name = data.aws_ssm_parameter.notifications_referral_table_name.value
}

######################################################
#### dynamo notifications referral code kinesis stream ####
######################################################

resource "aws_kinesis_stream" "dynamodb_notifications_referral_code_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-notifications-referral-code"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "notifications_referral_code_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_notifications_referral_code_stream[0].arn
  table_name = data.aws_ssm_parameter.notifications_referral_code_table_name.value
}

##############################################################
#### dynamo customer-credentials-change-history kinesis stream ####
##############################################################

resource "aws_kinesis_stream" "dynamodb_customer_credentials_change_history_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-credentials-change-history"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customer_credentials_change_history_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_credentials_change_history_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_credentials_change_history_table_name.value
}

##############################################################
#### dynamo customer-verification-attempt kinesis stream ####
##############################################################

resource "aws_kinesis_stream" "dynamodb_customer_verification_attempt_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-verification-attempt"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customer_verification_attempt_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_verification_attempt_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_verification_attempt_table_name.value
}

##############################################################
#### dynamo customer-block-list kinesis stream ####
##############################################################

resource "aws_kinesis_stream" "dynamodb_customer_block_list_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-customer-block-list"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "customer_block_list_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_customer_block_list_stream[0].arn
  table_name = data.aws_ssm_parameter.customer_block_list_table_name.value
}

########################################################
#### dynamo sls-ddb-cards-card-rules kinesis stream ####
########################################################

resource "aws_kinesis_stream" "dynamodb_sls_cards_rules_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-cards-rules"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_cards_rules_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_cards_rules_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_cards_rules_stream_table_name.value
}

#########################################################################
#### dynamo sls-ddb-cards-card-disabled-rules-history kinesis stream ####
#########################################################################

resource "aws_kinesis_stream" "dynamodb_sls_cards_disabled_rules_history_stream" {
  count            = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-cards-disabled-rules-history"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_cards_disabled_rules_history_dynamo_to_kinesis" {
  count      = contains(["prod", "beta", "sandbox", "alpha"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_cards_disabled_rules_history_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_cards_disabled_rules_history_table_name.value
}

#########################################################################
#### dynamo sls-ddb-investments-model-portfolio kinesis stream ####
#########################################################################

resource "aws_kinesis_stream" "dynamodb_sls_investments_model_portfolio_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-investments-model-portfolio"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_investments_model_portfolio_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_investments_model_portfolio_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_investments_model_portfolio_table_name.value
}

#########################################################################
#### dynamo sls-ddb-investments-model-portfolio-rebalance kinesis stream ####
#########################################################################

resource "aws_kinesis_stream" "dynamodb_sls_investments_model_portfolio_rebalance_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-investments-model-portfolio-rebalance"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_investments_model_portfolio_rebalance_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_investments_model_portfolio_rebalance_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_investments_model_portfolio_rebalance_table_name.value
}

#########################################################################
#### dynamo sls-ddb-investments-instrument kinesis stream ####
#########################################################################

resource "aws_kinesis_stream" "dynamodb_sls_investments_instrument_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-investments-instrument"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_investments_instrument_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_investments_instrument_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_investments_instrument_table_name.value
}

#########################################################################
#### dynamo sls-ddb-investments-dividend kinesis stream ####
#########################################################################

resource "aws_kinesis_stream" "dynamodb_sls_investments_dividend_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-investments-dividend"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_investments_dividend_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_investments_dividend_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_investments_dividend_table_name.value
}
#########################################################################
#### dynamo sls-ddb-investments-daily-fees kinesis stream ####
#########################################################################

resource "aws_kinesis_stream" "dynamodb_sls_investments_daily_fees_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-investments-daily-fees"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_investments_daily_fees_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_investments_daily_fees_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_investments_daily_fees_table_name.value
}
#########################################################################
#### dynamo sls-ddb-investments-monthly-fees kinesis stream ####
#########################################################################

resource "aws_kinesis_stream" "dynamodb_sls_investments_monthly_fees_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-investments-monthly-fees"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_investments_monthly_fees_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_investments_monthly_fees_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_investments_monthly_fees_table_name.value
}

###########################################################
# dynamo sls-ddb-investments-order kinesis stream ####
###########################################################

resource "aws_kinesis_stream" "dynamodb_sls_investments_order_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-investments-order"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "sls_investments_order_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_investments_order_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_investments_order_table_name.value
}

#########################################################################
#### dynamo sls-ddb-instant-savings-accounts-products kinesis stream ####
#########################################################################

resource "aws_kinesis_stream" "dynamodb_sls_instant_savings_accounts_products_stream" {
  count            = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-instant-savings-accounts-products"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}


resource "aws_dynamodb_kinesis_streaming_destination" "sls_instant_savings_accounts_products_dynamo_to_kinesis" {
  count      = contains(["prod", "sandbox", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_instant_savings_accounts_products_stream[0].arn
  table_name = data.aws_ssm_parameter.sls_instant_savings_accounts_products_table_name.value
}

###########################################################
# dynamo sls-ddb-home-financing-mortgage kinesis stream ####
###########################################################

resource "aws_kinesis_stream" "dynamodb_sls_finance_mortgage_stream" {
  count            = contains(["prod", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  name             = "${local.prefix}-stream-sls-financing-mortgage"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
}

resource "aws_dynamodb_kinesis_streaming_destination" "sls_finance_mortgage_dynamo_to_kinesis" {
  count      = contains(["prod", "alpha", "beta"], var.bespoke_account) ? 1 : 0
  stream_arn = aws_kinesis_stream.dynamodb_sls_finance_mortgage_stream[0].arn
  table_name = data.aws_ssm_parameter.home_financing_mortgage_table_name.value
}
