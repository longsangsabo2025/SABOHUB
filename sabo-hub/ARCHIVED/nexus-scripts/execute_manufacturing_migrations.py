#!/usr/bin/env python3
"""
Execute Manufacturing Migrations
Creates tables: suppliers, materials, bom, purchase_orders, production_orders, payables
"""

import sys
from pathlib import Path

try:
    import psycopg2
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
MIGRATION_FILE = Path(__file__).parent / "database" / "migrations" / "COMBINED_MANUFACTURING_MIGRATIONS.sql"

print("=" * 80)
print("🏭 MANUFACTURING MIGRATIONS EXECUTOR")
print("=" * 80)
print()

# Read SQL
if not MIGRATION_FILE.exists():
    print(f"❌ File not found: {MIGRATION_FILE}")
    sys.exit(1)

sql_content = MIGRATION_FILE.read_text(encoding='utf-8')
print(f"📄 Migration file: {MIGRATION_FILE.name}")
print(f"   Size: {MIGRATION_FILE.stat().st_size:,} bytes")
print()

# Connect & Execute
print("🔌 Connecting to database...")
conn = psycopg2.connect(POOLER_URL)
conn.autocommit = False
cursor = conn.cursor()
print("✅ Connected!")
print()

print("⚡ Executing manufacturing migrations...")
print("   Creating tables for: suppliers, materials, bom, PO, production, payables")
print()

try:
    cursor.execute(sql_content)
    conn.commit()
    print("✅ Migrations executed successfully!")
    print()
    
    # Verify tables
    print("🔍 Verifying tables created...")
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN (
            'suppliers', 'materials', 'material_categories',
            'bom', 'bom_items',
            'purchase_orders', 'purchase_order_items',
            'production_orders', 'production_order_items',
            'payables', 'payable_items'
        )
        ORDER BY table_name;
    """)
    
    tables = cursor.fetchall()
    print(f"✅ Found {len(tables)} manufacturing tables:")
    print()
    
    for i, (table_name,) in enumerate(tables, 1):
        cursor.execute(f"SELECT COUNT(*) FROM public.{table_name};")
        count = cursor.fetchone()[0]
        print(f"   {i:2d}. {table_name:30s} ({count} rows)")
    
    print()
    
    if len(tables) >= 11:
        print("🎉 SUCCESS! All manufacturing tables created!")
    else:
        print(f"⚠️  Expected 11 tables, found {len(tables)}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print()
    print("Rolling back...")
    conn.rollback()
    cursor.close()
    conn.close()
    sys.exit(1)

finally:
    cursor.close()
    conn.close()
    print()
    print("🔒 Connection closed")

print()
print("=" * 80)
print("✅ MANUFACTURING SETUP COMPLETE!")
print("=" * 80)
print()
print("Next: Visit manufacturing pages at https://hub.saboarena.com")
print("  - /manufacturing/suppliers")
print("  - /manufacturing/materials")
print("  - /manufacturing/bom")
print("  - /manufacturing/purchase-orders")
print("  - /manufacturing/production-orders")
print("  - /manufacturing/payables")
print()
