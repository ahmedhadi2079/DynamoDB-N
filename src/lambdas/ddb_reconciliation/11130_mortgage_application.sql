WITH latest AS
(
SELECT dynamodb_keys_id_s as athena_id,
ROW_NUMBER() OVER (PARTITION BY dynamodb_keys_id_s ORDER BY COALESCE(dynamodb_new_image_updated_at_n, now()) DESC, timestamp_extracted DESC, date DESC, dynamodb_keys_id_s ASC) as rn
FROM "datalake_raw"."dynamo_sls_home_financing_mortgage_application"
)
SELECT athena_id
FROM latest
WHERE rn=1
