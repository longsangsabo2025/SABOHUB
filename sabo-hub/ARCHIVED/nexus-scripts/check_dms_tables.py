#!/usr/bin/env python3
"""Check what DMS tables exist in the database"""

import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("🔍 Checking DMS tables in database...")
print()

conn = psycopg2.connect(POOLER_URL)
cursor = conn.cursor()

# Get all tables
cursor.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    ORDER BY table_name;
""")

all_tables = [row[0] for row in cursor.fetchall()]
dms_tables = [t for t in all_tables if t.startswith('dms_')]

print(f"Total tables in public schema: {len(all_tables)}")
print(f"DMS tables (dms_*): {len(dms_tables)}")
print()

if dms_tables:
    print("📋 DMS Tables found:")
    for i, table in enumerate(dms_tables, 1):
        print(f"  {i:2d}. {table}")
else:
    print("❌ No DMS tables found!")
    print()
    print("🔍 Searching for similar table names...")
    
    # Check for tables with distributor, sell, route, visit, chart, journal
    keywords = ['distributor', 'sell', 'route', 'visit', 'chart', 'journal', 'store', 'price']
    found_any = False
    
    for keyword in keywords:
        matching = [t for t in all_tables if keyword in t.lower()]
        if matching:
            found_any = True
            print(f"\n  Tables containing '{keyword}':")
            for table in matching:
                print(f"    - {table}")
    
    if not found_any:
        print("\n  No related tables found.")
        print("\n  First 10 tables in database:")
        for i, table in enumerate(all_tables[:10], 1):
            print(f"    {i:2d}. {table}")

cursor.close()
conn.close()
