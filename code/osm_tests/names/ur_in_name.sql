select
    'n'||osm_id::text as osm_id,
    name,
    '[RU] name contains "ур." - should be changed to "урочище"?' as reason
from planet_osm_point
where
    name is not null and
    (
        name ilike '%ур.%'
    )
order by way
;