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
    -- Event Information
    value:event_information:name::STRING as event_name,
    value:event_information:type::STRING as event_type,
    value:event_information:dates::DATE as event_date,
    value:event_information:status::STRING as event_status,
    value:event_information:genre::STRING as event_genre,
    value:event_information:subgenre::STRING as event_subgenre,
    -- Metadata
    loaded_at,
    filename as source_file,
    array_index
FROM source_data,
LATERAL FLATTEN(input => raw_data)