import os
import sys

import psycopg2
import psycopg2.extras

import pprint

database = "dbname=gis user=gis"
a = psycopg2.connect(database)
a.autocommit = True
cursor = a.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

reasons = {}

for name in os.listdir('.'):
    if os.path.isdir(name):
        for sql_name in os.listdir(os.path.join(name)):
            if sql_name.endswith('.sql'):
                sys.stdout.write(sql_name)
                sys.stdout.flush()
                cursor.execute(open(os.path.join(name, sql_name)).read())
                sys.stdout.write(' done\n')
                sys.stdout.flush()
                for obj in cursor:
                    if obj.get('reason') not in reasons:
                        reasons[obj.get('reason')] = set()
                    reasons[obj.get('reason')].add(obj.get('osm_id'))


out = open('tofix.html', 'w')
out.write('<html><head><meta charset="utf-8" /><title>objects to be inspected by humans</title></head><body>')
reason_names = reasons.keys()
reason_names.sort()
reason_names.reverse()
for reason in reason_names:
    ids = reasons[reason]
    ids = list(ids)
    out.write('<h3>%s</h3>'%(reason,))
    num = 0
    out.write('<ul>')
    while ids:
        num += 1
        l = ','.join(ids[:100])
        ids = ids[100:]
        out.write("<li><a href='http://level0.osmz.ru/?url=%s' target='_blank'>Batch %s</a></li>" % (l, num))
    out.write('</ul>')
out.write('</body></html>')