{{ config(schema='gold', alias='fact_event_details', materialized='table', pre_hook = ["CREATE TABLE IF NOT EXISTS gold.fact_event_detail(
    dim_currency string,
    dim_event_genre string,
    dim_event_status string,
    dim_event_type string,
    dim_performer1 string,
    dim_performer2 string,
    dim_venue string,
    dim_event_date date,
    dim_sale_start_date date,
    dim_date_event_pull date,
    load_date date,
    event_schedule number,
    venue_capacity number,
    event_name string,
    min_price float,
    max_price float,
    ticket_limit string
)"] ) }}

WITH source_data as (
    SELECT
        sha1(lower(ts.price_currency)) as dim_currency,
        sha1(concat(lower(ei.event_genre), ';', lower(ei.event_subgenre))) as dim_event_genre,
        sha1(lower(ei.event_status)) as dim_event_status,
        sha1(lower(ei.event_type)) as dim_event_type,
        sha1(concat(lower(nvl(apd.team1_name, '')), ';',
          nvl(apd.team1_popularity, 0), ';', nvl(apd.team1_participation_history, 0))) as dim_performer1,
        sha1(concat(lower(nvl(apd.team2_name, '')), ';',
          nvl(apd.team2_popularity, 0), ';', nvl(apd.team2_participation_history, 0))) as dim_performer2,
        sha1(concat(lower(vd.venue_name), ';', nvl(vd.venue_capacity, 0), ';', vd.event_schedule)) as dim_venue,
        ei.event_date as dim_event_date,
        to_date(ts.sale_start_date) as dim_sale_start_date,
        ts.date_event_pull as dim_date_event_pull,
        current_date as load_date,
        vd.event_schedule as event_schedule,
        nvl(vd.venue_capacity, 0) as venue_capacity,
        ei.event_name as event_name,
        ts.min_price as min_price,
        ts.max_price as max_price,
        ts.ticket_limit as ticket_limit
    FROM silver.ticket_sales as ts
    JOIN silver.event_information as ei on (ei.id_event = ts.id_event and ei.date_event_pull = ts.date_event_pull)
    JOIN silver.artist_performer_details as apd on (apd.id_event = ts.id_event and apd.date_event_pull = ts.date_event_pull)
    JOIN silver.venue_details as vd on (vd.id_event = ts.id_event and vd.date_event_pull = ts.date_event_pull)
)
SELECT * FROM source_data
