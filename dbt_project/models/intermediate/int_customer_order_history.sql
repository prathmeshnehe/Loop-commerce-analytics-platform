-- Builds a complete picture of every customer's
-- order history. One row per customer.
-- This is the foundation for retention analysis.

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

order_revenue AS (
    SELECT
        order_id,
        SUM(total_item_revenue) AS order_revenue
    FROM order_items
    GROUP BY order_id
),

customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        o.status,
        r.order_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS order_number
    FROM orders o
    LEFT JOIN order_revenue r ON o.order_id = r.order_id
)
-- WHY ROW_NUMBER(): This numbers each customer's orders
-- chronologically. Order #1 = first purchase,
-- Order #2 = second purchase, etc.
-- This is how we identify repeat buyers vs one-time buyers.

SELECT * FROM customer_orders