CREATE OR REPLACE FUNCTION ST_Fast_Real_Length(geom geometry)
    RETURNS double precision
    LANGUAGE plpgsql
    IMMUTABLE STRICT
AS $function$
BEGIN
    IF ST_SRID(geom) IN (3857, 900913, 3395) THEN
        RETURN ST_Length(geom) * cos(radians(ST_Y(ST_Transform(ST_Centroid(geom), 4326))));
    ELSIF ST_SRID(geom) = 4326 THEN
        RETURN ST_Length(geom::geography);
    END IF;
END
$function$;