CREATE OR REPLACE FUNCTION ST_Nullify(geom geometry)
RETURNS geometry AS
$$
BEGIN
    IF ST_IsEmpty(geom) THEN
        RETURN NULL;
    END IF;
    RETURN geom;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;