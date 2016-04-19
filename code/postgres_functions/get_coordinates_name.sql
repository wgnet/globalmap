CREATE OR REPLACE FUNCTION get_coordinates_name(geom geometry, add_to_accuracy integer)
  RETURNS character varying AS
$BODY$DECLARE
    bbox box2d;
    centroid geometry;
    x numeric;
    y numeric;
    accuracy_x int;
    accuracy_y int;

    result character varying DEFAULT '';
BEGIN
    bbox := ST_Extent(ST_Transform(geom, 4326));
    centroid := ST_Transform(ST_Centroid(geom), 4326);

        x := ST_X(centroid)::numeric;
        y := ST_Y(centroid)::numeric;

        IF (ST_xmax(bbox)-ST_xmin(bbox)) / 2 = 0 THEN
            accuracy_x := 0;
        ELSE
            accuracy_x := 0 - round(log((ST_xmax(bbox)-ST_xmin(bbox)) / 2))::int + add_to_accuracy;
        END IF;

        IF (ST_ymax(bbox)-ST_ymin(bbox)) / 2 = 0 THEN
            accuracy_y := 0;
        ELSE
            accuracy_y := 0 - round(log((ST_ymax(bbox)-ST_ymin(bbox)) / 2))::int + add_to_accuracy;
        END IF;

    x := round(x, accuracy_x);
    y := round(y, accuracy_y);

    IF y > 0 THEN
        result := result || 'S';
    ELSEIF y < 0 THEN
        result := result || 'N';
    END IF;
    result := result || abs(y);

    result := result || '-';

    IF x > 0 THEN
        result := result || 'E';
    ELSEIF x < 0 THEN
        result := result || 'W';
    END IF;
    result := result || abs(x);

    RETURN result;
END;$BODY$
  LANGUAGE plpgsql IMMUTABLE LEAKPROOF
  COST 1;
ALTER FUNCTION get_coordinates_name(geometry)
  OWNER TO postgres;
