CREATE OR REPLACE FUNCTION format_osm_id(osm_id bigint, feature_type text default 'point', format text default 'level0')
RETURNS text AS
$$
BEGIN
    if format = 'level0' then
        if feature_type in ('point', 'node') and osm_id > 0 then
            return 'n'||osm_id;
        elsif feature_type in ('line', 'polygon', 'area', 'poly', 'way') and osm_id > 0 then
            return 'w'||osm_id;
        elsif feature_type in ('line', 'polygon', 'area', 'poly', 'way') and osm_id < 0 then
            return 'r'|| -osm_id;
        end if;
    end if;
    raise 'format_osm_id: cannot convert % % to %', feature_type, osm_id, format;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;