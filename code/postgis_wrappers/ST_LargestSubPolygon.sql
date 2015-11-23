CREATE OR REPLACE FUNCTION ST_LargestSubPolygon(geom geometry)
RETURNS geometry AS
$$
BEGIN
    IF NOT ST_IsCollection(geom) THEN
        RETURN geom;
    END IF;
    RETURN (select * from (select (ST_Dump(geom)).geom g) p order by ST_Area(g) desc limit 1);
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;