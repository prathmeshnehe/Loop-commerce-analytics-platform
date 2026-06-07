WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_CUSTOMERS') }}
),

cleaned AS (
    SELECT
        CUSTOMER_ID,
        CUSTOMER_UNIQUE_ID,
        CUSTOMER_ZIP_CODE_PREFIX AS zip_code,
        CUSTOMER_CITY AS city,
        CUSTOMER_STATE AS state_code,
        CASE CUSTOMER_STATE
            WHEN 'AC' THEN 'Acre'
            WHEN 'AL' THEN 'Alagoas'
            WHEN 'AP' THEN 'Amapá'
            WHEN 'AM' THEN 'Amazonas'
            WHEN 'BA' THEN 'Bahia'
            WHEN 'CE' THEN 'Ceará'
            WHEN 'DF' THEN 'Distrito Federal'
            WHEN 'ES' THEN 'Espírito Santo'
            WHEN 'GO' THEN 'Goiás'
            WHEN 'MA' THEN 'Maranhão'
            WHEN 'MT' THEN 'Mato Grosso'
            WHEN 'MS' THEN 'Mato Grosso do Sul'
            WHEN 'MG' THEN 'Minas Gerais'
            WHEN 'PA' THEN 'Pará'
            WHEN 'PB' THEN 'Paraíba'
            WHEN 'PR' THEN 'Paraná'
            WHEN 'PE' THEN 'Pernambuco'
            WHEN 'PI' THEN 'Piauí'
            WHEN 'RJ' THEN 'Rio de Janeiro'
            WHEN 'RN' THEN 'Rio Grande do Norte'
            WHEN 'RS' THEN 'Rio Grande do Sul'
            WHEN 'RO' THEN 'Rondônia'
            WHEN 'RR' THEN 'Roraima'
            WHEN 'SC' THEN 'Santa Catarina'
            WHEN 'SP' THEN 'São Paulo'
            WHEN 'SE' THEN 'Sergipe'
            WHEN 'TO' THEN 'Tocantins'
            ELSE CUSTOMER_STATE
        END AS state
    FROM source
)

SELECT * FROM cleaned
