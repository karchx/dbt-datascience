from snowflake.connector import connect
import json
import pandas as pd
from typing import Dict


def connection_snowflake(config: Dict) -> connect:
    print(config['account'])
    conn = connect(
        user=config['user'],
        password=config['password'],
        account=config['account'],
        warehouse=config['warehouse'],
        database=config['database'],
    )
    return conn


def create_schemas(conn: connect):
    cur = conn.cursor()

    cur.execute("CREATE SCHEMA IF NOT EXISTS bronze")
    cur.execute("CREATE SCHEMA IF NOT EXISTS silver")

    cur.close()


def load_bronze(conn: connect, archivo_json: str, tabla_bronze: str):
    cur = conn.cursor()

    cur.execute("USE SCHEMA bronze")
    cur.execute("CREATE OR REPLACE TEMPORARY STAGE temp_json_stage")

    cur.execute(f"""
    CREATE OR REPLACE TABLE bronze.{tabla_bronze} (
        raw_data VARIANT,
        filename STRING,
        loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
    )
    """)

    # load JSON file to stage
    cur.execute(
        f"PUT file://{archivo_json} @temp_json_stage AUTO_COMPRESS=TRUE")

    cur.execute(f"""
    COPY INTO bronze.{tabla_bronze} (raw_data, filename)
    FROM (
        SELECT
            $1,
            METADATA$FILENAME
        FROM @temp_json_stage
    )
    FILE_FORMAT = (TYPE = JSON)
    """)

    cur.close()


def silver_data(conn: connect, tabla_bronze: str, tabla_silver: str):
    """
    Transform silver data
    """
    cur = conn.cursor()

    cur.execute(f"""
    CREATE OR REPLACE TABLE silver.event_information AS
    SELECT 
        -- Event Information
        value:event_information:name::STRING as event_name,
        value:event_information:type::STRING as event_type,
        value:event_information:dates::DATE as event_date,
        value:event_information:status::STRING as event_status,
        value:event_information:genre::STRING as event_genre,
        value:event_information:subgenre::STRING as event_subgenre,
         -- Metadata
        b.loaded_at,
        b.filename as source_file,
        index as array_index 
    FROM bronze.{tabla_bronze} b,
    LATERAL FLATTEN(input => b.raw_data)
    """)

    cur.execute(f"""
    CREATE OR REPLACE TABLE silver.venue_details AS
    SELECT
       -- Venue Details
       value:venue_details:name::STRING as venue_name,
       value:venue_details:location:latitude::FLOAT as venue_latitude,
       value:venue_details:location:longitude::FLOAT as venue_longitude,
       value:venue_details:location:address::STRING as venue_address,
       value:venue_details:capacity::INTEGER as venue_capacity,
       value:venue_details:event_schedule::INTEGER as event_schedule,
       -- Metadata
       b.loaded_at,
       b.filename as source_file,
       index as array_index
    FROM bronze.{tabla_bronze} b,
    LATERAL FLATTEN(input => b.raw_data)
    """)

    cur.execute(f"""
    CREATE OR REPLACE TABLE silver.ticket_sales AS
    SELECT
       -- Ticket Sales
       value:ticket_sales:price_range:min::FLOAT as min_price,
       value:ticket_sales:price_range:max::FLOAT as max_price,
       value:ticket_sales:price_range:currency::STRING as price_currency,
       value:ticket_sales:sale_dates::TIMESTAMP as sale_start_date,
       value:ticket_sales:available_quantities::STRING as ticket_limit,
       -- Metadata
       b.loaded_at,
       b.filename as source_file,
       index as array_index
    FROM bronze.{tabla_bronze} b,
    LATERAL FLATTEN(input => b.raw_data)
    """)

    cur.execute(f"""
    CREATE OR REPLACE TABLE silver.artist_performer_details AS
    SELECT
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
       b.loaded_at,
       b.filename as source_file,
       index as array_index
    
    FROM bronze.{tabla_bronze} b,
    LATERAL FLATTEN(input => b.raw_data)
    """)

    cur.close()


def main():
    # CONF secret aws
    config = {
        'user': 'xxx',
        'password': 'xxx',
        'account': 'xxxx',
        'warehouse': 'xxx',
        'database': 'xxxx'
    }

    archivo_json = './ticketmaster.json'
    tabla_bronze = 'ticketmaster_raw'
    tabla_silver = 'ticketmaster_silver'

    conn = connection_snowflake(config)
    create_schemas(conn)
    load_bronze(conn, archivo_json, tabla_bronze)
    silver_data(conn, tabla_bronze, tabla_silver)
    conn.close()


if __name__ == "__main__":
    main()
