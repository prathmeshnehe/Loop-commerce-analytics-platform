-- BUSINESS QUESTION:
-- Which markets are growing fastest by revenue?

WITH order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customers AS (
    SELECT
        customer_id,
        customer_unique_id,
        city,
        state
    FROM {{ ref('stg_customers') }}
),

order_revenue AS (
    SELECT
        order_id,
        SUM(total_item_revenue) AS order_revenue
    FROM order_items
    GROUP BY order_id
),

joined AS (
    SELECT
        c.state                             AS market,
        DATE_TRUNC('month', o.order_date)   AS month,
        COUNT(DISTINCT o.order_id)          AS total_orders,
        COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
        SUM(r.order_revenue)                AS total_revenue,
        ROUND(AVG(r.order_revenue), 2)      AS avg_order_value
    FROM orders o
    LEFT JOIN customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN order_revenue r
        ON o.order_id = r.order_id
    WHERE c.state IS NOT NULL
    GROUP BY c.state, DATE_TRUNC('month', o.order_date)
    ORDER BY month, total_revenue DESC
)

SELECT * FROM joined