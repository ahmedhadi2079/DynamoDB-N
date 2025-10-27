# Users Customers Table
data "aws_ssm_parameter" "users_customers_table_name" {
  name = "/nomo/sls_dynamodb/users/ddb_table/customers/name"
}

data "aws_ssm_parameter" "users_customers_table_arn" {
  name = "/nomo/sls_dynamodb/users/ddb_table/customers/arn"
}

# Home Financing Mortgage Application Table
data "aws_ssm_parameter" "home_financing_mortgage_application_table_name" {
  name = "/nomo/sls_dynamodb/home_financing/ddb_table/mortgage_application/name"
}

data "aws_ssm_parameter" "home_financing_mortgage_application_table_arn" {
  name = "/nomo/sls_dynamodb/home_financing/ddb_table/mortgage_application/arn"
}

# Home Financing Mortgage In Principle Table
data "aws_ssm_parameter" "home_financing_mortgage_in_principle_table_name" {
  name = "/nomo/sls_dynamodb/home_financing/ddb_table/mortgage_in_principle/name"
}

data "aws_ssm_parameter" "home_financing_mortgage_in_principle_table_arn" {
  name = "/nomo/sls_dynamodb/home_financing/ddb_table/mortgage_in_principle/arn"
}

# Customer Finances Table
data "aws_ssm_parameter" "customer_finances_table_name" {
  name = "/nomo/sls_dynamodb/customer_finances/ddb_table/customer_finances/name"
}

data "aws_ssm_parameter" "customer_finances_table_arn" {
  name = "/nomo/sls_dynamodb/customer_finances/ddb_table/customer_finances/arn"
}

# Investments Order Table
data "aws_ssm_parameter" "sls_investments_order_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/order/name"
}

data "aws_ssm_parameter" "sls_investments_order_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/order/arn"
}

# Investments Sell Table
data "aws_ssm_parameter" "investments_sell_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/sell/name"
}

data "aws_ssm_parameter" "investments_sell_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/sell/arn"
}


# Investments User Table
data "aws_ssm_parameter" "investments_user_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/user/name"
}

data "aws_ssm_parameter" "investments_user_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/user/arn"
}

# Investments Fund Table
data "aws_ssm_parameter" "investments_fund_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/fund/name"
}

data "aws_ssm_parameter" "investments_fund_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/fund/arn"
}

# Customer Profile Orchestrations Passcode Reset Tiers History Table
data "aws_ssm_parameter" "customer_profile_orchestrations_passcode_reset_tiers_history_table_name" {
  name = "/nomo/sls_dynamodb/customer-profile-orchestration/ddb_table/passcode_reset_tiers_history/name"
}

data "aws_ssm_parameter" "customer_profile_orchestrations_passcode_reset_tiers_history_table_arn" {
  name = "/nomo/sls_dynamodb/customer-profile-orchestration/ddb_table/passcode_reset_tiers_history/arn"
}

# Customer Profile Orchestrations Passcode Reset Code Challenges Table
data "aws_ssm_parameter" "customer_profile_orchestrations_passcode_reset_code_challenges_table_name" {
  name = "/nomo/sls_dynamodb/customer-profile-orchestration/ddb_table/passcode_reset_code_challenges/name"
}

data "aws_ssm_parameter" "customer_profile_orchestrations_passcode_reset_code_challenges_table_arn" {
  name = "/nomo/sls_dynamodb/customer-profile-orchestration/ddb_table/passcode_reset_code_challenges/arn"
}

# Customer Risk Score Table
data "aws_ssm_parameter" "customer_risk_score_table_name" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/score/name"
}

data "aws_ssm_parameter" "customer_risk_score_table_arn" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/score/arn"
}

# Customer Risk Score History Table
data "aws_ssm_parameter" "customer_risk_score_history_table_name" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/score_history/name"
}

data "aws_ssm_parameter" "customer_risk_score_history_table_arn" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/score_history/arn"
}

# Customer Risk Form Data Table
data "aws_ssm_parameter" "customer_risk_form_data_table_name" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/form_data/name"
}

data "aws_ssm_parameter" "customer_risk_form_data_table_arn" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/form_data/arn"
}

# Customer Identity Identity Table
data "aws_ssm_parameter" "customer_identity_identity_table_name" {
  name = "/nomo/sls_dynamodb/customer_identity/ddb_table/identity/name"
}

data "aws_ssm_parameter" "customer_identity_identity_table_arn" {
  name = "/nomo/sls_dynamodb/customer_identity/ddb_table/identity/arn"
}

# Customer Address Verification Code Table
data "aws_ssm_parameter" "customer_address_verification_code_table_name" {
  name = "/nomo/sls_dynamodb/customer_address/ddb_table/verification_code/name"
}

data "aws_ssm_parameter" "customer_address_verification_code_table_arn" {
  name = "/nomo/sls_dynamodb/customer_address/ddb_table/verification_code/arn"
}

# Customer Risk US Person Table
data "aws_ssm_parameter" "customer_risk_us_person_table_name" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/us_person/name"
}

data "aws_ssm_parameter" "customer_risk_us_person_table_arn" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/us_person/arn"
}

# Customer Risk Country Score Table
data "aws_ssm_parameter" "customer_risk_country_score_table_name" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/country_score/name"
}

data "aws_ssm_parameter" "customer_risk_country_score_table_arn" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/country_score/arn"
}

# Customer Risk CRM Case Table
data "aws_ssm_parameter" "customer_risk_crm_case_table_name" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/crm_case/name"
}

data "aws_ssm_parameter" "customer_risk_crm_case_table_arn" {
  name = "/nomo/sls_dynamodb/customer_risk/ddb_table/crm_case/arn"
}

# Cards Cards Table
data "aws_ssm_parameter" "cards_cards_table_name" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/cards/name"
}

data "aws_ssm_parameter" "cards_cards_table_arn" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/cards/arn"
}

# Cards Fast Messages Table
data "aws_ssm_parameter" "cards_fast_messages_table_name" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/fast_messages/name"
}

data "aws_ssm_parameter" "cards_fast_messages_table_arn" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/fast_messages/arn"
}

# Cards Orders Table
data "aws_ssm_parameter" "cards_orders_table_name" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/orders/name"
}

data "aws_ssm_parameter" "cards_orders_table_arn" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/orders/arn"
}

# Cards Status History Table
data "aws_ssm_parameter" "cards_status_history_table_name" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/cards_status_history/name"
}

data "aws_ssm_parameter" "cards_status_history_table_arn" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/cards_status_history/arn"
}

# Users Onfido Table
data "aws_ssm_parameter" "users_onfido_table_name" {
  name = "/nomo/sls_dynamodb/users/ddb_table/onfido/name"
}

data "aws_ssm_parameter" "users_onfido_table_arn" {
  name = "/nomo/sls_dynamodb/users/ddb_table/onfido/arn"
}

# Users Customer Passport Number Table
data "aws_ssm_parameter" "users_customer_passport_number_table_name" {
  name = "/nomo/sls_dynamodb/users/ddb_table/customer_passport_number/name"
}

data "aws_ssm_parameter" "users_customer_passport_number_table_arn" {
  name = "/nomo/sls_dynamodb/users/ddb_table/customer_passport_number/arn"
}

# Customer Address Address Table
data "aws_ssm_parameter" "customer_address_address_table_name" {
  name = "/nomo/sls_dynamodb/customer_address/ddb_table/address/name"
}

data "aws_ssm_parameter" "customer_address_address_table_arn" {
  name = "/nomo/sls_dynamodb/customer_address/ddb_table/address/arn"
}

# Exchange Rates Table
data "aws_ssm_parameter" "exchange_rates_exchange_rates_table_name" {
  name = "/nomo/sls_dynamodb/exchange_rates/ddb_table/exchange_rates/name"
}

data "aws_ssm_parameter" "exchange_rates_exchange_rates_table_arn" {
  name = "/nomo/sls_dynamodb/exchange_rates/ddb_table/exchange_rates/arn"
}

# Payees Payees V2 Table
data "aws_ssm_parameter" "payees_payees_v2_table_name" {
  name = "/nomo/sls_dynamodb/payees/ddb_table/payees-v2/name"
}

data "aws_ssm_parameter" "payees_payees_v2_table_arn" {
  name = "/nomo/sls_dynamodb/payees/ddb_table/payees-v2/arn"
}

# Home Financing Mortgage Table
data "aws_ssm_parameter" "home_financing_mortgage_table_name" {
  name = "/nomo/sls_dynamodb/home_financing/ddb_table/mortgage/name"
}

data "aws_ssm_parameter" "home_financing_mortgage_table_arn" {
  name = "/nomo/sls_dynamodb/home_financing/ddb_table/mortgage/arn"
}

# payment products Table
data "aws_ssm_parameter" "payments_payment_products_table_name" {
  name = "/nomo/sls_dynamodb/payments/ddb_table/payment_products/name"
}

data "aws_ssm_parameter" "payments_payment_products_table_arn" {
  name = "/nomo/sls_dynamodb/payments/ddb_table/payment_products/arn"
}

# IAS-recurring-transfers Table
data "aws_ssm_parameter" "ias_recurring_transfers_table_name" {
  name = "/nomo/sls_dynamodb/scheduled_transfers_engine/ddb_table/recurring_rules/name"
}

data "aws_ssm_parameter" "ias_recurring_transfers_table_arn" {
  name = "/nomo/sls_dynamodb/scheduled_transfers_engine/ddb_table/recurring_rules/arn"
}

# AWS Glue bucket SSM
data "aws_ssm_parameter" "aws_glue_bucket_name" {
  name = "/nomo/data_dependencies/s3/aws_glue_assets/name"
}

# document-verification Table
data "aws_ssm_parameter" "document_verification_table_name" {
  name = "/nomo/sls_dynamodb/document_verification/ddb_table/document_verification/name"
}

data "aws_ssm_parameter" "document_verification_table_arn" {
  name = "/nomo/sls_dynamodb/document_verification/ddb_table/document_verification/arn"
}

# confirmation-of-payee Table
data "aws_ssm_parameter" "confirmation_of_payee_table_name" {
  name = "/nomo/sls_dynamodb/confirmation_of_payee/ddb_table/logs/name"
}

data "aws_ssm_parameter" "confirmation_of_payee_table_arn" {
  name = "/nomo/sls_dynamodb/confirmation_of_payee/ddb_table/logs/arn"
}

# clear bank transactions
data "aws_ssm_parameter" "clearbank_transactions_table_name" {
  name = "/nomo/sls_dynamodb/clearbank/ddb_table/transactions/name"
}

data "aws_ssm_parameter" "clearbank_transactions_table_arn" {
  name = "/nomo/sls_dynamodb/clearbank/ddb_table/transactions/arn"
}

# notifications referral Table
data "aws_ssm_parameter" "notifications_referral_table_name" {
  name = "/nomo/sls_dynamodb/notifications/ddb_table/referral/name"
}

data "aws_ssm_parameter" "notifications_referral_table_arn" {
  name = "/nomo/sls_dynamodb/notifications/ddb_table/referral/arn"
}

# notifications referral code Table
data "aws_ssm_parameter" "notifications_referral_code_table_name" {
  name = "/nomo/sls_dynamodb/notifications/ddb_table/referral_code/name"
}

data "aws_ssm_parameter" "notifications_referral_code_table_arn" {
  name = "/nomo/sls_dynamodb/notifications/ddb_table/referral_code/arn"
}

# customer credentials change history Table
data "aws_ssm_parameter" "customer_credentials_change_history_table_name" {
  name = "/nomo/sls_dynamodb/auth/ddb_table/customer_credentials_change_history/name"
}

data "aws_ssm_parameter" "customer_credentials_change_history_table_arn" {
  name = "/nomo/sls_dynamodb/auth/ddb_table/customer_credentials_change_history/arn"
}

# customer verification attempt table
data "aws_ssm_parameter" "customer_verification_attempt_table_name" {
  name = "/nomo/sls_dynamodb/auth/ddb_table/customer_verification_attempt/name"
}

data "aws_ssm_parameter" "customer_verification_attempt_table_arn" {
  name = "/nomo/sls_dynamodb/auth/ddb_table/customer_verification_attempt/arn"
}

# customer block list table
data "aws_ssm_parameter" "customer_block_list_table_name" {
  name = "/nomo/sls_dynamodb/auth/ddb_table/customer_block_list/name"
}

data "aws_ssm_parameter" "customer_block_list_table_arn" {
  name = "/nomo/sls_dynamodb/auth/ddb_table/customer_block_list/arn"
}

# data "aws_glue_job" "glue_rds_crawler_job" {
#   job_name = "rds-export-crawler"
# }

# sls-ddb-cards-card-rules list table
data "aws_ssm_parameter" "sls_cards_rules_stream_table_name" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/card_rules/name"
}

data "aws_ssm_parameter" "sls_cards_rules_stream__table_arn" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/card_rules/arn"
}


# sls-ddb-cards-card-disabled-rules-history list table
data "aws_ssm_parameter" "sls_cards_disabled_rules_history_table_name" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/card_disabled_rules_history/name"
}

data "aws_ssm_parameter" "sls_cards_rules_strsls_cards_disabled_rules_history_table_arn" {
  name = "/nomo/sls_dynamodb/cards/ddb_table/card_disabled_rules_history/arn"
}

# sls-ddb-investments-model-portfolio list table
data "aws_ssm_parameter" "sls_investments_model_portfolio_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/model_portfolio/name"
}

data "aws_ssm_parameter" "sls_investments_model_portfolio_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/model_portfolio/arn"
}

# sls-ddb-investments-model-portfolio-rebalance list table
data "aws_ssm_parameter" "sls_investments_model_portfolio_rebalance_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/model_portfolio_rebalance/name"
}

data "aws_ssm_parameter" "sls_investments_model_portfolio_rebalance_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/model_portfolio_rebalance/arn"
}

# sls-ddb-investments-instrument list table
data "aws_ssm_parameter" "sls_investments_instrument_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/instrument/name"
}

data "aws_ssm_parameter" "sls_investments_instrument_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/instrument/arn"
}

# sls-ddb-investments-dividend list table
data "aws_ssm_parameter" "sls_investments_dividend_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/dividend/name"
}

data "aws_ssm_parameter" "sls_investments_dividend_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/dividend/arn"
}

# sls-ddb-investments-daily-fees list table
data "aws_ssm_parameter" "sls_investments_daily_fees_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/daily_fees/name"
}

data "aws_ssm_parameter" "sls_investments_daily_fees_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/daily_fees/arn"
}

# sls-ddb-investments-monthly-fees list table
data "aws_ssm_parameter" "sls_investments_monthly_fees_table_name" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/monthly_fees/name"
}

data "aws_ssm_parameter" "sls_investments_monthly_fees_table_arn" {
  name = "/nomo/sls_dynamodb/investments/ddb_table/monthly_fees/arn"
}

# sls-ddb-instant-savings-accounts-products list table
data "aws_ssm_parameter" "sls_instant_savings_accounts_products_table_name" {
  name = "/nomo/sls_dynamodb/instant_savings_accounts/ddb_table/products/name"
}

data "aws_ssm_parameter" "sls_instant_savings_accounts_products_table_arn" {
  name = "/nomo/sls_dynamodb/instant_savings_accounts/ddb_table/products/arn"
}

