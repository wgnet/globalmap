CREATE OR REPLACE FUNCTION parse_integer(val text)
RETURNS integer AS
$$
BEGIN
    RETURN val::integer;
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