{{ config(schema='gold', alias='dim_performer', materialized='table', pre_hook=["
   create table if not exists gold.dim_performer(
          performer_sk BIGINT autoincrement start 1 increment 1,
          performer_bk CHAR(40),
          performer_description varchar(100),
          performer_popularity int,
          performer_participation_history int,
          effective_date DATETIME,
          end_date DATETIME)"
  ]) }}
WITH source_data AS (
    SELECT DISTINCT
        sha1(concat(lower(nvl(apd.team1_name, '')), ';',
          nvl(apd.team1_popularity, 0), ';', nvl(apd.team1_participation_history, 0))) AS performer_bk,
        apd.team1_name AS performer_description,
        apd.team1_popularity as performer_popularity,
        apd.team1_participation_history as performer_participation_history,
        current_timestamp() AS effective_date,
        NULL AS end_date
    FROM {{ source('silver', 'artist_performer_details') }} AS apd
    WHERE NOT EXISTS (
        SELECT 1
        FROM {{ this }} AS dp
        WHERE lower(dp.performer_description) = lower(apd.team1_name)
        AND nvl(dp.performer_popularity, 0) = nvl(apd.team1_popularity, 0)
        AND nvl(dp.performer_participation_history, 0) = nvl(apd.team1_participation_history, 0)
    )

    UNION

    SELECT DISTINCT
        sha1(concat(lower(nvl(apd.team2_name, '')), ';',
          nvl(apd.team2_popularity, 0), ';', nvl(apd.team2_participation_history, 0))) AS performer_bk,
        apd.team2_name AS performer_description,
        apd.team2_popularity as performer_popularity,
        apd.team2_participation_history as performer_participation_history,
        current_timestamp() AS effective_date,
        NULL AS end_date
    FROM {{ source('silver', 'artist_performer_details') }} AS apd
    WHERE apd.team2_name IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM {{ this }} AS dp
          WHERE lower(dp.performer_description) = lower(apd.team2_name)
          AND nvl(dp.performer_popularity, 0) = nvl(apd.team2_popularity, 0)
          AND nvl(dp.performer_participation_history, 0) = nvl(apd.team2_participation_history, 0)
      )
)

SELECT * FROM source_data
