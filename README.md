# EPL Data Pipeline

An end-to-end data engineering pipeline that ingests live Premier League data,
transforms it through a modeled warehouse layer, and tracks league standings
history — built to demonstrate ELT architecture, incremental/SCD modeling,
testing, and cloud orchestration.

## Why this project

Most portfolio projects stop at "load a CSV, run some SQL." This one is built
the way a real pipeline is: raw data lands untouched, transformation happens
in a version-controlled, tested modeling layer, and two independent
schedulers keep it running without manual intervention.

## Architecture

\`\`\`mermaid
graph LR
    A[football-data.org API] -->|GitHub Actions, daily| B[BigQuery: raw_football]
    B -->|dbt staging views| C[Staging: parsed JSON]
    C -->|dbt Cloud job, daily| D[Marts: fct_matches, dim_standings_scd, fct_scorers]
    D --> E[Looker Studio Dashboard]
\`\`\`

**Orchestration is deliberately split across two schedulers**, matching how
ingestion and transformation are often owned separately in real teams:
- **GitHub Actions** — daily scheduled extraction from the football-data.org API into BigQuery raw tables
- **dbt Cloud** — daily scheduled `dbt build`, running transformations and tests

## Data model

| Layer | Model | Description |
|---|---|---|
| Staging | `stg_football_matches` | Flattened match data from raw JSON |
| Staging | `stg_football_standings` | Flattened league table snapshots |
| Staging | `stg_football_scorers` | Flattened top scorer snapshots |
| Mart | `fct_football_matches` | Deduplicated match results |
| Mart | `dim_football_standings_scd` | **SCD Type 2** — full history of each team's league position, with `valid_from`/`valid_to`/`is_current` and a `table_movement` (UP/DOWN/POSITION_UNCHANGED) indicator |
| Mart | `fct_football_scorers` | Top scorers, ranked by goals then assists |

## Testing

- Standard checks: `not_null`, `unique`, `accepted_values` on key fields
- Custom business-rule tests:
  - Goals can never be negative on a finished match
  - League position must fall between 1–20 (EPL has 20 teams)
  - Every team in the standings must appear in at least one match (cross-model referential check)

## Design decisions & trade-offs

- **Raw JSON stored as-is** in BigQuery `JSON`-typed columns, flattened only at the staging layer — preserves full source fidelity and traceability if something needs re-investigating later
- **Full-refresh table materialization**, not incremental `MERGE`, due to a BigQuery free-tier restriction (DML requires a linked billing account). The SCD Type 2 history is instead derived fresh each run using window functions (`LAG`/`LEAD`) over the accumulated raw snapshots — a valid alternative approach at this data volume. In a production setting with billing enabled, this would use `merge` incremental strategies instead.
- **Two independent schedulers** (GitHub Actions + dbt Cloud) rather than a single orchestrator — chosen deliberately to reflect a common real-world split between ingestion and transformation ownership

## Tech stack
`Python` `football-data.org API` `BigQuery` `dbt` `GitHub Actions` `Looker Studio`

## Dashboard
[Link to Looker Studio dashboard] *(coming soon)*

## Repository structure
\`\`\`
epl-data-pipeline/
├── .github/workflows/run_pipeline.yml   # scheduled extraction
├── extract/
│   ├── fetch_football_data.py
│   └── requirements.txt
├── dbt_project/                          # staging, marts, tests
└── README.md
\`\`\`
