### Common
aws_account_id  = "187003861892" # prod
bespoke_account = "prod"

### Lambda
lambda_ddb_to_s3_memory_size = 10240

dynamo_recon_table_events = {
  "dynamo_cards_recon" = {
    schedule = "cron(0 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_card_fast_messages_recon" = {
    schedule = "cron(5 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_onfido_recon" = {
    schedule = "cron(10 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_mortgage_app_recon" = {
    schedule = "cron(15 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_mortgage_in_principle" = {
    schedule = "cron(20 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_customer_finances" = {
    schedule = "cron(25 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_cardorders_recon" = {
    schedule = "cron(30 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_riskscore_recon" = {
    schedule = "cron(40 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_riskscorehist_recon" = {
    schedule = "cron(45 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_customer_risk_crm_case_recon" = {
    schedule = "cron(55 2 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_financing_mortgage_recon" = {
    schedule = "cron(0 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_customer_passport_recon" = {
    schedule = "cron(15 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_customer_risk_form_recon" = {
    schedule = "cron(20 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_customer_identity_recon" = {
    schedule = "cron(25 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_cards_status_history_recon" = {
    schedule = "cron(30 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_customer_address_address_recon" = {
    schedule = "cron(35 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_payees_v2_recon" = {
    schedule = "cron(45 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_ias_recurring_recon" = {
    schedule = "cron(50 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_document_verification_recon" = {
    schedule = "cron(55 3 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_confirmation_of_payee_recon" = {
    schedule = "cron(0 4 * * ? *)"
    state    = "DISABLED"
  },
  "dynamo_customers_recon" = {
    schedule = "cron(5 4 * * ? *)"
    state    = "DISABLED"
  },
}

