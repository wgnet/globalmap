select
    'n'||osm_id::text as osm_id,
    name,
    'place''s name contains "km." - probably it is a highway=milestone or ele=?' as reason
from planet_osm_point
where
    place is not null and
    name is not null and
    (
        name ~* '[0-9]+?\s?km'
        or name ~* 'km\s?\.?\s?[0-9]+?'
--        or name ~* '[0-9]+?\s?к?м\M'
    )
order by way
;
