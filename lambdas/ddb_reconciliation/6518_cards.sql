SELECT dynamodb_keys_id_s AS athena_id,
    dynamodb_new_image_state_s AS athena_state
FROM (
        SELECT dynamodb_keys_id_s,
            dynamodb_new_image_state_s,
            ROW_NUMBER() OVER (
                PARTITION BY dynamodb_keys_id_s
                ORDER BY COALESCE(dynamodb_new_image_updated_at_n, now()) DESC,
                    timestamp_extracted DESC,
                    date DESC,
                    dynamodb_keys_id_s ASC
            ) AS rn
        FROM dynamo_sls_cards
    )
WHERE rn = 1
