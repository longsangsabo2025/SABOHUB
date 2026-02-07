#!/usr/bin/env python3
"""Check DB schema for Sales features"""
import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(POOLER_URL)
cur = conn.cursor()

print("=" * 60)
print("CHECKING DATABASE FOR SALES FEATURES")
print("=" * 60)

# Check for required tables
tables = [
    'sales_targets', 
    'competitor_reports', 
    'surveys', 
    'survey_responses', 
    'store_visit_photos',
    'store_inventory_checks',
    'distributor_promotions',
    'customer_visits'
]
print("\n1. TABLE STATUS:")
for t in tables:
    cur.execute("""SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema='public' AND table_name=%s)""", (t,))
    exists = cur.fetchone()[0]
    if exists:
        cur.execute(f"SELECT COUNT(*) FROM {t}")
        count = cur.fetchone()[0]
        print(f"   ✅ {t}: {count} rows")
    else:
        print(f"   ❌ {t}: MISSING")

# Check customer fields
print("\n2. CUSTOMER DEBT FIELDS:")
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name='customers' AND column_name IN ('total_debt', 'credit_limit')
""")
fields = [r[0] for r in cur.fetchall()]
print(f"   Fields: {fields}")

# Check promotions structure
print("\n3. PROMOTIONS STRUCTURE:")
cur.execute("""SELECT column_name FROM information_schema.columns WHERE table_name='distributor_promotions' ORDER BY ordinal_position""")
cols = [r[0] for r in cur.fetchall()]
if cols:
    print(f"   Columns: {cols}")
else:
    print("   Table not found or empty")

# Check store_visit_photos structure
print("\n4. VISIT PHOTOS STRUCTURE:")
cur.execute("""SELECT column_name FROM information_schema.columns WHERE table_name='store_visit_photos' ORDER BY ordinal_position""")
cols = [r[0] for r in cur.fetchall()]
if cols:
    print(f"   Columns: {cols}")
else:
    print("   Table not found")

# Check store_inventory_checks structure  
print("\n5. INVENTORY CHECK STRUCTURE:")
cur.execute("""SELECT column_name FROM information_schema.columns WHERE table_name='store_inventory_checks' ORDER BY ordinal_position""")
cols = [r[0] for r in cur.fetchall()]
if cols:
    print(f"   Columns: {cols}")
else:
    print("   Table not found")

conn.close()
print("\n" + "=" * 60)
