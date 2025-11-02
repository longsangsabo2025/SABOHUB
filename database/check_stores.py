#!/usr/bin/env python3
"""
Quick check stores table structure
"""

import psycopg2
from psycopg2.extras import RealDictCursor

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(CONNECTION_STRING)
cur = conn.cursor(cursor_factory=RealDictCursor)

# Check stores columns
print("📋 Stores table columns:")
cur.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'stores'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  - {row['column_name']}: {row['data_type']} ({row['is_nullable']})")

# Check stores data
print("\n📊 Stores data:")
cur.execute("SELECT * FROM stores")
for row in cur.fetchall():
    print(f"  {dict(row)}")

# Check branches columns
print("\n📋 Branches table columns:")
cur.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'branches'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  - {row['column_name']}: {row['data_type']} ({row['is_nullable']})")

cur.close()
conn.close()
