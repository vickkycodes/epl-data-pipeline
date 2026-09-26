{{ config(materialized='table') }}

with source as (
    select
        team_id,
        team_name,
        position,
        points,
        played_games,
        goals_for,
        goals_against,
        goal_difference,
        extracted_at
    from {{ ref('stg_football_standings') }}
),

with_previous as (
    select
        *,
        lag(position) over (partition by team_id order by extracted_at) as prev_position,
        lag(points) over (partition by team_id order by extracted_at) as prev_points,
        lag(played_games) over (partition by team_id order by extracted_at) as prev_played_games
    from source
),

changes_only as (
    select
        *,
        case
            when prev_position is null then 'NEW'
            when position < prev_position then 'UP'
            when position > prev_position then 'DOWN'
            else 'UNCHANGED'
        end as table_movement
    from with_previous
    where prev_position is null
       or position != prev_position
       or points != prev_points
       or played_games != prev_played_games
)

select
    team_id,
    team_name,
    position,
    points,
    played_games,
    goals_for,
    goals_against,
    goal_difference,
    table_movement,
    extracted_at as valid_from,
    lead(extracted_at) over (partition by team_id order by extracted_at) as valid_to,
    lead(extracted_at) over (partition by team_id order by extracted_at) is null as is_current
from changes_only
order by position