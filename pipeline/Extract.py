"""Extracts plant information from an API"""

import csv
import logging
import asyncio
import ssl
import aiohttp
import certifi

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Logs to console
    ]
)


async def extract_botanist_information(botanist_info: dict) -> dict:
    """Extracts the botanist information from the API JSON"""
    return {"name": botanist_info.get('name'),
            "email": botanist_info.get('email'),
            "phone": botanist_info.get('phone')}


async def extract_location_information(location_info: list) -> dict:
    """Extracts the location information from the API JSON"""
    return {"latitude": location_info[1],
            "longitude": location_info[0],
            "closest_town": location_info[2],
            "ISO_code": location_info[3]}


async def extract_plant_information(plant_info: dict) -> dict:
    """Extracts the plant information from the API JSON"""
    scientific_name = plant_info.get('scientific_name')
    images = plant_info.get('images')

    if scientific_name is not None:
        scientific_name = scientific_name[0]
    else:
        scientific_name = "None"

    if images is not None:
        images = images['original_url']
    else:
        images = "None"

    return {"name": plant_info.get('name'),
            "scientific_name": scientific_name,
            "original_url": images}


async def extract_metric_information(metric_info: dict) -> dict:
    """Extracts the plant metric information from the API JSON"""
    return {"temperature": metric_info.get('temperature'),
            "soil_moisture": metric_info.get('soil_moisture'),
            "recording_taken": metric_info.get('recording_taken'),
            "last_watered": metric_info.get('last_watered')}


async def fetch_plant_data(session: aiohttp.ClientSession, number: int) -> dict:
    """Fetches and processes the data for a single plant ID"""
    url = f"https://data-eng-plants-api.herokuapp.com/plants/{number}"
    try:
        async with session.get(url, timeout=30) as response:
            if response.status == 200:
                api_information = await response.json()
                botanist = await extract_botanist_information(api_information['botanist'])
                location = await extract_location_information(api_information['origin_location'])
                plant = await extract_plant_information(api_information)
                plant_metric = await extract_metric_information(api_information)

                combined_data = {
                    **botanist,
                    **location,
                    "plant_name": plant["name"],
                    "plant_scientific_name": plant["scientific_name"],
                    "plant_image_url": plant["original_url"],
                    **plant_metric
                }
                logging.info("Processed plant ID: %s", number)
                return combined_data
            logging.error(
                "Failed with status code: %s, plant ID: %s", response.status, number)
            return None
    except aiohttp.ClientError as e:
        logging.error("Error fetching data for plant ID %s: %s", number, e)
        return None


async def fetch_and_collect_data() -> list:
    """Fetches data concurrently for all plants and returns it as a list of dictionaries"""
    ssl_context = ssl.create_default_context(cafile=certifi.where())

    async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=ssl_context)) as session:
        tasks = [fetch_plant_data(session, number)
                 for number in range(51)]
        results = await asyncio.gather(*tasks)

        return [result for result in results if result is not None]


def write_to_csv(data: list[dict], csv_file: str) -> None:
    """Writes the collected data to the CSV file"""
    if data:
        with open(csv_file, mode='w', newline='', encoding='utf-8') as file:
            writer = csv.DictWriter(file, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)
        logging.info("Data written to CSV file: %s", csv_file)
    else:
        logging.error("No data to write to CSV.")


if __name__ == "__main__":
    CSV_FILE = "Plant_information.csv"
    collected_data = asyncio.run(fetch_and_collect_data())
    write_to_csv(collected_data, CSV_FILE)
