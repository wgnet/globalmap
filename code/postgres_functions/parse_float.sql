CREATE OR REPLACE FUNCTION parse_float(val text)
RETURNS double precision AS
$$
BEGIN
    RETURN val::double precision;
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                -- todo: more sophisticated parsing
                RETURN NULL;
            END;
    RETURN NULL;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;