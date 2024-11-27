"""Archives data from the past 24 hours and cleans the plant metric ta"""

from os import environ
import logging
from dotenv import load_dotenv
from pymssql import connect, Connection, exceptions

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')


def get_connection() -> Connection:
    """Connects to Microsoft SQL Server Database"""
    logging.info("Attempting to connect to the database.")
    try:
        conn = connect(
            server=environ["DB_HOST"],
            port=environ["DB_PORT"],
            user=environ["DB_USER"],
            password=environ["DB_PASSWORD"],
            database=environ["DB_NAME"],
            as_dict=True
        )
        logging.info("Database connection successful.")
        return conn
    except KeyError as e:
        logging.error("%s missing from environment variables.", e)
        raise
    except exceptions.OperationalError as e:
        logging.error("Error connecting to database: %s", e)
        raise
    except Exception as e:
        logging.error("Unexpected error while connecting to database: %s", e)
        raise


def get_all_plant_ids(conn: Connection):
    """Retrieves all plant ids from the database"""
    query = "SELECT plant_id FROM plant;"
    with conn.cursor() as cur:
        cur.execute(query)
        plant_ids = cur.fetchall()
        ids = [id['plant_id'] for id in plant_ids]

    return ids


def get_plants_data(conn: Connection, plant_ids):
    """Combines the plant ids and plant metrics"""
    for id in plant_ids:
        metrics = calculate_archive_metrics(conn, id)[0]
        latest_recording = get_latest_recording(conn, id)['recording_taken']
        metrics['last_recorded'] = latest_recording
        metrics['plant_id'] = id
        upload_plant_metric_data(conn, metrics)


def upload_plant_metric_data(conn: Connection, plant_details: dict):
    """Uploads the past 24 hour data from plant metrics table into archive table"""

    logging.info("Attempting to insert into archive table")
    query = """INSERT INTO plants_archive (avg_temperature, 
                    avg_soil_moisture, watered_count, last_recorded, plant_id)
                VALUES (%s, %s, %s, %s, %s);"""

    avg_temp = plant_details.get("avg_temp")
    avg_soil_moist = plant_details.get("avg_moisture")
    watered_count = plant_details.get("watered_count")
    last_recorded = plant_details.get("last_recorded")
    plant_id = plant_details.get("plant_id")

    with conn.cursor() as cur:
        cur.execute(query, (avg_temp, avg_soil_moist,
                    watered_count, last_recorded, plant_id))

    logging.info("Completed inserting to archive")


def calculate_archive_metrics(conn: Connection, plant_id: int) -> int:
    """Calculates the number of times a given plant was watered in the last 24 hours"""

    query = """SELECT
                    AVG(soil_moisture) as avg_moisture,
                    COUNT(DISTINCT(last_watered)) as watered_count,
                    AVG(temperature) as avg_temp
                FROM plant_metric
                WHERE plant_id = %s"""
    with conn.cursor() as cur:
        cur.execute(query, (plant_id,))
        archive_metrics = cur.fetchall()

    return archive_metrics


def get_latest_recording(conn: Connection, plant_id: int) -> int:
    """Finds the latest time a recording was made for a given plant."""

    query = """SELECT TOP 1 recording_taken
                FROM plant_metric
                WHERE plant_id = %s
                ORDER BY recording_taken DESC;"""
    with conn.cursor() as cur:
        cur.execute(query, (plant_id,))
        latest_recording = cur.fetchone()

    return latest_recording


def clear_plant_metrics(conn: Connection) -> None:
    """ Clears all recordings from the plant metrics table."""
    query = "TRUNCATE TABLE plant_metric;"
    with conn.cursor() as cur:
        cur.execute(query)


def lambda_handler(event, context):
    """Moves data in the archive table and cleans the plant_metric table
    when the lambda is invoked"""
    try:
        load_dotenv()
        logging.info("Connecting to database")
        conn = get_connection()

        plant_ids = get_all_plant_ids(conn)
        get_plants_data(conn, plant_ids)

        clear_plant_metrics(conn)
        logging.info("Plant metric table has been cleared")

        return {
            "statuscode": 200,
            "body": "ETL pipeline executed successfully!"
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"An unexpected error occurred: {e}"
        }


if __name__ == "__main__":
    lambda_handler(None, None)
