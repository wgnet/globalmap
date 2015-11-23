TABLE = """(select *, w.name ? 'ko' as has_loc from gamefield_polygon g left join wgnl_localizations w on (w.osm_id = g.osm_id)) p"""
COLUMN = 'has_loc'
FILENAME = 'world.png'

import psycopg2
import mapnik
import math
import sys

self, FILENAME, COLUMN, TABLE = tuple(sys.argv)

v = 1.0
s = 1.0
p = 0.0
def rgbcolor(h, f):
    """Convert a color specified by h-value and f-value to an RGB
    three-tuple."""
    # q = 1 - f
    # t = f
    if h == 0:
        return v, f, p
    elif h == 1:
        return 1 - f, v, p
    elif h == 2:
        return p, v, f
    elif h == 3:
        return p, 1 - f, v
    elif h == 4:
        return f, p, v
    elif h == 5:
        return v, p, 1 - f

def uniquecolors(n):
    """Compute a list of distinct colors, ecah of which is
    represented as an RGB three-tuple"""
    hues = [360.0 / n * i for i in range(n)]
    hs = [math.floor(hue / 60) % 6 for hue in hues]
    fs = [hue / 60 - math.floor(hue / 60) for hue in hues]
    return [('rgb({}%, {}%, {}%)'.format(*tuple(a * 100 for a in rgbcolor(h, f)))) for h, f in zip(hs, fs)]

colors = uniquecolors(60)

m = mapnik.Map(2048, 1536)
m.background = mapnik.Color('white')
ds = mapnik.PostGIS(dbname='gis',dbuser='gis',table=TABLE, estimate_extent=False, extent_from_subquery=True)
layer = mapnik.Layer('world')
layer.datasource = ds

database = "dbname=gis user=gis"
a = psycopg2.connect(database)
a.autocommit = True
cursor = a.cursor()
cursor.execute('select distinct %s from %s order by 1'%(COLUMN, TABLE))

VALUES = [i[0] for i in cursor.fetchall() if i[0] is not None]
if type(VALUES[0]) == str:
    VALUES = ["'%s'"%(i.replace("'","\'")) for i in VALUES]
COLORS = uniquecolors(len(VALUES))

s = mapnik.Style()
r = mapnik.Rule()
polygon_symbolizer = mapnik.PolygonSymbolizer(mapnik.Color('rgba(50%, 50%, 50%,0.5)'))
r.symbols.append(polygon_symbolizer)
line_symbolizer = mapnik.LineSymbolizer(mapnik.Color('black'), 0.1)
r.symbols.append(line_symbolizer)
s.rules.append(r)
m.append_style('all',s)
layer.styles.append('all')

for value, color in zip(VALUES, COLORS):
    s = mapnik.Style()
    r = mapnik.Rule()
    f = mapnik.Filter("[{}] = {}".format(COLUMN, str(value)))
    r.filter = f
    polygon_symbolizer = mapnik.PolygonSymbolizer(mapnik.Color(color))
    r.symbols.append(polygon_symbolizer)
    line_symbolizer = mapnik.LineSymbolizer(mapnik.Color('black'), 0.2)
    r.symbols.append(line_symbolizer)
    s.rules.append(r)
    m.append_style(str(value),s)
    layer.styles.append(str(value))

m.layers.append(layer)
m.zoom_to_box(layer.envelope())
mapnik.render_to_file(m,FILENAME, 'png')