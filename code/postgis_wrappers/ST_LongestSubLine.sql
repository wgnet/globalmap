CREATE OR REPLACE FUNCTION ST_LongestSubLine(geom   geometry,
                                             grid_granularity double precision default 1)
RETURNS geometry AS
$$
BEGIN
    IF ST_IsEmpty(geom) THEN
        RAISE WARNING 'ST_LongestSubLine: geometry is empty';
        RETURN ST_SetSRID('LINESTRING EMPTY'::geometry, ST_SRID(geom));
    END IF;
--    IF ST_IsCollection(geom) THEN
--        geom = ST_CollectionHomogenize(geom);
--    END IF;

    IF ST_Dimension(geom) = 2 THEN
        geom = ST_Boundary(geom);
    END IF;

    geom = ST_SnapToGrid(geom, grid_granularity);
    geom = ST_LineMerge(ST_Safe_Repair(geom));

    IF ST_Dimension(geom) != 1 THEN
        RETURN ST_SetSRID('LINESTRING EMPTY'::geometry, ST_SRID(geom));
    END IF;

    RETURN
        (select p.geom from (select (ST_Dump(geom)).geom as geom) p order by ST_Length(p.geom) desc limit 1);
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;