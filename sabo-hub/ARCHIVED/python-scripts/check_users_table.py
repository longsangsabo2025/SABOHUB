#!/usr/bin/env python3
"""Check if users table is used correctly in RLS - check what tables hold user info"""

import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cursor = conn.cursor()

# Check if 'users' table exists
cursor.execute("""
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('users', 'employees')
ORDER BY table_name
""")
tables = cursor.fetchall()
print(f'Tables found: {[t[0] for t in tables]}')

# Check users table columns
for tbl in ['users', 'employees']:
    cursor.execute(f"""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = '{tbl}' AND table_schema = 'public'
    AND column_name IN ('id', 'company_id', 'role', 'auth_id', 'user_id', 'email')
    ORDER BY ordinal_position
    """)
    cols = cursor.fetchall()
    if cols:
        print(f'\n=== {tbl} relevant columns ===')
        for c in cols:
            print(f'  {c[0]:20} {c[1]}')
    
    # Check a couple rows
    cursor.execute(f"SELECT count(*) FROM {tbl}")
    count = cursor.fetchone()[0]
    print(f'  Row count: {count}')

# Check if 'users' table id matches auth.users id
cursor.execute("""
SELECT u.id, u.company_id, u.email 
FROM public.users u 
LIMIT 5
""")
rows = cursor.fetchall()
print(f'\n=== Sample users ===')
for r in rows:
    print(f'  id={r[0]}, company_id={r[1]}, email={r[2]}')

# Check employees table for comparison
cursor.execute("""
SELECT e.id, e.company_id, e.email, e.auth_id, e.role
FROM public.employees e 
LIMIT 5
""")
rows = cursor.fetchall()
print(f'\n=== Sample employees ===')
for r in rows:
    print(f'  id={r[0]}, company_id={r[1]}, email={r[2]}, auth_id={r[3]}, role={r[4]}')

# Check which other tables' RLS policies reference 'users' vs 'employees'
cursor.execute("""
SELECT DISTINCT tablename, policyname, 
  CASE WHEN qual::text LIKE '%users%' THEN 'users' 
       WHEN qual::text LIKE '%employees%' THEN 'employees' 
       ELSE 'other' END as ref_table
FROM pg_policies 
WHERE schemaname = 'public'
AND (qual::text LIKE '%users%' OR qual::text LIKE '%employees%')
ORDER BY ref_table, tablename
LIMIT 30
""")
refs = cursor.fetchall()
print(f'\n=== RLS table references ===')
for r in refs:
    print(f'  {r[0]:30} {r[1]:40} -> {r[2]}')

conn.close()
