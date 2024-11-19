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
    value:artist_performer_details[0]:id_event::STRING as id_event,
    value:artist_performer_details[0]:date_event_pull::DATETIME as date_event_pull,
    -- Team/Performer 1
    value:artist_performer_details[0]:name::STRING as team1_name,
    value:artist_performer_details[0]:genre::STRING as team1_genre,
    value:artist_performer_details[0]:popularity::INTEGER as team1_popularity,
    value:artist_performer_details[0]:event_participation_history::INTEGER as team1_participation_history,
    -- Team/Performer 2
    value:artist_performer_details[1]:name::STRING as team2_name,
    value:artist_performer_details[1]:genre::STRING as team2_genre,
    value:artist_performer_details[1]:popularity::INTEGER as team2_popularity,
    value:artist_performer_details[1]:event_participation_history::INTEGER as team2_participation_history,
    -- Metadata
    loaded_at,
    filename as source_file
--    array_index
FROM source_data,
LATERAL FLATTEN(input => raw_data)
