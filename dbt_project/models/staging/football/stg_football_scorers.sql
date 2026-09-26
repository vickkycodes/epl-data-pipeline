{{ config(materialized='view') }}

with source as (
    select raw_json, extracted_at
    from {{ source('football_raw', 'scorers_raw') }}
),

scorers_array as (
    select
        extracted_at,
        scorer_item
    from source,
    unnest(json_query_array(raw_json, '$.scorers')) as scorer_item
)

select
    lax_int64(scorer_item.player.id) as player_id,
    lax_string(scorer_item.player.name) as player_name,
    lax_string(scorer_item.player.nationality) as nationality,
    lax_int64(scorer_item.team.id) as team_id,
    lax_string(scorer_item.team.name) as team_name,
    lax_int64(scorer_item.playedMatches) as played_matches,
    lax_int64(scorer_item.goals) as goals,
    lax_int64(scorer_item.assists) as assists,
    extracted_at
from scorers_array