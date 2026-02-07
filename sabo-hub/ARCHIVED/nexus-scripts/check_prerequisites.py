#!/usr/bin/env python3
"""Check what's missing for manufacturing"""

import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(POOLER_URL)
cursor = conn.cursor()

print("🔍 Checking prerequisites for manufacturing...")
print()

# Check companies
cursor.execute("SELECT name FROM public.companies ORDER BY created_at;")
companies = cursor.fetchall()
print(f"Companies: {len(companies)}")
for name, in companies:
    print(f"  - {name}")
print()

# Check if odori_warehouses table exists
cursor.execute("""
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'odori_warehouses'
    );
""")
has_odori_warehouses = cursor.fetchone()[0]
print(f"odori_warehouses table: {'✅ EXISTS' if has_odori_warehouses else '❌ MISSING'}")

# Check regular warehouses table
cursor.execute("""
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'warehouses'
    );
""")
has_warehouses = cursor.fetchone()[0]
print(f"warehouses table: {'✅ EXISTS' if has_warehouses else '❌ MISSING'}")

if has_warehouses:
    cursor.execute("SELECT COUNT(*) FROM public.warehouses;")
    count = cursor.fetchone()[0]
    print(f"  → {count} warehouses exist")

cursor.close()
conn.close()
