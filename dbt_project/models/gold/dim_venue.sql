{{ config(schema='gold', alias='dim_venue', materialized='table', pre_hook = ["CREATE TABLE IF NOT EXISTS gold.dim_venue(
    venue_sk BIGINT autoincrement start 1 increment 1,
    venue_bk CHAR(40),
    venue_name varchar(200),
    venue_latitude float,
    venue_longitude float,
    venue_address varchar(250),
    venue_capacity number,
    event_schedule number,
    effective_date DATETIME,
    end_date DATETIME
)"] ) }}

WITH source_data as (
     SELECT DISTINCT
            venue_name,
            sha1(concat(lower(venue_name), ';', nvl(venue_capacity, 0), ';', event_schedule)) as venue_bk,
            venue_latitude,
            venue_longitude,
            venue_address,
            venue_capacity,
            event_schedule,
            current_timestamp() AS effective_date,
            NULL AS end_date
     FROM {{ source('silver', 'venue_details') }}
)
SELECT * FROM source_data
