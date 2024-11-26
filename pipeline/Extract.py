"""Connects to the API and extracts relevant information"""

import csv
import logging
import requests

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Logs to console
    ]
)


def extract_botanist_information(botanist_info: dict) -> dict:
    """Extracts the botanist information from the API JSON"""
    return {"name": botanist_info.get('name'),
            "email": botanist_info.get('email'),
            "phone": botanist_info.get('phone')}


def extract_location_information(location_info: list) -> dict:
    """Extracts the location information from the API JSON"""
    return {"longitude": location_info[0],
            "latitude": location_info[1],
            "closest_town": location_info[2],
            "ISO_code": location_info[3]}


def extract_plant_information(plant_info: dict) -> dict:
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


def extract_metric_information(metric_info: dict) -> dict:
    """Extracts the plant metric information from the API JSON"""
    return {"temperature": metric_info['temperature'],
            "soil_moisture": metric_info['soil_moisture'],
            "recording_taken": metric_info['recording_taken'],
            "last_watered": metric_info['last_watered']}


def fetch_and_collect_data() -> None:
    """Fetches data from the API and collects it into a list of dictionaries"""
    collected_data = []
    for number in range(50):
        url = f"https://data-eng-plants-api.herokuapp.com/plants/{number}"
        response = requests.get(url)

        if response.status_code == 200:
            api_information = response.json()
            botanist = extract_botanist_information(
                api_information['botanist'])
            location = extract_location_information(
                api_information['origin_location'])
            plant = extract_plant_information(api_information)
            plant_metric = extract_metric_information(api_information)

            combined_data = {
                **botanist,
                **location,
                "plant_name": plant["name"],
                "plant_scientific_name": plant["scientific_name"],
                "plant_image_url": plant["original_url"],
                **plant_metric
            }

            collected_data.append(combined_data)
            logging.info(f"Processed plant ID: {number}")
        else:
            logging.error(f"Failed with status code: {
                          response.status_code}, plant ID: {number}")
    return collected_data


def write_to_csv(data: list[dict], csv_file: str) -> None:
    """Writes the collected data to the CSV file"""
    with open(csv_file, mode='w', newline='', encoding='utf-8') as file:
        # gets column headings from first csv row
        writer = csv.DictWriter(file, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)
    logging.info(f"Data written to CSV file: {CSV_FILE}")


if __name__ == "__main__":
    CSV_FILE = "plant_information.csv"
    COLLECTED_DATA = fetch_and_collect_data()
    write_to_csv(COLLECTED_DATA, CSV_FILE)
