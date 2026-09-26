# EPL Data Pipeline

An end-to-end data engineering pipeline that ingests live English Premier League data from an API, loads raw data into BigQuery, transforms and models it with dbt, and produces analytics-ready tables for reporting and dashboarding.

The project demonstrates an ELT architecture using cloud-based ingestion, transformation, testing, dimensional modeling, historical standings tracking, and scheduled orchestration.

## Why this project

Many portfolio projects stop at loading a CSV and running a few SQL queries.

This project was designed to reflect a more realistic data engineering workflow:

- Data is extracted automatically from an external API
- Raw API responses are stored in BigQuery before transformation
- dbt is used as the transformation and modeling layer
- Staging models separate source parsing from business logic
- Mart models provide analytics-ready datasets
- Data quality is validated with dbt tests
- Ingestion and transformation are scheduled independently
- Final datasets are available for downstream BI and reporting

## Architecture

```mermaid
graph LR
    A[football-data.org API] -->|GitHub Actions - Daily| B[BigQuery Raw Layer]
    B --> C[dbt Staging Models]
    C --> D[dbt Mart Models]
    D -->|dbt Cloud - Daily Build| E[BigQuery Analytics Tables]
    E --> F[Looker Studio Dashboard]
```

The pipeline follows an ELT pattern:

```text
football-data.org API
        |
        v
Python Extraction
        |
        v
BigQuery Raw Layer
        |
        v
dbt Staging Models
        |
        v
dbt Mart Models
        |
        v
BigQuery Analytics Layer
        |
        v
Looker Studio
```

## Pipeline orchestration

The project uses two schedulers for different parts of the pipeline.

**GitHub Actions**

Handles the ingestion layer.

A scheduled workflow runs the Python extraction process, retrieves the latest football data from the API, and loads the raw data into BigQuery.

**dbt Cloud**

Handles the transformation layer.

A scheduled dbt Cloud job runs:

```bash
dbt build
```

This executes the models and associated data quality tests.

Separating ingestion and transformation also reflects how these responsibilities may be managed independently in real data teams.

## Data source

Data is retrieved from the `football-data.org` API.

The pipeline currently ingests data for:

- Premier League matches
- League standings
- Top scorers

The API responses are initially stored in BigQuery in their raw form before being transformed through dbt.

## Data transformation

Transformation is handled entirely in dbt.

The dbt project follows a layered modeling approach:

```text
Raw BigQuery tables
        |
        v
Staging models
        |
        v
Mart models
```

### Staging layer

The staging models parse and clean the raw football API data.

Current models:

| Model | Description |
|---|---|
| `stg_football_matches` | Cleans and flattens Premier League match data |
| `stg_football_standings` | Cleans and flattens league standings snapshots |
| `stg_football_scorers` | Cleans and flattens top-scorer data |

Source definitions are maintained in:

```text
models/staging/football/_src_football.yml
```

### Mart layer

The mart layer contains analytics-ready models for downstream reporting.

| Model | Description |
|---|---|
| `fct_football_matches` | Cleaned and deduplicated match-level dataset |
| `dim_football_standings` | Historical standings dimension used to track league-position changes over time |
| `fct_football_scorers` | Player scoring dataset ranked using goals and assists |

The standings model tracks changes in team position across snapshots, allowing historical league-table movement to be analyzed instead of only retaining the latest standings.

## Historical standings modeling

One of the main modeling features of the project is the ability to preserve standings history.

Instead of overwriting the league table every time new data is loaded, historical snapshots are retained in the raw layer.

dbt then uses SQL window functions such as:

```sql
LAG()
LEAD()
```

to compare standings across snapshots and identify changes in team position.

This allows metrics such as:

```text
UP
DOWN
POSITION_UNCHANGED
```

to be derived from the historical data.

The model also supports effective-period style fields such as:

```text
valid_from
valid_to
is_current
```

which provides SCD Type 2-style historical tracking without requiring incremental `MERGE` operations.

## Testing

Data quality is validated using dbt tests.

### Standard tests

Standard tests are applied to important fields using:

- `not_null`
- `unique`
- `accepted_values`

### Business-rule tests

Additional tests validate football-specific business rules.

Examples include:

- Goals cannot be negative for completed matches
- Premier League position must fall between 1 and 20
- Teams appearing in the standings should also exist in the match dataset
- Key identifiers required by downstream models cannot be null

These tests run as part of the scheduled:

```bash
dbt build
```

process.

## Design decisions and trade-offs

### Raw JSON preservation

API responses are preserved in the raw BigQuery layer before transformation.

This provides:

- Source traceability
- Easier debugging
- Reprocessing capability
- Protection against losing fields that may become useful later

The raw layer therefore represents the source data, while dbt staging models handle parsing and standardization.

### Full-refresh modeling

The project currently uses full-refresh table materializations rather than incremental `MERGE` strategies.

This decision was influenced by BigQuery free-tier limitations around certain DML operations without an attached billing account.

At the current dataset size, rebuilding the analytical models is inexpensive and operationally simple.

In a larger production environment, the same models could be migrated to dbt incremental strategies using:

```text
merge
insert_overwrite
```

or partition-based processing.

### Historical standings

Rather than using database-side updates to maintain SCD history, historical API snapshots are retained and the standings timeline is reconstructed with window functions.

For the current data volume, this provides a simple and transparent way of preserving league history.

### Separate schedulers

Ingestion and transformation are intentionally scheduled separately:

- GitHub Actions handles API extraction
- dbt Cloud handles transformation and testing

This keeps responsibilities separated and makes failures easier to isolate.

## Tech stack

| Technology | Purpose |
|---|---|
| Python | API extraction and ingestion |
| football-data.org API | Premier League data source |
| Google BigQuery | Cloud data warehouse |
| dbt | Transformation, modeling and testing |
| dbt Cloud | Scheduled transformations |
| GitHub Actions | Scheduled ingestion |
| Git / GitHub | Version control and project hosting |
| Looker Studio | Dashboard and reporting layer |

## Repository structure

```text
epl-data-pipeline/
│
├── .github/
│   └── workflows/
│       └── run_pipeline.yml
│
├── extract/
│   ├── fetch_football_data.py
│   └── requirements.txt
│
├── dbt_project/
│   │
│   ├── analyses/
│   │
│   ├── macros/
│   │
│   ├── models/
│   │   │
│   │   ├── staging/
│   │   │   └── football/
│   │   │       ├── _src_football.yml
│   │   │       ├── stg_football_matches.sql
│   │   │       ├── stg_football_scorers.sql
│   │   │       └── stg_football_standings.sql
│   │   │
│   │   └── marts/
│   │       └── football/
│   │           ├── dim_football_standings.sql
│   │           ├── fct_football_matches.sql
│   │           └── fct_football_scorers.sql
│   │
│   ├── seeds/
│   ├── snapshots/
│   ├── tests/
│   ├── dbt_project.yml
│   ├── packages.yml
│   └── package-lock.yml
│
├── .gitignore
└── README.md
```

## Data flow

```text
football-data.org
        |
        | REST API
        v
fetch_football_data.py
        |
        | GitHub Actions
        v
BigQuery Raw Dataset
        |
        | dbt
        v
Staging Models
        |
        v
Mart Models
        |
        v
BigQuery Analytics Tables
        |
        v
Looker Studio
```

## Dashboard

A Looker Studio dashboard will consume the final mart models for Premier League analysis.

Planned reporting includes:

- Current league standings
- League-position movement
- Match results
- Team performance
- Top scorers
- Goals and assists
- Historical standings trends

Dashboard link:

`Coming soon`

## Future improvements

Potential extensions to the project include:

- Convert large models to incremental dbt models
- Add BigQuery partitioning and clustering
- Introduce source freshness checks
- Add dbt documentation and lineage publishing
- Add pipeline failure notifications
- Add more seasons of historical EPL data
- Introduce CI checks on pull requests
- Add additional football competitions
- Add automated dashboard refresh validation

## Key concepts demonstrated

This project demonstrates practical experience with:

- ELT pipeline design
- REST API ingestion
- Cloud data warehousing
- Raw/staging/mart architecture
- SQL transformation
- Dimensional modeling
- Historical data modeling
- SCD concepts
- Data quality testing
- dbt model dependencies
- Workflow orchestration
- Git-based development
- Analytics engineering
