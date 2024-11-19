{{ config(schema='silver') }}
WITH source_data AS (
    SELECT
        raw_data,
        loaded_at,
        filename
--        index as array_index
    FROM {{ source('bronze', 'ticketmaster_raw') }}
)

SELECT
    value:venue_details:id_event::STRING as id_event,
    value:venue_details:date_event_pull::DATETIME as date_event_pull,
    -- Venue Details
    value:venue_details:name::STRING as venue_name,
    value:venue_details:location:latitude::FLOAT as venue_latitude,
    value:venue_details:location:longitude::FLOAT as venue_longitude,
    value:venue_details:location:address::STRING as venue_address,
    value:venue_details:capacity::INTEGER as venue_capacity,
    value:venue_details:event_schedule::INTEGER as event_schedule,
    -- Metadata
    loaded_at,
    filename as source_file
--    array_index
FROM source_data,
LATERAL FLATTEN(input => raw_data)
