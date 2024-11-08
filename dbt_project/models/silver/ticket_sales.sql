{{
    config(
        materialized='table',
        schema='silver'
    )
}}

WITH source_data AS (
    SELECT 
        raw_data,
        loaded_at,
        filename,
        index as array_index
    FROM {{ source('bronze', 'ticketmaster_raw') }}
)

SELECT
    -- Ticket Sales
    value:ticket_sales:price_range:min::FLOAT as min_price,
    value:ticket_sales:price_range:max::FLOAT as max_price,
    value:ticket_sales:price_range:currency::STRING as price_currency,
    value:ticket_sales:sale_dates::TIMESTAMP as sale_start_date,
    value:ticket_sales:available_quantities::STRING as ticket_limit,
    -- Metadata
    loaded_at,
    filename as source_file,
    array_index
FROM source_data,
LATERAL FLATTEN(input => raw_data)