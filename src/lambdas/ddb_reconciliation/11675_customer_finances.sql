WITH latest AS
(
SELECT dynamodb_keys_user_id_s as athena_user_id,
ROW_NUMBER() OVER (PARTITION BY dynamodb_keys_user_id_s ORDER BY timestamp_extracted DESC, date DESC, dynamodb_keys_user_id_s ASC) as rn
FROM "datalake_raw"."dynamo_sls_customer_finances"
)
SELECT athena_user_id
FROM latest
WHERE rn=1
