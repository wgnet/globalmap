CREATE OR REPLACE FUNCTION ST_Safe_Repair(
                                        geom        geometry,
                                        message     text             default '[unspecified]'
                                        )
RETURNS geometry AS
$$
BEGIN
    IF ST_IsEmpty(geom) THEN
        RAISE DEBUG 'ST_Safe_Repair: geometry is empty (%)', message;
        -- empty POLYGON makes ST_Segmentize fail, replace it with empty GEOMETRYCOLLECTION
        RETURN ST_SetSRID('GEOMETRYCOLLECTION EMPTY'::geometry, ST_SRID(geom));
    END IF;
    IF ST_IsValid(geom) THEN
        RETURN ST_ForceRHR(ST_CollectionExtract(geom, ST_Dimension(geom) + 1));
    END IF;
    RETURN
        ST_CollectionExtract(
            ST_MakeValid(
                geom
            ),
            ST_Dimension(geom) + 1
        );
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;