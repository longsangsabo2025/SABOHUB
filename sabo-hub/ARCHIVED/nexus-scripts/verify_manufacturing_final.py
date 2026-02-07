#!/usr/bin/env python3
import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

REQUIRED_TABLES = [
    'manufacturing_suppliers',
    'manufacturing_materials',
    'manufacturing_material_categories',
    'manufacturing_bom',
    'manufacturing_bom_items',
    'manufacturing_purchase_orders',
    'manufacturing_purchase_order_items',
    'manufacturing_production_orders',
    'manufacturing_production_order_items',
    'manufacturing_production_materials',
    'manufacturing_payables',
    'manufacturing_payable_items'
]

conn = psycopg2.connect(POOLER_URL)
cursor = conn.cursor()

print("✅ MANUFACTURING TABLES STATUS")
print("=" * 60)

existing = []
missing = []

for table in REQUIRED_TABLES:
    cursor.execute(f"""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = '{table}'
        );
    """)
    if cursor.fetchone()[0]:
        existing.append(table)
        print(f"✅ {table}")
    else:
        missing.append(table)
        print(f"❌ {table} (MISSING)")

print()
print(f"Summary: {len(existing)}/{len(REQUIRED_TABLES)} tables exist")

if len(existing) == len(REQUIRED_TABLES):
    print()
    print("🎉 ALL MANUFACTURING TABLES READY!")
    print("   Manufacturing pages should work now!")
elif missing:
    print()
    print(f"⚠️  Need to create {len(missing)} tables:")
    for t in missing:
        print(f"   - {t}")

cursor.close()
conn.close()
