{{ config(materialized='table') }}

with staged as (
    select *
    from {{ ref('stg_football_matches') }}
),

deduped as (
    select *,
        row_number() over (
            partition by match_id
            order by extracted_at desc
        ) as rn
    from staged
)

select
    match_id,
    match_utc_date,
    match_status,
    matchday,
    home_team_id,
    home_team_name,
    away_team_id,
    away_team_name,
    home_goals_full_time,
    away_goals_full_time,
    match_winner,
    extracted_at
from deduped
where rn = 1