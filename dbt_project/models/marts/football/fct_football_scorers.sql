{{ config(materialized='table') }}

with staged as (
    select *
    from {{ ref('stg_football_scorers') }}
),

deduped as (
    select *,
        row_number() over (
            partition by player_id
            order by extracted_at desc
        ) as rn
    from staged
)

select
    player_id,
    player_name,
    nationality,
    team_id,
    team_name,
    played_matches,
    goals,
    assists,
    rank() over (order by goals desc, coalesce(assists, 0) desc) as goal_rank,
    extracted_at
from deduped
where rn = 1
order by goal_rank