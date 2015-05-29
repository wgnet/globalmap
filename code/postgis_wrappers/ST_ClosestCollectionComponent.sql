CREATE OR REPLACE FUNCTION ST_ClosestCollectionComponent(collection geometry,
                                                         geom       geometry)
RETURNS geometry AS
$$
BEGIN
    IF NOT ST_IsCollection(collection) THEN
        RETURN collection;
    END IF;
    RETURN (select * from (select (ST_Dump(collection)).geom g) p order by ST_Distance(g, geom), ST_Length(g) desc limit 1);
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;