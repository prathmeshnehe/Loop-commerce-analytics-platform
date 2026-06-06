-- Combines ad spend with order data by date
-- to calculate daily return on ad spend (ROAS)

WITH ad_spend AS (
    SELECT * FROM {{ ref('stg_ad_spend') }}
),

daily_orders AS (
    SELECT
        order_date,
        COUNT(DISTINCT order_id)    AS total_orders,
        SUM(order_revenue)          AS total_revenue
    FROM {{ ref('int_customer_order_history') }}
    GROUP BY order_date
),

joined AS (
    SELECT
        a.spend_date,
        a.channel,
        a.market,
        a.spend_amount,
        a.impressions,
        a.clicks,
        a.cost_per_click,
        d.total_orders,
        d.total_revenue,
        ROUND(d.total_revenue / NULLIF(a.spend_amount, 0), 2) AS roas
    FROM ad_spend a
    LEFT JOIN daily_orders d ON a.spend_date = d.order_date
)
-- WHY LEFT JOIN: Not every day with ad spend will have
-- orders. LEFT JOIN keeps all ad spend rows even when
-- there are no matching orders that day.

SELECT * FROM joined