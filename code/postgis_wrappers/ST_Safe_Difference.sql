CREATE OR REPLACE FUNCTION ST_Safe_Difference(geom_a   geometry,
                                              geom_b   geometry         default NULL,
                                              message  text             default '[unspecified]',
                                              grid_granularity double precision default 1)
RETURNS geometry AS
$$
BEGIN
    IF geom_b IS NULL THEN
        RAISE DEBUG 'ST_Safe_Difference: second geometry is NULL (%)', message;
        RETURN geom_a;
    END IF;
    IF ST_IsEmpty(geom_b) THEN
        RAISE DEBUG 'ST_Safe_Difference: second geometry is empty (%)', message;
        RETURN geom_a;
    END IF;
    RETURN
        ST_Safe_Repair(
            ST_Translate(
                ST_Difference(
                    ST_Translate(geom_a, -ST_XMin(geom_a), -ST_YMin(geom_a)),
                    ST_Translate(geom_b, -ST_XMin(geom_a), -ST_YMin(geom_a))
                ),
                ST_XMin(geom_a),
                ST_YMin(geom_a)
            )
        );
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RAISE NOTICE 'ST_Safe_Difference: making everything valid (%)', message;
                RETURN
                    ST_Translate(
                        ST_Safe_Repair(
                            ST_Difference(
                                ST_Translate(ST_Safe_Repair(geom_a), -ST_XMin(geom_a), -ST_YMin(geom_a)),
                                ST_Buffer(ST_Translate(geom_b, -ST_XMin(geom_a), -ST_YMin(geom_a)), 0.4 * grid_granularity)
                            )
                        ),
                        ST_XMin(geom_a),
                        ST_YMin(geom_a)
                    );
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE WARNING 'ST_Safe_Difference: everything failed (%)', message;
                        RETURN ST_Safe_Repair(geom_a);
        END;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE;