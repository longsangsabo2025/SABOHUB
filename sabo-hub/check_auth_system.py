import psycopg2

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

# 1. Check employee_login RPC source
print("=== employee_login RPC ===")
cur.execute("""
    SELECT routine_name, routine_definition 
    FROM information_schema.routines 
    WHERE routine_name = 'employee_login' AND routine_schema = 'public'
""")
rows = cur.fetchall()
for r in rows:
    print(r[1])

# 2. Check what roles exist in employees table
print("\n=== Roles in employees table ===")
cur.execute("SELECT role, COUNT(*) FROM employees GROUP BY role ORDER BY role")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

# 3. Check if CEO exists in employees table
print("\n=== CEO in employees ===")
cur.execute("SELECT id, full_name, email, role, username, company_id FROM employees WHERE role = 'ceo'")
for r in cur.fetchall():
    print(f"  id={r[0]}, name={r[1]}, email={r[2]}, role={r[3]}, username={r[4]}, company_id={r[5]}")

# 4. Check users table
print("\n=== users table ===")
try:
    cur.execute("SELECT id, full_name, email, role FROM users LIMIT 5")
    for r in cur.fetchall():
        print(f"  id={r[0]}, name={r[1]}, email={r[2]}, role={r[3]}")
except Exception as e:
    print(f"  Error: {e}")
    conn.rollback()

# 5. Check auth.users (Supabase auth)
print("\n=== auth.users ===")
try:
    cur.execute("SELECT id, email FROM auth.users LIMIT 5")
    for r in cur.fetchall():
        print(f"  id={r[0]}, email={r[1]}")
except Exception as e:
    print(f"  Error: {e}")
    conn.rollback()

# 6. Check if employees have auth_user_id (linking to auth.users)
print("\n=== employees with auth_user_id ===")
cur.execute("SELECT id, full_name, role, auth_user_id FROM employees WHERE auth_user_id IS NOT NULL")
for r in cur.fetchall():
    print(f"  id={r[0]}, name={r[1]}, role={r[2]}, auth_user_id={r[3]}")

conn.close()
