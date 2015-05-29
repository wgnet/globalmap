CREATE OR REPLACE FUNCTION ST_FilterSmallRings(
                                            geom            geometry,
                                            min_area        double precision default 0)
RETURNS geometry AS
$$
BEGIN
    IF ST_Dimension(geom) != 2 THEN
        RETURN ST_SetSRID('POLYGON EMPTY'::geometry, ST_SRID(geom));
    END IF;

    IF ST_NRings(geom) = 1 THEN
        IF ST_Area(geom) > min_area THEN
            RETURN geom;
        ELSE
            RETURN ST_SetSRID('POLYGON EMPTY'::geometry, ST_SRID(geom));
        END IF;
    END IF;


    RETURN (
        select
            ST_BuildArea(
                ST_Collect(
                    (ring).geom
                )
            )
        from
            (select
                ST_DumpRings(p.geom) as ring
            from
                (
                    select (ST_Dump(geom)).geom as geom
                ) p
            ) p
        where
            ST_Area((ring).geom) > min_area

    );
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;