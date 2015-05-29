-- based on http://gis.stackexchange.com/questions/114764/how-to-use-st-delaunaytriangles-to-construct-a-voronoi-diagram
CREATE OR REPLACE FUNCTION ST_VoronoiPolygons(  geom_points geometry,
                                                geom_area geometry default NULL,
                                                message    text    default '[unspecified]')

RETURNS SETOF geometry AS
$$
DECLARE
    srid integer;
    pointset geometry;
    voronoi_polygons geometry;
    polygon geometry;
BEGIN
    srid := ST_SRID(geom_points);
    IF geom_area is NULL THEN
        geom_area := ST_Expand(geom_points, 0);
    END IF;
    voronoi_polygons := (WITH
        Sample AS (
            SELECT
                ST_Collect(
                    ST_SetSRID(geom_points, 0),
                    -- adding corners to get better infinity coverage
                    ST_GeomFromText('MULTIPOINT (-40000000 -40000000, 40000000 -40000000, -40000000 40000000, 40000000 40000000)')
                ) as geom
        ),
        -- Build edges and circumscribe points to generate a centroid
        edges AS (
        SELECT id,
            UNNEST(ARRAY[
                ST_MakeLine(p1,p2),
                ST_MakeLine(p2,p3),
                ST_MakeLine(p3,p1)]) Edge,
            ST_Centroid(ST_ConvexHull(ST_Union(-- Done this way due to issues I had with LineToCurve
                ST_CurveToLine(REPLACE(ST_AsText(ST_LineMerge(ST_Union(ST_MakeLine(p1,p2),ST_MakeLine(p2,p3)))), 'LINE', 'CIRCULAR'), 15),
                ST_CurveToLine(REPLACE(ST_AsText(ST_LineMerge(ST_Union(ST_MakeLine(p2,p3),ST_MakeLine(p3,p1)))), 'LINE', 'CIRCULAR'), 15)
            ))) ct
        FROM (
            -- Decompose to points
            SELECT id,
                ST_PointN(g,1) p1,
                ST_PointN(g,2) p2,
                ST_PointN(g,3) p3
            FROM (
                SELECT
                    (gd).Path id,
                    ST_ExteriorRing((gd).Geom) g -- ID and make triangle a linestring
                FROM (
                    SELECT (ST_Dump(ST_DelaunayTriangles(geom))) gd FROM Sample) a -- Get Delaunay Triangles
                ) b
            ) c
        )
    SELECT
        ST_SetSRID(
            ST_Polygonize(
                ST_Node(
                    ST_LineMerge(
                        ST_Union(
                            v,
                            ST_ExteriorRing(
                                ST_ConvexHull(
                                    v
                                )
                            )
                        )
                    )
                )
            ),
            srid
        ) as geom
    FROM (
        SELECT  -- Create voronoi edges and reduce to a multilinestring
            ST_LineMerge(ST_Union(ST_MakeLine(
            x.ct,
            CASE
            WHEN y.id IS NULL THEN
                CASE WHEN ST_Within(
                    x.ct,
                    (SELECT ST_ConvexHull(geom) FROM sample)
                )
                THEN
                    ST_MakePoint(
                        ST_X(x.ct) + ((ST_X(ST_Centroid(x.edge)) - ST_X(x.ct)) * 2),
                        ST_Y(x.ct) + ((ST_Y(ST_Centroid(x.edge)) - ST_Y(x.ct)) * 2)
                    )
                END
            ELSE
                y.ct
            END
            ))) v
        FROM
            edges x
            LEFT OUTER JOIN
            edges y ON (x.id <> y.id AND ST_Equals(x.edge, y.edge))
        ) z
);
    FOR polygon IN SELECT (ST_Dump(voronoi_polygons)).geom LOOP
        polygon := ST_Safe_Intersection(polygon, geom_area);
        IF not ST_IsEmpty(polygon) THEN
            RETURN NEXT polygon;
        END IF;
    END LOOP;
END
$$
LANGUAGE 'plpgsql' IMMUTABLE;