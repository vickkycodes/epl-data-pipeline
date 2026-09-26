
with source as (
    select raw_json, extracted_at
    from {{ source('football_raw', 'standings_raw') }}
),

standings_array as (
    select
        extracted_at,
        team_item
    from source,
    unnest(json_query_array(raw_json, '$.standings[0].table')) as team_item
)

select
    int64(team_item.team.id) as team_id,
    string(team_item.team.name) as team_name,
    int64(team_item.position) as position,
    int64(team_item.playedGames) as played_games,
    int64(team_item.won) as won,
    int64(team_item.draw) as draw,
    int64(team_item.lost) as lost,
    int64(team_item.points) as points,
    int64(team_item.goalsFor) as goals_for,
    int64(team_item.goalsAgainst) as goals_against,
    int64(team_item.goalDifference) as goal_difference,
    extracted_at
from standings_array