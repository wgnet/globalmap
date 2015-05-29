CREATE OR REPLACE FUNCTION ST_MinimumBoundingDiamond(orig_geom geometry)
RETURNS geometry AS
$$
BEGIN
    RETURN (
        select ST_Union(geom) from (
            select
                ST_Safe_Intersection(
                    ST_Safe_Intersection(
                        ST_Safe_Intersection(
                            ST_Safe_Intersection(
                                ST_Safe_Intersection(
                                    ST_Rotate(ST_Expand(ST_Rotate(geom, pi()/4), 0), -pi()/4),
                                    ST_Rotate(ST_Expand(ST_Rotate(geom, pi()/6), 0), -pi()/6)),
                                ST_Rotate(ST_Expand(ST_Rotate(geom, pi()/3), 0), -pi()/3)),
                            ST_Rotate(ST_Expand(ST_Rotate(geom, -pi()/6), 0), pi()/6)),
                        ST_Rotate(ST_Expand(ST_Rotate(geom, -pi()/3), 0), pi()/3)),
                    ST_Expand(geom, 0)
                ) as geom
            from (
                select (ST_Dump(orig_geom)).geom as geom
            ) p
        ) p
    );
END
$$
LANGUAGE 'plpgsql' IMMUTABLE STRICT;