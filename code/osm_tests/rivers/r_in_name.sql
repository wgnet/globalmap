select
    'w'||osm_id::text as osm_id,
    name,
    '[RU] river''s name contains "р." - probably should be changed to "река"? (and copied to name:ru if doesn''t exist)' as reason
from planet_osm_line
where
    "waterway" = 'river' and
    name is not null and
    (
        name ilike 'р.%' or
        name ilike '%р.'
    )
order by way
;