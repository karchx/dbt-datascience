from snowflake.connector import connect
import os
from typing import Dict
import logging
from dotenv import load_dotenv
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()


def connection_snowflake() -> connect:
    required_env_vars = [
        'SNOWFLAKE_USER',
        'SNOWFLAKE_PASSWORD',
        'SNOWFLAKE_ACCOUNT',
        'SNOWFLAKE_WAREHOUSE',
        'SNOWFLAKE_DATABASE'
    ]

    missing_vars = [var for var in required_env_vars if not os.getenv(var)]
    if missing_vars:
        raise ValueError(
            f"Faltan las siguientes variables de entorno: {', '.join(missing_vars)}")

    try:
        conn = connect(
            user=os.getenv('SNOWFLAKE_USER'),
            password=os.getenv('SNOWFLAKE_PASSWORD'),
            account=os.getenv('SNOWFLAKE_ACCOUNT'),
            warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
            database=os.getenv('SNOWFLAKE_DATABASE'),
        )
        logger.info("Conexión establecida con Snowflake")
        return conn
    except Exception as e:
        logger.error(f"Error al conectar con Snowflake: {str(e)}")
        raise


def create_schemas(conn: connect):
    try:
        cur = conn.cursor()
        cur.execute("CREATE SCHEMA IF NOT EXISTS bronze")
        logger.info("Schema bronze creado o verificado")
        cur.close()
    except Exception as e:
        logger.error(f"Error al crear schemas: {str(e)}")
        raise
    finally:
        if cur:
            cur.close()


def load_bronze(conn: connect, archivo_json: str, tabla_bronze: str):
    try:
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

        logger.info(f"Datos cargados exitosamente en {tabla_bronze}")
    except Exception as e:
        logger.error(f"Error al cargar datos en bronze: {str(e)}")
        raise
    finally:
        if cur:
            cur.close()


def main():
    try:
        archivo_json = os.path.abspath('./ticketmaster.json')
        tabla_bronze = 'ticketmaster_raw'
        print(archivo_json)
        if not os.path.exists(archivo_json):
            raise FileNotFoundError(
                f"No se encontró el archivo {archivo_json}")

        conn = connection_snowflake()
        create_schemas(conn)
        load_bronze(conn, archivo_json, tabla_bronze)

        logger.info("Proceso de carga completado exitosamente")

    except Exception as e:
        logger.error(f"Error en el proceso principal: {str(e)}")
        raise

    finally:
        if 'conn' in locals() and conn:
            conn.close()
            logger.info("Conexión cerrada")


if __name__ == "__main__":
    main()
