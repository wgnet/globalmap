CREATE OR REPLACE FUNCTION ST_ExteriorRings(geometry) RETURNS geometry AS $$
    select
        (
            ST_Buffer(
                ST_Collect(
                    ST_MakePolygon(
                        ST_ExteriorRing(
                            p.geom
                        )
                    )
                ),
                0
            )
        )
    from (
        select (ST_Dump($1)).geom as geom
    ) p

$$ LANGUAGE SQL;