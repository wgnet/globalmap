select
    replace('w'||osm_id::text, 'w-', 'r') as osm_id,
    name,
    '[RU] lake''s name contains "оз." - probably should be changed to "озеро"? (and copied to name:ru if doesn''t exist, also consider adding water=lake)' as reason
from planet_osm_polygon
where
    "natural" = 'water' and
    name is not null and
    (
        name ilike 'оз.%' or
        name ilike '%оз.'
    )
order by way
;