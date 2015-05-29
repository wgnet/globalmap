select
    'n'||osm_id::text as osm_id,
    name,
    '[RU] peak''s name starts with "г." - probably should be changed to "гора"? (and copied to name:ru if doesn''t exist)' as reason
from planet_osm_point
where
    "natural" = 'peak' and
    name is not null and
    name ilike 'г.%'
order by way
;