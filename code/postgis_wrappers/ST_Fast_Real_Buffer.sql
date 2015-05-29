CREATE OR REPLACE FUNCTION ST_Fast_Real_Buffer(geom geometry, radius float, buffer_style_parameters text default '' )
    RETURNS geometry
    LANGUAGE plpgsql
    IMMUTABLE STRICT
AS $function$
BEGIN
    IF ST_SRID(geom) IN (3857, 900913, 3395) THEN
        RETURN ST_Buffer(geom, radius / cos(radians(ST_Y(ST_Transform(ST_Centroid(geom), 4326)))), buffer_style_parameters);
    ELSIF ST_SRID(geom) = 4326 THEN
        RETURN ST_SetSRID(ST_Buffer(geom::geography, radius)::geometry, 4326, buffer_style_parameters);
    END IF;
END
$function$;