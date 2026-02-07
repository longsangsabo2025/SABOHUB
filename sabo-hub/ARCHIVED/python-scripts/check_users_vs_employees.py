#!/usr/bin/env python3
"""Check employees vs users - find the mismatch"""

import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cursor = conn.cursor()

# Check employees columns
cursor.execute("""
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'employees' AND table_schema = 'public'
ORDER BY ordinal_position
""")
print('employees columns:', [c[0] for c in cursor.fetchall()])

# Check all employees
cursor.execute("""
SELECT e.id, e.company_id, e.email, e.role, e.full_name
FROM public.employees e 
ORDER BY e.role, e.email
""")
rows = cursor.fetchall()
print(f'\n=== All employees ({len(rows)}) ===')
for r in rows:
    print(f'  id={r[0]}, company={r[1]}, email={r[2]}, role={r[3]}, name={r[4]}')

# Check all users with company_id
cursor.execute("""
SELECT u.id, u.company_id, u.email, u.role
FROM public.users u 
ORDER BY u.role, u.email
""")
rows = cursor.fetchall()
print(f'\n=== All users ({len(rows)}) ===')
for r in rows:
    print(f'  id={r[0]}, company={r[1]}, email={r[2]}, role={r[3]}')

# Check: which users.id exist in employees.id?
cursor.execute("""
SELECT u.id, u.email, u.company_id as user_company, e.company_id as emp_company
FROM public.users u
LEFT JOIN public.employees e ON e.id = u.id
ORDER BY u.email
""")
rows = cursor.fetchall()
print(f'\n=== users LEFT JOIN employees on id ===')
for r in rows:
    match = 'MATCH' if r[2] == r[3] else ('MISMATCH' if r[3] else 'NO_EMP')
    print(f'  {r[1]:50} user_co={r[2]}, emp_co={r[3]} -> {match}')

# Check: which RLS policies use 'users' vs 'employees'
cursor.execute("""
SELECT tablename, policyname, cmd,
  CASE 
    WHEN coalesce(qual::text,'') || coalesce(with_check::text,'') LIKE '%public.users%' THEN 'uses:users'
    WHEN coalesce(qual::text,'') || coalesce(with_check::text,'') LIKE '%employees%' THEN 'uses:employees'
    ELSE 'other'
  END as ref
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd
""")
rows = cursor.fetchall()
print(f'\n=== All RLS policy table references ===')
for r in rows:
    print(f'  {r[0]:30} {r[2]:8} {r[1]:45} {r[3]}')

conn.close()
