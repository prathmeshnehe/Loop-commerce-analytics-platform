-- BUSINESS QUESTION:
-- What % of real unique customers come back to buy again?
-- Uses customer_unique_id to correctly identify repeat buyers
-- across Olist's order-scoped customer_id system.

WITH customer_orders AS (
    SELECT * FROM {{ ref('int_customer_order_history') }}
),

customers AS (
    SELECT
        customer_unique_id,
        city,
        state
    FROM {{ ref('stg_customers') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY customer_id
    ) = 1
    -- WHY QUALIFY: Since customer_unique_id appears
    -- multiple times (one per order), we take just
    -- one row per real person for the join
),

customer_summary AS (
    SELECT
        customer_id  AS customer_unique_id,
        COUNT(DISTINCT order_id)    AS total_orders,
        MIN(order_date)             AS first_order_date,
        MAX(order_date)             AS last_order_date,
        SUM(order_revenue)          AS lifetime_value,
        CASE
            WHEN COUNT(DISTINCT order_id) > 1
            THEN 1 ELSE 0
        END AS is_repeat_customer
    FROM customer_orders
    GROUP BY customer_id
),

final AS (
    SELECT
        c.state,
        COUNT(DISTINCT cs.customer_unique_id)       AS total_customers,
        SUM(cs.is_repeat_customer)                  AS repeat_customers,
        ROUND(
            SUM(cs.is_repeat_customer)
            / NULLIF(COUNT(DISTINCT cs.customer_unique_id), 0)
            * 100, 2
        )                                           AS repeat_rate_pct,
        ROUND(AVG(cs.lifetime_value), 2)            AS avg_lifetime_value
    FROM customer_summary cs
    LEFT JOIN customers c
        ON cs.customer_unique_id = c.customer_unique_id
    GROUP BY c.state
    ORDER BY repeat_rate_pct DESC
)

SELECT * FROM final