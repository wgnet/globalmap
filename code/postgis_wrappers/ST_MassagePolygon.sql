CREATE OR REPLACE FUNCTION ST_MassagePolygon(geom geometry, epsilon float default 100)
RETURNS geometry AS
$$
BEGIN
    begin
        geom = ST_Buffer(geom, 0);
    exception
        when others then
            geom = ST_SnapToGrid(geom, 0.1 * epsilon);
    end;
    geom = ST_Buffer(ST_Buffer(geom, epsilon, 'join=mitre mitre_limit=5.0'), -epsilon, 'join=mitre mitre_limit=5.0');
    return geom;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;