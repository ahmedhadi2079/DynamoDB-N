dynamo_tables = {
    "dynamo_cards_recon": {
        "reconcile_sql_path": "6518_cards.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CARDS",
        "threshold": 0.9995,
    },
    "dynamo_card_fast_messages_recon": {
        "reconcile_sql_path": "6978_card_fast_messages.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CARD_FAST_MESSAGES",
        "threshold": 0.999,
    },
    "dynamo_onfido_recon": {
        "reconcile_sql_path": "7485_onfido.sql",
        "dynamo_table_env_var_name": "DYNAMODB_ONFIDO",
        "threshold": 0.9995,
    },
    "dynamo_mortgage_app_recon": {
        "reconcile_sql_path": "11130_mortgage_application.sql",
        "dynamo_table_env_var_name": "DYNAMODB_MORTGAGE_APP",
        "threshold": 0.9995,
    },
    "dynamo_mortgage_in_principle": {
        "reconcile_sql_path": "11131_mortgage_in_principle.sql",
        "dynamo_table_env_var_name": "DYNAMODB_MORTGAGE_IN_PRINC",
        "threshold": 0.9995,
    },
    "dynamo_customer_finances": {
        "reconcile_sql_path": "11675_customer_finances.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CUST_FINANCES",
        "threshold": 0.9995,
    },
    "dynamo_cardorders_recon": {
        "reconcile_sql_path": "13439_cardorders.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CARDORDERS",
        "threshold": 0.9995,
    },
    "dynamo_riskscore_recon": {
        "reconcile_sql_path": "13443_risk_score.sql",
        "dynamo_table_env_var_name": "DYNAMODB_RISKSCORE",
        "threshold": 0.9995,
    },
    "dynamo_riskscorehist_recon": {
        "reconcile_sql_path": "13444_risk_score_hist.sql",
        "dynamo_table_env_var_name": "DYNAMODB_RISKSCOREHIST",
        "threshold": 0.9995,
    },
    "dynamo_customer_risk_crm_case_recon": {
        "reconcile_sql_path": "13446_risk_crm.sql",
        "dynamo_table_env_var_name": "DYNAMODB_RISKSCRM",
        "threshold": 0.9995,
    },
    "dynamo_financing_mortgage_recon": {
        "reconcile_sql_path": "13447_financing-mortgage.sql",
        "dynamo_table_env_var_name": "DYNAMODB_FINANCING_MORTGAGE",
        "threshold": 0.9995,
    },
    "dynamo_customer_passport_recon": {
        "reconcile_sql_path": "13451_customer_passport_number.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CUSTOMER_PASSPORT",
        "threshold": 0.9995,
    },
    "dynamo_customer_risk_form_recon": {
        "reconcile_sql_path": "13452_customer_risk_form.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CUSTOMER_RISKFORM",
        "threshold": 0.9995,
    },
    "dynamo_customer_identity_recon": {
        "reconcile_sql_path": "13453_customer_identity.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CUSTOMER_IDENTITY",
        "threshold": 0.9995,
    },
    "dynamo_cards_status_history_recon": {
        "reconcile_sql_path": "13454_cards_status_history.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CARDS_STATUS_HISTORY",
        "threshold": 0.9995,
    },
    "dynamo_customer_address_address_recon": {
        "reconcile_sql_path": "13455_customer_address_address.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CUSTOMER_ADDRESS_ADDRESS",
        "threshold": 0.9995,
    },
    "dynamo_payees_v2_recon": {
        "reconcile_sql_path": "13457_sls_payees_v2.sql",
        "dynamo_table_env_var_name": "DYNAMODB_PAYEES_V2",
        "threshold": 0.9995,
    },
    "dynamo_ias_recurring_recon": {
        "reconcile_sql_path": "13458_sls_ias_recurring.sql",
        "dynamo_table_env_var_name": "DYNAMODB_IAS_RECURRING",
        "threshold": 0.9995,
    },
    "dynamo_document_verification_recon": {
        "reconcile_sql_path": "13459_sls_document_verification.sql",
        "dynamo_table_env_var_name": "DYNAMODB_DOCUMENT_VERIFICATION",
        "threshold": 0.9995,
    },
    "dynamo_confirmation_of_payee_recon": {
        "reconcile_sql_path": "13460_sls_confirmation_of_payee.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CONFIRMATION_OF_PAYEE",
        "threshold": 0.9995,
    },
    "dynamo_customers_recon": {
        "reconcile_sql_path": "5710_total_onboarding_timeline.sql",
        "dynamo_table_env_var_name": "DYNAMODB_CUSTOMERS",
        "threshold": 0.9995,
    },
}
