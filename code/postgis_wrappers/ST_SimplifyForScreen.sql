CREATE OR REPLACE FUNCTION ST_SimplifyForScreen(geom geometry)
RETURNS geometry AS
$$
DECLARE
    eps double precision;
BEGIN
    eps = ST_Perimeter(ST_Envelope(geom))/4000;
    RETURN ST_SimplifyPreserveTopology(
                        ST_Buffer(
                            ST_Buffer(
                                ST_SimplifyPreserveTopology(
                                    geom,
                                    eps),
                                3 * eps,
                                2),
                            -3 * eps,
                            2),
                        eps);
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;


