-- IMPORTANT FIX:
-- In Olist, customer_id is unique PER ORDER not per person.
-- customer_unique_id is the real person's identifier.
-- Without this fix, every customer looks like a first-time buyer
-- and repeat purchase rate shows 0% — which is wrong.

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customers AS (
    SELECT
        customer_id,
        customer_unique_id
    FROM {{ ref('stg_customers') }}
),

orders_with_real_customer AS (
    SELECT
        o.order_id,
        o.customer_id,
        c.customer_unique_id,  -- the REAL person identifier
        o.order_date,
        o.status,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_date
        ) AS order_number
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.customer_id
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

final AS (
    SELECT
        o.customer_unique_id AS customer_id,
        o.order_id,
        o.order_date,
        o.status,
        o.order_number,
        COALESCE(r.order_revenue, 0) AS order_revenue
    FROM orders_with_real_customer o
    LEFT JOIN order_revenue r ON o.order_id = r.order_id
)

SELECT * FROM final