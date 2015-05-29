select
    'n'||osm_id::text as osm_id,
    name,
    'name is strange single-character, probably should be just removed' as reason
from planet_osm_point
where
    name is not null and
    (
        name in ('-', '?', '!', '-', ',', '*', '=')
    )
order by way
;