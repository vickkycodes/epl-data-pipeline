select *
from {{ ref('dim_football_standings_scd') }}
where position < 1 or position > 20