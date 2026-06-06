-- BUSINESS QUESTION:
-- How does each market (state) perform on
-- revenue, orders, and average order value?
-- Mirrors Loop's global expansion challenge.

WITH orders AS (
    SELECT * FROM {{ ref('int_customer_order_history') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

joined AS (
    SELECT
        c.state                             AS market,
        DATE_TRUNC('month', o.order_date)   AS month,
        COUNT(DISTINCT o.order_id)          AS total_orders,
        COUNT(DISTINCT o.customer_id)       AS unique_customers,
        SUM(o.order_revenue)                AS total_revenue,
        ROUND(AVG(o.order_revenue), 2)      AS avg_order_value
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.state, DATE_TRUNC('month', o.order_date)
    ORDER BY month, total_revenue DESC
)

SELECT * FROM joined