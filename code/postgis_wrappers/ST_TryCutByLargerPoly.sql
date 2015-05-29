CREATE OR REPLACE FUNCTION ST_TryCutByLargerPoly(geom_a     geometry,
                                                 geom_b     geometry         default NULL,
                                                 message    text             default '[unspecified]',
                                                 area_saved double precision default 0.7)

RETURNS geometry AS
$$
DECLARE
    intersection geometry;
BEGIN
    IF geom_b IS NULL THEN
        RAISE NOTICE 'ST_TryCutByLargerPoly: second geometry is NULL (%)', message;
        RETURN geom_a;
    END IF;
    intersection := ST_Safe_Intersection(geom_a, geom_b);
    IF ST_Area(intersection) > (area_saved * ST_Area(geom_a)) THEN
        RETURN intersection;
    ELSE
        RETURN geom_a;
    END IF;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE;