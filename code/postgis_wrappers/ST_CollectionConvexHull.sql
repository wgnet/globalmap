CREATE OR REPLACE FUNCTION ST_CollectionConvexHull(orig_geom geometry)
RETURNS geometry AS
$$
BEGIN
    RETURN (
        select ST_Union(geom) from (
            select
                ST_ConvexHull(geom) as geom
            from (
                select (ST_Dump(orig_geom)).geom as geom
            ) p
        ) p
    );
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;