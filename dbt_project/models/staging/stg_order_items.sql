WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_ORDER_ITEMS') }}
),

cleaned AS (
    SELECT
        ORDER_ID,
        ORDER_ITEM_ID           AS item_sequence,
        PRODUCT_ID,
        SELLER_ID,
        PRICE                   AS item_price,
        FREIGHT_VALUE           AS shipping_cost,
        PRICE + FREIGHT_VALUE   AS total_item_revenue
    FROM source
)
-- WHY we add total_item_revenue: downstream models
-- need total revenue per item. Computing it here
-- once avoids repeating the logic everywhere.

SELECT * FROM cleaned