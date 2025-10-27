WITH a AS (
    -- distincting columns
    SELECT date as lambda_date,
        dynamodb_keys_id_s,
        dynamodb_new_image_status_s,
        dynamodb_old_image_status_s,
        dynamodb_new_image_updated_at_n,
        dynamodb_new_image_type_s,
        timestamp_extracted
    FROM datalake_raw.dynamo_scv_sls_customers
    GROUP BY date,
        dynamodb_keys_id_s,
        dynamodb_new_image_status_s,
        dynamodb_old_image_status_s,
        dynamodb_new_image_updated_at_n,
        dynamodb_new_image_type_s,
        timestamp_extracted
),
b AS (
    -- finding the first value of dynamodb_new_image_updated_at_n per user_id and status to find when a customer moved into that status
    SELECT lambda_date,
        dynamodb_keys_id_s AS user,
        dynamodb_new_image_status_s AS onboarding_status_new,
        dynamodb_old_image_status_s AS onboarding_status_old,
        dynamodb_new_image_type_s AS type,
        dynamodb_new_image_updated_at_n AS last_update,
        FIRST_VALUE(dynamodb_new_image_updated_at_n) OVER (
            PARTITION BY dynamodb_keys_id_s,
            dynamodb_new_image_status_s
            ORDER BY dynamodb_new_image_updated_at_n ASC
        ) as onboarding_status_update_date,
        timestamp_extracted
    FROM a
),
c as (
    -- creating generalised onboarding statuses, also getting day,month,quarter,year from the onboarding status update date
    SELECT lambda_date,
        user,
        CASE
            WHEN onboarding_status_new IS NULL THEN 'UNKNOWN'
            WHEN onboarding_status_new = '' THEN 'UNKNOWN'
            ELSE onboarding_status_new
        END AS onboarding_status_new,
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
            WHEN type is NULL then 'UNKNOWN'
            WHEN type = '' then 'UNKNOWN'
            WHEN type = 'DEFAULT' then 'NORMAL'
            WHEN type = 'EXCLUSIVE' then 'VIP'
        END AS type,
        last_update,
        DAY(onboarding_status_update_date) AS day,
        MONTH(onboarding_status_update_date) AS month,
        QUARTER(onboarding_status_update_date) AS quarter,
        YEAR(onboarding_status_update_date) AS year,
        onboarding_status_update_date,
        timestamp_extracted
    FROM b
),
d as (
    -- generating the row number to find the first row the customer moved into status, also generating a date from day,month,year cols
    select user,
        onboarding_status_new,
        onboarding_group,
        onboarding_status_old,
        type,
        last_update,
        day,
        month,
        quarter,
        year,
        onboarding_status_update_date,
        ROW_NUMBER() OVER (
            PARTITION BY user,
            day,
            month,
            quarter,
            year
            ORDER BY last_update DESC,
                timestamp_extracted DESC,
                lambda_date DESC
        ) rn,
        date_parse(
            concat(
                cast(year as varchar(4)),
                lpad(cast(month as varchar(2)), 2, '0'),
                lpad(cast(day as varchar(2)), 2, '0')
            ),
            '%Y%m%d'
        ) as onboarding_status_date_
    from c
),
e as (
    -- filtering row number to get 1st row customer moved into status
    select user,
        onboarding_status_new,
        onboarding_group,
        onboarding_status_old,
        type,
        last_update,
        day,
        month,
        quarter,
        year,
        onboarding_status_update_date,
        onboarding_status_date_
    from d
    where rn = 1
),
dates as (
    -- for exploding rows to get historical daily statuses - DATES
    select dt
    FROM UNNEST(
            sequence(
                date '2021-04-01',
                current_date,
                INTERVAL '1' DAY
            )
        ) t(dt)
),
user_dates as (
    -- for exploding rows to get historical daily statuses - Users X dates
    select distinct dates.dt as onboarding_status_date_,
        d2.user
    from dates
        cross join (
            select distinct user
            from d
        ) d2
),
exploded_records as (
    -- exploding the records
    select user_dates.user,
        user_dates.onboarding_status_date_,
        e.onboarding_status_new
    from e
        right join user_dates on e.onboarding_status_date_ = user_dates.onboarding_status_date_
        and e.user = user_dates.user
    order by onboarding_status_date_ desc
)
select user,
    onboarding_status_date_,
    COALESCE (
        onboarding_status_new,
        LAST_VALUE(onboarding_status_new) IGNORE NULLS OVER (
            PARTITION BY user
            ORDER BY onboarding_status_date_ ASC
        )
    ) as status_
from exploded_records
WHERE user not in (
        SELECT dynamodb_keys_id_s
        FROM -- exclude deleted users, (users are deleted in dynamo) which cause reconciliation to give incorrect counts
            (
                SELECT dynamodb_keys_id_s,
                    dynamodb_new_image_status_s,
                    dynamodb_old_image_status_s,
                    dynamodb_new_image_id_s,
                    ROW_NUMBER() OVER (
                        PARTITION BY dynamodb_keys_id_s
                        ORDER BY COALESCE(dynamodb_new_image_updated_at_n, now()) DESC,
                            timestamp_extracted DESC,
                            date DESC,
                            dynamodb_new_image_id_s ASC
                    ) as rn,
                    date,
                    FIRST_VALUE(date) OVER (
                        PARTITION BY dynamodb_keys_id_s
                        ORDER BY date DESC
                    ) as last_date,
                    date(dynamodb_new_image_created_at_n) as created_at_date
                FROM datalake_raw.dynamo_scv_sls_customers
            )
        WHERE rn = 1
            and (
                (
                    dynamodb_new_image_id_s = ''
                    AND dynamodb_new_image_status_s = ''
                )
                OR (
                    dynamodb_new_image_id_s IS NULL
                    AND dynamodb_new_image_status_s IS NULL
                )
                OR (
                    dynamodb_new_image_status_s IS NULL
                    and dynamodb_new_image_id_s = ''
                )
            )
            and last_date <= date
        UNION
        -- exclude users who were created today, as a user can be created in dynamodb and not make it to datalake in time before reconciliation is ran
        select dynamodb_keys_id_s
        from datalake_raw.dynamo_scv_sls_customers
        where date(dynamodb_new_image_created_at_n) = date(now())
    )
