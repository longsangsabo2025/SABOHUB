import psycopg2

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

# 1. Check for NULL company_id in customer_contacts
print("=== customer_contacts with NULL company_id ===")
cur.execute("SELECT id, customer_id, name, company_id FROM customer_contacts WHERE company_id IS NULL")
rows = cur.fetchall()
print(f"Found {len(rows)} rows with NULL company_id:")
for r in rows:
    print(f"  id={r[0]}, customer_id={r[1]}, name={r[2]}, company_id={r[3]}")

# 2. Check all company_ids
print("\n=== company_id distribution in customer_contacts ===")
cur.execute("SELECT company_id, COUNT(*) FROM customer_contacts GROUP BY company_id")
for r in cur.fetchall():
    print(f"  company_id={r[0]}: {r[1]} rows")

# 3. Check customer_addresses NULL company_id
print("\n=== customer_addresses with NULL company_id ===")
cur.execute("SELECT id, customer_id, company_id FROM customer_addresses WHERE company_id IS NULL")
rows = cur.fetchall()
print(f"Found {len(rows)} rows with NULL company_id")

# 4. Check what happens with RLS - show the actual policies
print("\n=== RLS Policies on customer_contacts ===")
cur.execute("""
    SELECT polname, polcmd, pg_get_expr(polqual, polrelid) as using_expr, 
           pg_get_expr(polwithcheck, polrelid) as check_expr
    FROM pg_policy 
    WHERE polrelid = 'customer_contacts'::regclass
""")
for r in cur.fetchall():
    print(f"  Policy: {r[0]}")
    print(f"    Command: {r[1]}")
    print(f"    USING: {r[2]}")
    print(f"    CHECK: {r[3]}")

# 5. Check if auth.uid() function works - test with employees
print("\n=== auth.uid() test ===")
try:
    cur.execute("SELECT auth.uid()")
    print(f"auth.uid() = {cur.fetchone()[0]}")
except Exception as e:
    print(f"auth.uid() error: {e}")
    conn.rollback()

# 6. Check the NOT NULL constraint on company_id
print("\n=== customer_contacts column info ===")
cur.execute("""
    SELECT column_name, is_nullable, column_default, data_type
    FROM information_schema.columns 
    WHERE table_name = 'customer_contacts' AND column_name = 'company_id'
""")
for r in cur.fetchall():
    print(f"  {r[0]}: nullable={r[1]}, default={r[2]}, type={r[3]}")

# 7. Check if there's a NOT NULL violation happening
print("\n=== customer_contacts column constraints ===")
cur.execute("""
    SELECT column_name, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'customer_contacts'
    ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(f"  {r[0]}: nullable={r[1]}")

# 8. Check how the Supabase client authenticates (what JWT claim is used)
print("\n=== Check if anon key works vs service role ===")
print("Note: Pooler connection bypasses RLS (superuser)")
print("The error is from Supabase JS client using anon key + JWT")

# 9. Check if the RLS policies reference auth.uid() correctly  
print("\n=== Verify employees table has a user with auth matching ===")
cur.execute("SELECT id, name, role, company_id FROM employees WHERE is_active = true LIMIT 5")
for r in cur.fetchall():
    print(f"  id={r[0]}, name={r[1]}, role={r[2]}, company_id={r[3]}")

# 10. Check if there's a trigger blocking inserts
print("\n=== Triggers on customer_contacts ===")
cur.execute("""
    SELECT trigger_name, event_manipulation, action_statement
    FROM information_schema.triggers
    WHERE event_object_table = 'customer_contacts'
""")
rows = cur.fetchall()
if rows:
    for r in rows:
        print(f"  {r[0]}: {r[1]} -> {r[2]}")
else:
    print("  No triggers found")

conn.close()
