CREATE OR REPLACE FUNCTION ST_Safe_Intersection(geom_a   geometry,
                                                geom_b   geometry         default NULL,
                                                message  text             default '[unspecified]',
                                                grid_granularity double precision default 1)
RETURNS geometry AS
$$
BEGIN
    IF geom_b IS NULL THEN
        RAISE NOTICE 'ST_Safe_Intersection: second geometry is NULL (%)', message;
        RETURN geom_b;
    END IF;
    RETURN
        ST_Safe_Repair(
            ST_Intersection(
                geom_a,
                geom_b
            )
        );
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RAISE NOTICE 'ST_Safe_Intersection: making everything valid (%)', message;
                RETURN
                ST_Translate(
                    ST_Safe_Repair(
                        ST_Difference(
                            ST_Safe_Repair(
                                ST_Intersection(
                                    ST_Safe_Repair(ST_Translate(geom_a, -ST_XMin(geom_a), -ST_YMin(geom_a))),
                                    ST_Safe_Repair(ST_Translate(geom_b, -ST_XMin(geom_a), -ST_YMin(geom_a)))
                                )
                            )
                        )
                    ),
                    ST_XMin(geom_a),
                    ST_YMin(geom_a)
                );
                EXCEPTION
                    WHEN OTHERS THEN
                        BEGIN
                            RAISE NOTICE 'ST_Safe_Intersection: buffering everything (%)', message;
                            RETURN
                                ST_Safe_Repair(
                                    ST_Intersection(
                                        ST_Buffer(
                                            geom_a,
                                            0.4 * grid_granularity
                                        ),
                                        ST_Buffer(
                                            geom_b,
                                            -0.4 * grid_granularity
                                        )
                                    )
                                );
                            EXCEPTION
                                WHEN OTHERS THEN
                                    RAISE EXCEPTION 'ST_Safe_Intersection: everything failed (%)', message;
                                    -- RETURN ST_MakeValid(geom_a);
                        END;
            END;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE;