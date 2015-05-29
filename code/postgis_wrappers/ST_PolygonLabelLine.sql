CREATE OR REPLACE FUNCTION ST_PolygonLabelLine(geom geometry, seed geometry default 'POINT EMPTY')

RETURNS geometry AS
$$
DECLARE
    center geometry;
BEGIN
    if not ST_Intersects(geom, seed) then
        center = ST_LabelPoint(geom);
    else
        center = seed;
    end if;
    return
    ST_LongestSubLine(
        ST_Intersection(
            ST_SetSRID(
                ST_MakeLine(
                    ST_MakePoint(ST_XMin(geom), ST_Y(center)),
                    ST_MakePoint(ST_XMax(geom), ST_Y(center))
                ),
                ST_SRID(geom)
            ),
            geom
        )
    );
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;
