select *
from {{ ref('fct_football_matches') }}
where match_status = 'FINISHED'
  and (home_goals_full_time < 0
    or away_goals_full_time < 0)