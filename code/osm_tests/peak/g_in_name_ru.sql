select
    'n'||osm_id::text as osm_id,
    tags->'name:ru' as "name:ru",
    'peak''s name starts with "г." - probably should be changed to "гора"? (and copied to name:ru if doesn''t exist)' as reason
from planet_osm_point
where
    "natural" = 'peak' and
    tags?'name:ru' and
    tags->'name:ru' ilike 'г.%'
order by way;