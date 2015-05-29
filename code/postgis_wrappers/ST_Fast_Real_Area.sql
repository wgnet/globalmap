CREATE OR REPLACE FUNCTION ST_Fast_Real_Area(geom geometry)
    RETURNS double precision
    LANGUAGE plpgsql
    IMMUTABLE STRICT
AS $function$
BEGIN
    IF ST_SRID(geom) IN (3857, 900913, 3395) THEN
        RETURN ST_Area(geom) * (cos(radians(ST_Y(ST_Transform(ST_Centroid(geom), 4326)))) ^ 2);
    ELSIF ST_SRID(geom) = 4326 THEN
        RETURN ST_Area(geom) * 111319.49079 * 111319.49079 * (cos(radians(ST_Y(ST_Centroid(geom)))));
    END IF;
END
$function$;