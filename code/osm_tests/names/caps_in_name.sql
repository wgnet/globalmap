select
    'n'||osm_id::text as osm_id,
    name,
    'name is all caps?' as reason
from planet_osm_point
where
    (place is not null or "natural" in ('peak', 'bay', 'cliff', 'hill', 'rock')) and
    name is not null and
    (
        coalesce(tags->'name:ru', name) ~* '[a-zа-я]{3,}' and
        coalesce(tags->'name:ru', name) = upper(coalesce(tags->'name:ru', name))
    )
order by way
;