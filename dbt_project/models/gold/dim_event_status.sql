{{ config(schema='gold', alias='dim_event_status', materialized='table', pre_hook = ["CREATE TABLE IF NOT EXISTS gold.dim_event_status(
    event_sk BIGINT autoincrement start 1 increment 1,
    event_bk CHAR(40),
    event_status varchar(100),
    effective_date DATETIME,
    end_date DATETIME
)"] ) }}

WITH source_data as (
     SELECT DISTINCT
            event_status,
            sha1(lower(event_status)) as event_bk,
            current_timestamp() AS effective_date,
            NULL AS end_date
     FROM {{ source('silver', 'event_information') }}
)
SELECT * FROM source_data
