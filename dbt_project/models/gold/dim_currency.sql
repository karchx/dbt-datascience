{{ config(schema='gold', alias='dim_currency', materialized='table', pre_hook = ["CREATE TABLE IF NOT EXISTS gold.dim_currency(
    currency_sk BIGINT autoincrement start 1 increment 1,
    currency_bk CHAR(40),
    currency varchar(20),
    effective_date DATETIME,
    end_date DATETIME
)"] ) }}

WITH source_data as (
     SELECT DISTINCT
            price_currency as currency,
            sha1(lower(price_currency)) as currency_bk,
            current_timestamp() AS effective_date,
            NULL AS end_date
     FROM {{ source('silver', 'ticket_sales') }}
     WHERE price_currency IS NOT NULL
)
SELECT * FROM source_data
