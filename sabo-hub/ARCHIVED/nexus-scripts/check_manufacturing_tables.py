#!/usr/bin/env python3
"""Check Manufacturing Tables"""

import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

MANUFACTURING_TABLES = [
    'suppliers',
    'materials',
    'material_categories',
    'bom',
    'bom_items',
    'purchase_orders',
    'purchase_order_items',
    'production_orders',
    'production_order_items',
    'payables',
    'payable_items'
]

print("🔍 Checking Manufacturing Tables...")
print()

conn = psycopg2.connect(POOLER_URL)
cursor = conn.cursor()

existing = []
missing = []

for table in MANUFACTURING_TABLES:
    cursor.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = %s
        );
    """, (table,))
    
    exists = cursor.fetchone()[0]
    if exists:
        cursor.execute(f"SELECT COUNT(*) FROM public.{table};")
        count = cursor.fetchone()[0]
        print(f"✅ {table:30s} ({count} rows)")
        existing.append(table)
    else:
        print(f"❌ {table:30s} (MISSING)")
        missing.append(table)

print()
print(f"Summary: {len(existing)}/{len(MANUFACTURING_TABLES)} tables exist")

if missing:
    print()
    print(f"⚠️  Missing {len(missing)} tables:")
    for table in missing:
        print(f"   - {table}")
    print()
    print("💡 Need to run manufacturing migrations (027-032)")

cursor.close()
conn.close()
