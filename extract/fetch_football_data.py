from dotenv import load_dotenv
import requests
import json
from datetime import datetime, timezone
from google.cloud import bigquery
from google.cloud.exceptions import NotFound
import os

# --- Config ---
API_KEY = os.environ["FOOTBALL_API_KEY"]
PROJECT_ID = "sublime-amp-480104-g6"
DATASET_ID = "raw_football"
LOCATION = "US"  

headers = {"X-Auth-Token": API_KEY}

ENDPOINTS = {
    "matches": "https://api.football-data.org/v4/competitions/PL/matches",
    "standings": "https://api.football-data.org/v4/competitions/PL/standings",
    "scorers": "https://api.football-data.org/v4/competitions/PL/scorers",
}

client = bigquery.Client(project=PROJECT_ID)

TABLE_SCHEMA = [
    bigquery.SchemaField("raw_json", "JSON", mode="REQUIRED"),
    bigquery.SchemaField("extracted_at", "TIMESTAMP", mode="REQUIRED"),
]


def ensure_dataset_exists():
    dataset_ref = f"{PROJECT_ID}.{DATASET_ID}"
    try:
        client.get_dataset(dataset_ref)
        print(f"Dataset {dataset_ref} already exists.")
    except NotFound:
        dataset = bigquery.Dataset(dataset_ref)
        dataset.location = LOCATION
        client.create_dataset(dataset)
        print(f"Created dataset {dataset_ref}.")


def ensure_table_exists(table_name):
    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{table_name}_raw"
    try:
        client.get_table(table_ref)
        print(f"Table {table_ref} already exists.")
    except NotFound:
        table = bigquery.Table(table_ref, schema=TABLE_SCHEMA)
        client.create_table(table)
        print(f"Created table {table_ref}.")


def fetch_and_load(name, url):
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    data = response.json()

    row = {
        "raw_json": data,   # pass the dict directly — let BigQuery handle JSON serialization
        "extracted_at": datetime.now(timezone.utc).isoformat(),
    }

    table_id = f"{PROJECT_ID}.{DATASET_ID}.{name}_raw"

    job_config = bigquery.LoadJobConfig(
        schema=TABLE_SCHEMA,
        write_disposition="WRITE_APPEND",
    )

    load_job = client.load_table_from_json([row], table_id, job_config=job_config)
    load_job.result()

    print(f"Loaded {name} successfully at {row['extracted_at']}")


if __name__ == "__main__":
    ensure_dataset_exists()
    for name in ENDPOINTS:
        ensure_table_exists(name)
    for name, url in ENDPOINTS.items():
        fetch_and_load(name, url)
