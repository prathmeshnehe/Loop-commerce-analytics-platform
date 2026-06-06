-- BUSINESS QUESTION:
-- Of customers who first bought in month X,
-- how many came back in subsequent months?
-- This is the gold standard retention metric.

WITH customer_orders AS (
    SELECT * FROM {{ ref('int_customer_order_history') }}
),

first_orders AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date) AS cohort_month
    FROM customer_orders
    WHERE order_number = 1
    -- WHY order_number = 1: Only grab each customer's
    -- very first purchase to define their cohort
),

all_orders AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date) AS order_month
    FROM customer_orders
),

cohort_data AS (
    SELECT
        f.cohort_month,
        a.order_month,
        DATEDIFF('month', f.cohort_month, a.order_month)
            AS months_since_first_purchase,
        COUNT(DISTINCT a.customer_id) AS active_customers
    FROM first_orders f
    LEFT JOIN all_orders a ON f.customer_id = a.customer_id
    GROUP BY f.cohort_month, a.order_month,
             months_since_first_purchase
)

SELECT
    cohort_month,
    months_since_first_purchase,
    active_customers
FROM cohort_data
WHERE months_since_first_purchase >= 0
ORDER BY cohort_month, months_since_first_purchase