
with source as (
    select raw_json, extracted_at
    from {{ source('football_raw', 'matches_raw') }}
),

matches_array as (
    select
        extracted_at,
        match_item
    from source,
    unnest(json_query_array(raw_json, '$.matches')) as match_item
)

select
    lax_int64(match_item.id) as match_id,
    timestamp(lax_string(match_item.utcDate)) as match_utc_date,
    lax_string(match_item.status) as match_status,
    lax_int64(match_item.matchday) as matchday,
    lax_int64(match_item.homeTeam.id) as home_team_id,
    lax_string(match_item.homeTeam.name) as home_team_name,
    lax_int64(match_item.awayTeam.id) as away_team_id,
    lax_string(match_item.awayTeam.name) as away_team_name,
    lax_int64(match_item.score.fullTime.home) as home_goals_full_time,
    lax_int64(match_item.score.fullTime.away) as away_goals_full_time,
    lax_string(match_item.score.winner) as match_winner,
    extracted_at
from matches_array