#!/usr/bin/env python3
"""Check manufacturing tables and indexes status"""

import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(POOLER_URL)
cursor = conn.cursor()

print("🔍 Detailed Manufacturing Status Check")
print("=" * 60)
print()

# Check indexes
print("📊 Manufacturing Indexes:")
cursor.execute("""
    SELECT indexname 
    FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND indexname LIKE '%mfg%'
    OR indexname LIKE '%supplier%'
    OR indexname LIKE '%material%'
    OR indexname LIKE '%bom%'
    ORDER BY indexname;
""")
indexes = cursor.fetchall()
print(f"Found {len(indexes)} indexes:")
for idx, in indexes[:10]:  # Show first 10
    print(f"  - {idx}")
if len(indexes) > 10:
    print(f"  ... and {len(indexes) - 10} more")
print()

# Check tables
print("📋 Tables:")
cursor.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND (
        table_name LIKE '%supplier%'
        OR table_name LIKE '%material%'
        OR table_name LIKE '%bom%'
        OR table_name IN ('purchase_orders', 'production_orders', 'payables')
    )
    ORDER BY table_name;
""")
tables = cursor.fetchall()
for table, in tables:
    cursor.execute(f"SELECT COUNT(*) FROM public.{table};")
    count = cursor.fetchone()[0]
    print(f"  ✅ {table:35s} ({count} rows)")

print()
print(f"Total: {len(tables)} tables, {len(indexes)} indexes")
print()
print("💡 Recommendation:")
if len(tables) == 0:
    print("  → Run fresh migrations (no existing data)")
elif len(indexes) > 0:
    print("  → Migrations partially run - need to DROP and recreate")
    print("  → Or modify migration to use IF NOT EXISTS for all indexes")

cursor.close()
conn.close()
