WITH filtered_source AS (
    SELECT
        *
    FROM
        datalake_raw.dynamo_scv_sls_customers
    WHERE
        date BETWEEN DATE '2021-04-01'
        AND current_date -- Excluding users created today
        AND date(dynamodb_new_image_created_at_n) < current_date -- Excluding deleted users
        AND NOT (
            (
                dynamodb_new_image_id_s = ''
                AND dynamodb_new_image_status_s = ''
            )
            OR (
                dynamodb_new_image_id_s IS NULL
                AND dynamodb_new_image_status_s IS NULL
            )
        )
),
a AS (
    SELECT
        date AS lambda_date,
        dynamodb_keys_id_s AS user,
        dynamodb_new_image_status_s AS onboarding_status_new,
        dynamodb_old_image_status_s AS onboarding_status_old,
        dynamodb_new_image_updated_at_n AS last_update,
        dynamodb_new_image_type_s AS type,
        timestamp_extracted
    FROM
        filtered_source
    GROUP BY
        date,
        dynamodb_keys_id_s,
        dynamodb_new_image_status_s,
        dynamodb_old_image_status_s,
        dynamodb_new_image_updated_at_n,
        dynamodb_new_image_type_s,
        timestamp_extracted
),
b AS (
    SELECT
        lambda_date,
        user,
        onboarding_status_new,
        onboarding_status_old,
        type,
        last_update,
        FIRST_VALUE(last_update) OVER (
            PARTITION BY user,
            onboarding_status_new
            ORDER BY
                last_update ASC
        ) AS onboarding_status_update_date,
        timestamp_extracted
    FROM
        a
),
c AS (
    SELECT
        lambda_date,
        user,
        COALESCE(NULLIF(onboarding_status_new, ''), 'UNKNOWN') AS onboarding_status_new,
        CASE
            WHEN onboarding_status_new IN (
                'AWAITING_APPROVAL',
                'AWAITING_BANK_ACCOUNT_CREATION',
                'AWAITING_MANUAL_REVIEW',
                'AWAITING_SUBMISSION'
            ) THEN 'Started Onboarding'
            WHEN onboarding_status_new = 'APPROVED' THEN 'Completed Onboarding'
            WHEN onboarding_status_new = 'CEASED' THEN 'Ceased'
            WHEN onboarding_status_new = 'REJECTED' THEN 'Rejected'
            ELSE 'Unknown'
        END AS onboarding_group,
        onboarding_status_old,
        CASE
            WHEN type IS NULL
            OR type = '' THEN 'UNKNOWN'
            WHEN type = 'DEFAULT' THEN 'NORMAL'
            WHEN type = 'EXCLUSIVE' THEN 'VIP'
        END AS type,
        last_update,
        DAY(onboarding_status_update_date) AS day,
        MONTH(onboarding_status_update_date) AS month,
        QUARTER(onboarding_status_update_date) AS quarter,
        YEAR(onboarding_status_update_date) AS year,
        onboarding_status_update_date,
        timestamp_extracted
    FROM
        b
),
d AS (
    SELECT
        user,
        onboarding_status_new,
        onboarding_group,
        onboarding_status_old,
        type,
        last_update,
        onboarding_status_update_date,
        ROW_NUMBER() OVER (
            PARTITION BY user,
            year,
            month,
            day
            ORDER BY
                last_update DESC,
                timestamp_extracted DESC,
                lambda_date DESC
        ) AS rn,
        date_parse(
            concat(
                cast(year AS varchar),
                lpad(cast(month AS varchar), 2, '0'),
                lpad(cast(day AS varchar), 2, '0')
            ),
            '%Y%m%d'
        ) AS onboarding_status_date_
    FROM
        c
),
e AS (
    SELECT
        user,
        onboarding_status_new,
        onboarding_status_update_date,
        onboarding_status_date_
    FROM
        d
    WHERE
        rn = 1
),
transitions AS (
    SELECT
        user,
        onboarding_status_update_date AS dt,
        onboarding_status_new
    FROM
        e
),
user_bounds AS (
    SELECT
        user,
        MIN(dt) AS start_dt,
        MAX(dt) AS end_dt
    FROM
        transitions
    GROUP BY
        user
),
user_dates AS (
    SELECT
        ub.user,
        dt
    FROM
        user_bounds ub
        CROSS JOIN UNNEST(
            sequence(ub.start_dt, ub.end_dt, INTERVAL '1' DAY)
        ) AS t(dt)
),
exploded_records AS (
    SELECT
        ud.user,
        ud.dt AS onboarding_status_date_,
        tr.onboarding_status_new
    FROM
        user_dates ud
        LEFT JOIN transitions tr ON tr.user = ud.user
        AND tr.dt = ud.dt
)
SELECT
    user,
    onboarding_status_date_,
    COALESCE(
        onboarding_status_new,
        LAST_VALUE(onboarding_status_new) IGNORE NULLS OVER (
            PARTITION BY user
            ORDER BY
                onboarding_status_date_
        )
    ) AS status_
FROM
    exploded_records
ORDER BY
    user,
    onboarding_status_date_;