-- Cleans raw orders data
-- Parses date columns correctly
-- Filters out invalid orders

WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_ORDERS') }}
),

cleaned AS (
    SELECT
        ORDER_ID,
        CUSTOMER_ID,
        ORDER_STATUS                            AS status,
        TO_DATE(ORDER_PURCHASE_TIMESTAMP)       AS order_date,
        TO_DATE(ORDER_DELIVERED_CUSTOMER_DATE)  AS delivered_date,
        TO_DATE(ORDER_ESTIMATED_DELIVERY_DATE)  AS estimated_delivery_date
    FROM source
    WHERE ORDER_STATUS != 'canceled'
)
-- WHY we filter canceled: canceled orders skew
-- retention and revenue metrics. We only want
-- real completed customer journeys.

SELECT * FROM cleaned