CREATE OR REPLACE FUNCTION ST_LabelPoint(geom geometry)

RETURNS geometry AS
$$
DECLARE
    center geometry;
BEGIN
    center = ST_Centroid(ST_Expand(geom, 0));
    IF ST_Intersects(center, geom) THEN
        return center;
    END IF;
    IF (ST_XMax(geom) - ST_XMin(geom)) < (ST_YMax(geom) - ST_YMin(geom)) THEN
        return ST_PointOnSurface(geom);
    ELSE
        return ST_Rotate(ST_PointOnSurface(ST_Rotate(geom, pi()/2)), -pi()/2);
    end if;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;