WITH ad_spend AS (
    SELECT * FROM {{ ref('stg_ad_spend') }}
),

channel_summary AS (
    SELECT
        spend_date,
        channel,
        market,
        spend_amount                                AS total_spend,
        impressions                                 AS total_impressions,
        clicks                                      AS total_clicks,
        cost_per_click,
        -- Simulated revenue based on realistic ROAS by channel
        -- Organic: highest ROAS (no spend, high intent)
        -- Email: second highest (warm audience)
        -- Referral: third (trusted source)
        -- Paid Social: fourth (broad audience)
        -- TikTok: lowest (awareness focused)
        ROUND(
            CASE channel
                WHEN 'organic'      THEN spend_amount * 4.2
                WHEN 'email'        THEN spend_amount * 3.8
                WHEN 'referral'     THEN spend_amount * 3.1
                WHEN 'paid_social'  THEN spend_amount * 2.4
                WHEN 'tiktok'       THEN spend_amount * 1.8
                ELSE spend_amount * 2.0
            END, 2
        )                                           AS total_revenue,
        0                                           AS total_orders
    FROM ad_spend
)

SELECT * FROM channel_summary