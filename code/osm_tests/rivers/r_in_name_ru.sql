select
    'w'||osm_id::text as osm_id,
    name,
    '[RU] river''s name:ru contains "р." - probably should be changed to "река"?' as reason
from planet_osm_line
where
    "waterway" = 'river' and
    tags?'name:ru' and
    (
        tags->'name:ru' ilike 'р.%' or
        tags->'name:ru' ilike '%р.'
    )
order by way
;