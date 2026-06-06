WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_ORDER_PAYMENTS') }}
),

cleaned AS (
    SELECT
        ORDER_ID,
        PAYMENT_TYPE,
        PAYMENT_INSTALLMENTS    AS installments,
        PAYMENT_VALUE           AS payment_amount
    FROM source
)

SELECT * FROM cleaned