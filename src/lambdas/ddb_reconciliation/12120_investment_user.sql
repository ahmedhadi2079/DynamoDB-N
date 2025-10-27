WITH latest AS
(
SELECT dynamodb_keys_id_s as athena_user_id,
ROW_NUMBER() OVER (PARTITION BY dynamodb_keys_id_s ORDER BY COALESCE(dynamodb_new_image_updated_at_n, now()) DESC, timestamp_extracted DESC, date DESC, dynamodb_keys_id_s ASC) as rn
FROM "datalake_raw"."dynamo_default_investment_user"
)
SELECT athena_user_id
FROM latest
WHERE rn=1
