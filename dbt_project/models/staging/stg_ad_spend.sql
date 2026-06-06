WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_AD_SPEND') }}
),

cleaned AS (
    SELECT
        TO_DATE(DATE)       AS spend_date,
        CHANNEL,
        MARKET,
        SPEND_AMOUNT,
        IMPRESSIONS,
        CLICKS,
        ROUND(SPEND_AMOUNT / NULLIF(CLICKS, 0), 2) AS cost_per_click
    FROM source
)
-- WHY NULLIF(CLICKS, 0): prevents division by zero error
-- if a campaign had zero clicks that day.
-- NULLIF returns NULL instead of crashing the query.

SELECT * FROM cleaned