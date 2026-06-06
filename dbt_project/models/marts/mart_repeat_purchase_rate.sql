-- BUSINESS QUESTION:
-- What % of customers come back to buy again?
-- Broken down by state/city (proxy for market)
-- This directly mirrors Loop's retention problem

WITH customer_orders AS (
    SELECT * FROM {{ ref('int_customer_order_history') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

customer_summary AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)    AS total_orders,
        MIN(order_date)             AS first_order_date,
        MAX(order_date)             AS last_order_date,
        SUM(order_revenue)          AS lifetime_value,
        CASE
            WHEN COUNT(DISTINCT order_id) > 1
            THEN 'repeat'
            ELSE 'one_time'
        END AS customer_type
    FROM customer_orders
    GROUP BY customer_id
),

final AS (
    SELECT
        c.state,
        COUNT(DISTINCT cs.customer_id)                          AS total_customers,
        SUM(CASE WHEN cs.customer_type = 'repeat' THEN 1 END)  AS repeat_customers,
        ROUND(
            COALESCE(SUM(CASE WHEN cs.customer_type = 'repeat' THEN 1 END), 0)
            / COUNT(DISTINCT cs.customer_id) * 100, 2
            )                                                   AS repeat_rate_pct,
        ROUND(AVG(cs.lifetime_value), 2)                        AS avg_lifetime_value
    FROM customer_summary cs
    LEFT JOIN customers c ON cs.customer_id = c.customer_id
    GROUP BY c.state
    ORDER BY repeat_rate_pct DESC
)

SELECT * FROM final