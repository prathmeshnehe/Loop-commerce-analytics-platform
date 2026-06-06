-- Cleans raw customer data
-- Renames columns to readable names
-- Casts data types correctly

WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_CUSTOMERS') }}
),

cleaned AS (
    SELECT
        CUSTOMER_ID,
        CUSTOMER_UNIQUE_ID,
        CUSTOMER_ZIP_CODE_PREFIX    AS zip_code,
        CUSTOMER_CITY               AS city,
        CUSTOMER_STATE              AS state
    FROM source
)

SELECT * FROM cleaned