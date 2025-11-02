#!/usr/bin/env python3
import psycopg2
from psycopg2.extras import RealDictCursor

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(CONNECTION_STRING)
cur = conn.cursor(cursor_factory=RealDictCursor)

print("📋 Tasks table columns:")
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'tasks'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  - {row['column_name']}: {row['data_type']}")

print("\n📋 Tables table columns:")
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'tables'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  - {row['column_name']}: {row['data_type']}")

cur.close()
conn.close()
