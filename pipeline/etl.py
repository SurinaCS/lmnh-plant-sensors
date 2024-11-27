"""Runs the combined functions from extract.py, transform.py and load.py"""

# pylint: disable=broad-exception-caught
# pylint: disable=line-too-long

import asyncio
import pandas as pd

from dotenv import load_dotenv
from extract import fetch_and_collect_data
from transform import main as transform
from load import main as load


def lambda_handler(event, context):
    """Runs the ETL pipeline when the lambda is invoked"""
    try:

        load_dotenv()

        extracted_plants_metrics = pd.DataFrame(
            asyncio.run(fetch_and_collect_data()))

        cleaned_plant_metrics = transform(extracted_plants_metrics)

        load(cleaned_plant_metrics)
        return {
            "statuscode": 200,
            "body": "ETL pipeline executed successfully!"
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"An unexpected error occurred: {e}"
        }
