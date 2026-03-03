import psycopg2

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

# 1. Check which tables have RLS enabled
print("=== Tables with RLS enabled ===")
cur.execute("""
    SELECT schemaname, tablename, rowsecurity 
    FROM pg_tables 
    WHERE schemaname = 'public' AND rowsecurity = true
    ORDER BY tablename
""")
rows = cur.fetchall()
print(f"Found {len(rows)} tables with RLS enabled:")
for r in rows:
    print(f"  {r[1]}")

# 2. Disable RLS on customer_contacts and customer_addresses
print("\n=== Disabling RLS on customer_contacts ===")
try:
    cur.execute("ALTER TABLE customer_contacts DISABLE ROW LEVEL SECURITY")
    conn.commit()
    print("  ✅ RLS disabled on customer_contacts")
except Exception as e:
    print(f"  ❌ Error: {e}")
    conn.rollback()

print("\n=== Disabling RLS on customer_addresses ===")
try:
    cur.execute("ALTER TABLE customer_addresses DISABLE ROW LEVEL SECURITY")
    conn.commit()
    print("  ✅ RLS disabled on customer_addresses")
except Exception as e:
    print(f"  ❌ Error: {e}")
    conn.rollback()

# 3. Also backfill the NULL company_id row
print("\n=== Backfilling NULL company_id in customer_contacts ===")
cur.execute("""
    UPDATE customer_contacts cc
    SET company_id = c.company_id
    FROM customers c
    WHERE cc.customer_id = c.id AND cc.company_id IS NULL
""")
updated = cur.rowcount
conn.commit()
print(f"  Updated {updated} rows")

# 4. Verify
print("\n=== Verification ===")
cur.execute("SELECT rowsecurity FROM pg_tables WHERE tablename = 'customer_contacts'")
r = cur.fetchone()
print(f"  customer_contacts RLS enabled: {r[0]}")

cur.execute("SELECT rowsecurity FROM pg_tables WHERE tablename = 'customer_addresses'")
r = cur.fetchone()
print(f"  customer_addresses RLS enabled: {r[0]}")

cur.execute("SELECT COUNT(*) FROM customer_contacts WHERE company_id IS NULL")
r = cur.fetchone()
print(f"  customer_contacts with NULL company_id: {r[0]}")

conn.close()
print("\n✅ Done!")
