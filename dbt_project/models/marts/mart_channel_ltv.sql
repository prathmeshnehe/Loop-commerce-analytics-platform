WITH daily_perf AS (
    SELECT * FROM {{ ref('int_channel_daily_performance') }}
),

channel_summary AS (
    SELECT
        channel,
        market,
        SUM(total_spend)            AS total_spend,
        SUM(total_clicks)           AS total_clicks,
        SUM(total_impressions)      AS total_impressions,
        SUM(total_revenue)          AS total_revenue,
        ROUND(
            SUM(total_revenue) /
            NULLIF(SUM(total_spend), 0), 2
        )                           AS overall_roas,
        ROUND(
            SUM(total_spend) /
            NULLIF(SUM(total_clicks), 0), 2
        )                           AS cost_per_order
    FROM daily_perf
    GROUP BY channel, market
    ORDER BY overall_roas DESC
)

SELECT * FROM channel_summary