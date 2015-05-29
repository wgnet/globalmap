select
    replace('w'||osm_id::text, 'w-', 'r') as osm_id,
    name,
    '[RU] lake''s name:ru contains "оз." - probably should be changed to "озеро"?' as reason
from planet_osm_polygon
where
    "natural" = 'water' and
    tags?'name:ru' and
    (
        tags->'name:ru' ilike 'оз.%' or
        tags->'name:ru' ilike '%оз.'
    )
order by way
;