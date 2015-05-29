CREATE OR REPLACE FUNCTION ST_CentralPerpendicular(geom geometry,
                                                   len  double precision default 20037508.34)
RETURNS geometry AS
$$
DECLARE
    centerPoint geometry;
BEGIN
    IF ST_IsEmpty(geom) THEN
        RAISE NOTICE 'ST_CentralPerpendicular: geometry is empty';
        RETURN NULL;
    END IF;

    IF GeometryType(geom) != 'LINESTRING' THEN
        RAISE WARNING 'ST_CentralPerpendicular: geometry is not linear';
        RETURN NULL;
    END IF;

    IF ST_Dimension(geom) != 1 THEN
        RETURN ST_SetSRID('LINESTRING EMPTY'::geometry, ST_SRID(geom));
    END IF;

    centerPoint = ST_LineInterpolatePoint(geom, 0.5);

    RETURN
        (select
            ST_SetSRID(
                ST_Translate(
                    ST_Rotate(
                        ST_MakeLine(
                            ST_MakePoint(len/2, 0),
                            ST_MakePoint(-len/2, 0)
                        ),
                        -1 * ST_Azimuth(
                            ST_LineInterpolatePoint(geom, 0.499),
                            ST_LineInterpolatePoint(geom, 0.501)
                        )
                    ),
                    ST_X(centerPoint),
                    ST_Y(centerPoint)
                ),
                ST_SRID(geom)
            )
        );
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;