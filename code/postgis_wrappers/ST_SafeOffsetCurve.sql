CREATE OR REPLACE FUNCTION ST_SafeOffsetCurve(
                                        geom                geometry,
                                        distance            float,
                                        style_parameters    text default ''
                                        )
RETURNS geometry AS
$$
DECLARE
    eps float;
BEGIN
    IF ST_IsEmpty(geom) THEN
        RAISE DEBUG 'ST_SafeOffsetCurve: geometry is empty (%)', message;
        -- empty POLYGON makes ST_Segmentize fail, replace it with empty GEOMETRYCOLLECTION
        return ST_SetSRID('GEOMETRYCOLLECTION EMPTY'::geometry, ST_SRID(geom));
    END IF;

    eps = 0.00001;
    while eps < abs(distance) loop
        begin
            if ST_IsCollection(geom) then
                return (
                    select ST_Union(t_geom) from (
                        select
                            ST_SafeOffsetCurve(t_geom, distance, style_parameters) as t_geom
                        from (
                            select (ST_Dump(geom)).geom as t_geom
                        ) p
                    ) p
                );
            else
                return ST_OffsetCurve(geom, distance, style_parameters);
            end if;
        exception when others then
                --RAISE WARNING 'ST_SafeOffsetCurve: geometry is broken, decimating (%)', ST_AsText(geom);
                eps = eps * 2.71828;
                geom = ST_Safe_Repair(ST_SnapToGrid(geom, eps));
        end;
    end loop;
    return ST_SetSRID('GEOMETRYCOLLECTION EMPTY'::geometry, ST_SRID(geom));
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;