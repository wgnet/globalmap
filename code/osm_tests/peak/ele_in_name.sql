select
    'n'||osm_id::text as osm_id,
    name,
    'peak''s name is a number - probably should be moved to ele=?' as reason
from planet_osm_point
where
    "natural" = 'peak' and
    name is not null and (
        parse_float(name) is not null
    )
order by way
;