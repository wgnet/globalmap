create or replace function ST_PointGrid(ext geometry, step float)
    returns setof geometry
as $$
declare
    c    geometry;
    xoff float;
    hend float;
    vend float;
begin
    xoff = ST_Xmin(ext);
    c = ST_SetSRID(ST_MakePoint(xoff, ST_Ymin(ext)), ST_SRID(ext));
    hend = ST_Xmax(ext);
    vend = st_Ymax(ext);
    while ST_X(c) < hend loop
        while ST_Y(c) < vend loop
            if _ST_Intersects(c, ext) then
                return next c;
            end if;
            c := ST_Translate(c, 0, step);
        end loop;
        xoff = xoff + step;
        c := ST_SetSRID(ST_MakePoint(xoff, ST_Ymin(ext)), ST_SRID(ext));
    end loop;
    return;
end;
$$ language 'plpgsql' immutable;
