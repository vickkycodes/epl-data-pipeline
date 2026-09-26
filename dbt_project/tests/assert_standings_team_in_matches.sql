select distinct s.team_id
from {{ ref('dim_football_standings_scd') }} s
left join {{ ref('fct_football_matches') }} m
    on s.team_id = m.home_team_id or s.team_id = m.away_team_id
where m.home_team_id is null