create or replace function ST_TileGeometry(
    z double precision default 0,
    x double precision default 0,
    y double precision default 0
)
    returns geometry as
$$
begin
    return ST_SetSRID(
        ST_Expand(
            ST_MakePoint(
                -20026376.39 + (x + 0.5) * 20026376.39 / 2 ^ (z - 1),
                -20026376.39 + (y + 0.5) * 20026376.39 / 2 ^ (z - 1)
            ),
            20026376.39 / (2 ^ z)
        ),
        3857
    );
end
$$
language 'plpgsql' immutable strict;