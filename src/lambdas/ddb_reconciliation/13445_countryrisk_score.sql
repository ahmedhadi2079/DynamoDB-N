with
pre_final as
(
SELECT dynamodb_new_image_customer_id_s AS athena_id
     , ROW_NUMBER() OVER (
                PARTITION BY dynamodb_new_image_customer_id_s
                ORDER BY COALESCE(dynamodb_new_image_updated_at_n, now()) DESC,
                    timestamp_extracted DESC,
                    date DESC,
                    dynamodb_new_image_customer_id_s ASC
            ) AS rn
  FROM "datalake_raw"."dynamo_sls_customer_risk_country_score"
)
SELECT athena_id
  FROM pre_final
 WHERE rn = 1
