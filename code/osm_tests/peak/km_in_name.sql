select
    'n'||osm_id::text as osm_id,
    name,
    'peak''s name contains elevation - should be moved to ele=?' as reason
from planet_osm_point
where
    "natural" = 'peak' and
    name is not null and
    (
        name ~* '[0-9]+?\s?k?m'
        or name ~* '[0-9]+?\s?ft'
        or name ~* 'k?m\s?\.?\s?[0-9]+?'
        or name ~* 'ft\s?\.?\s?[0-9]+?'
    )
order by way
;