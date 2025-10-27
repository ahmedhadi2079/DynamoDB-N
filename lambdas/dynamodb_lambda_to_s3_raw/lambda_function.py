from utils import (
    parse_payload,
    apply_schema,
    write_processed_to_s3,
    log_function,
    log_event,
)

from data_catalog import schemas


# Dynamo to Athena table mapping
TABLE_MAPPING = {
    "datalake-ddb-integration-stream-notifications-referral": "dynamo_sls_referral",
    "datalake-ddb-integration-stream-notifications-referral-code": "dynamo_sls_referral_code",
    "datalake-ddb-integration-stream-customer-credentials-change-history": "dynamo_sls_ddb_customer_credentials_change_history",
    "datalake-ddb-integration-stream-customer-verification-attempt": "dynamo_sls_ddb_customer_verification_attempt",
    "datalake-ddb-integration-stream-customer-block-list": "dynamo_sls_ddb_customer_block_list",
    "datalake-ddb-integration-stream-risk-score": "dynamo_sls_riskscore",
    "datalake-ddb-integration-stream-risk-crm-case": "dynamo_sls_risk_crm_case",
    "datalake-ddb-integration-stream-payments-payment-products": "dynamo_default_payment_products",
    "datalake-ddb-integration-stream-mortgage-in-principle": "dynamo_sls_home_financing_mortgage_in_principle",
    "datalake-ddb-integration-stream-investments-user": "dynamo_default_investment_user",
    "datalake-ddb-integration-stream-investments-sell": "dynamo_default_investment_sell",
    "datalake-ddb-integration-stream-investments-fund": "dynamo_default_investment_fund",
    "datalake-ddb-integration-stream-sls-financing-mortgage": "dynamo_sls_home_financing_mortgage",
    "datalake-ddb-integration-stream-exchange-rates": "dynamo_sls_exchange_rates",
    "datalake-ddb-integration-stream-customer-risk-us-person": "dynamo_sls_customer_risk_us_person",
    "datalake-ddb-integration-stream-customer-passport": "dynamo_sls_ddb_users_customer_passport_number",
    "datalake-ddb-integration-stream-customers": "dynamo_scv_sls_customers",
    "datalake-ddb-integration-stream-customer-identity": "dynamo_sls_customer_identity",
    "datalake-ddb-integration-stream-reset-code-challenges": "dynamo_sls_passcoderesetcodechallenges",
    "datalake-ddb-integration-stream-customer-address-verification": "dynamo_sls_ddb_customer_address_verification_code",
    "datalake-ddb-integration-stream-sls-ddb-payees-payees-v2": "dynamo_sls_payees_v2",
    "datalake-ddb-integration-stream-cards-status-history-identity": "dynamo_sls_cards_status_history",
    "datalake-ddb-integration-stream-document-verification": "dynamo_sls_document_verification",
    "datalake-ddb-integration-stream-sls-ddb-ias-recurring": "dynamo_sls_ias_recurring",
    "datalake-ddb-integration-stream-customer-risk-country-score": "dynamo_sls_customer_risk_country_score",
    "datalake-ddb-integration-stream-customer-address-address": "dynamo_sls_customer_address_address",
    "datalake-ddb-integration-stream-customer-finances": "dynamo_sls_customer_finances",
    "datalake-ddb-integration-stream-cards-orders": "dynamo_sls_cardorders",
    "datalake-ddb-integration-stream-onfido": "dynamo_onfido",
    "datalake-ddb-integration-stream-customer-risk-form": "dynamo_sls_customer_risk_form",
    "datalake-ddb-integration-stream-reset-tiers-history": "dynamo_sls_passcoderesettiershistory",
    "datalake-ddb-integration-stream-cards": "dynamo_sls_cards",
    "datalake-ddb-integration-stream-clearbank-transactions": "dynamo_sls_clearbank_transactions",
    "datalake-ddb-integration-stream-confirmation-of-payee": "dynamo_sls_confirmation_of_payee",
    "datalake-ddb-integration-stream-mortgage-application": "dynamo_sls_home_financing_mortgage_application",
    "datalake-ddb-integration-stream-cards-fast-messages": "dynamo_card_fast_messages_default",
    "datalake-ddb-integration-stream-risk-score-history": "dynamo_sls_riskscore_history",
    "datalake-ddb-integration-stream-sls-cards-rules": "dynamo_sls_cards_rules",
    "datalake-ddb-integration-stream-sls-cards-disabled-rules-history": "dynamo_sls_cards_disabled_rules_history",
    "datalake-ddb-integration-stream-sls-investments-model-portfolio": "dynamo_sls_investments_model_portfolio",
    "datalake-ddb-integration-stream-sls-investments-model-portfolio-rebalance": "dynamo_sls_investments_model_portfolio_rebalance",
    "datalake-ddb-integration-stream-sls-investments-instrument": "dynamo_sls_investments_instrument",
    "datalake-ddb-integration-stream-sls-investments-dividend": "dynamo_sls_investments_dividend",
    "datalake-ddb-integration-stream-sls-investments-daily-fees": "dynamo_sls_investments_daily_fees",
    "datalake-ddb-integration-stream-sls-investments-monthly-fees": "dynamo_sls_investments_monthly_fees",
    "datalake-ddb-integration-stream-sls-investments-order": "dynamo_sls_investments_order",
    "datalake-ddb-integration-stream-sls-instant-savings-accounts-products": "dynamo_sls_instant_savings_accounts_products",
}


@log_function
def lambda_handler(event, context):
    """
    Accepts a Kinesis Data Stream Event
    :param event: The event dict that contains the parameters sent when the function
                  is invoked.
    :param context: The context in which the function is called.
    :return: The result of the specified action.
    """
    try:
        event_id = event["Records"][0]["eventID"]
        log_event("info", "event_id", f"Processing event with ID: {event_id}")

        source_table_name = event["Records"][0]["eventSourceARN"].split("/")[1]
        log_event(
            "info", "source_table_name", f"Source DynamoDB table: {source_table_name}"
        )

        athena_table_name = TABLE_MAPPING.get(source_table_name)

        df = parse_payload(event)

        if not athena_table_name:
            log_event(
                "error",
                "missing_mapping",
                f"No Athena table mapping found for DynamoDB table: {source_table_name}",
            )
            return False

        log_event(
            "info", "target_table_mapping", f"Target Athena table: {athena_table_name}"
        )

        try:
            final_df = apply_schema(df, schemas[athena_table_name])
        except Exception as e:
            log_event("error", "apply_schema_error", f"Schema applying failed: {e}")
            raise ValueError(f"Schema mismatch for {athena_table_name}") from e

        write_processed_to_s3(final_df, athena_table_name)

        return True

    except Exception as e:
        log_event("error", "lambda_handler_exception", f"Unhandled exception: {e}")
        raise
