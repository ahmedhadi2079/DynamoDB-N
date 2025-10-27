WITH latest AS
(
SELECT dynamodb_new_image_pk_s as athena_id,
ROW_NUMBER() OVER (PARTITION BY dynamodb_new_image_pk_s ORDER BY COALESCE(dynamodb_new_image_updated_at_n, now()) DESC, timestamp_extracted DESC, date DESC, dynamodb_new_image_pk_s ASC) as rn
FROM "datalake_raw"."dynamo_onfido"
)
SELECT athena_id
FROM latest
WHERE rn=1
