CREATE OR REPLACE FUNCTION ST_SmoothSegmentInterpolation(
                                        a geometry,
                                        b geometry,
                                        steps integer default 100
                                        )

RETURNS geometry AS
$$
DECLARE
    line geometry[];
    i integer;
    alpha float;
BEGIN
    -- a, b - linestrings
    i := 0;
    WHILE i <= steps LOOP
        alpha = 1.*i/steps;
        line = array_append(
                    line,
                    ST_LineInterpolatePoint(
                        ST_MakeLine(
                            ST_LineInterpolatePoint(a, alpha),
                            ST_LineInterpolatePoint(b, alpha)
                        ),
                        alpha
                    )
                );
        i := i + 1;
    END LOOP;
    return ST_SetSRID(ST_MakeLine(line), ST_SRID(a));
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;