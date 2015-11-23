create or replace function ST_InscribedCircle(
    geom geometry,
    prec double precision default 100
)
    returns geometry as
    $$
    declare
        eps        double precision;
        max_radius double precision;
        min_radius double precision;
        geom_left  geometry;
        area_left  double precision;
        orig_area  double precision;
        cur_radius double precision;
    begin
        eps = ST_Perimeter(ST_Envelope(geom)) / (4 * prec);
        geom = ST_Simplify(geom, eps);
        min_radius = 0.000000001;
        max_radius = eps * prec / 2;
        orig_area = ST_Area(geom);
        area_left = 0;
        cur_radius = 0;
        while (area_left > eps * eps) or (area_left = 0) loop
            raise warning 'left %, min_radius %, max_radius %, cur_radius %', area_left, min_radius, max_radius, cur_radius;
-- cur_radius = (max_radius-min_radius) * sqrt(area_left / orig_area) + min_radius;
            cur_radius = cur_radius + sqrt(area_left);
            if cur_radius <= min_radius or cur_radius >= max_radius
            then cur_radius = (max_radius + min_radius) / 2; end if;
-- cur_radius = (max_radius + min_radius) /2;
            geom_left = ST_Buffer(geom, -cur_radius);
            if geom_left is null or ST_IsEmpty(geom_left)
            then
                raise warning 'too large radius %', cur_radius;
                max_radius = cur_radius;
                cur_radius = (max_radius + min_radius) / 2;
                area_left = 0;

            else
                min_radius = cur_radius;
                area_left = ST_Area(geom_left);
-- max_radius = least(cur_radius + sqrt(area_left), max_radius);
            end if;
        end loop;
        return ST_Buffer(ST_PointOnSurface(geom_left), max_radius);
    end
    $$
language 'plpgsql' immutable strict;


