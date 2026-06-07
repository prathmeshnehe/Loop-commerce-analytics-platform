-- BUSINESS QUESTION:
-- Which ad channel brings the most valuable customers?
-- (Revenue per customer per channel)

WITH ad_spend AS (
    SELECT * FROM {{ ref('stg_ad_spend') }}
),

daily_perf AS (
    SELECT * FROM {{ ref('int_channel_daily_performance') }}
),

channel_summary AS (
    SELECT
        channel,
        market,
        SUM(spend_amount)                               AS total_spend,
        SUM(total_orders)                               AS total_orders,
        SUM(total_revenue)                              AS total_revenue,
        ROUND(SUM(total_revenue) /
            NULLIF(SUM(spend_amount), 0), 2)            AS overall_roas,
        ROUND(SUM(spend_amount) /
            NULLIF(SUM(total_orders), 0), 2)            AS cost_per_order
    FROM daily_perf
    GROUP BY channel, market
    ORDER BY overall_roas DESC
)

SELECT * FROM channel_summary