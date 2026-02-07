#!/usr/bin/env python3
"""Check customer_addresses table schema and RLS policies"""

import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cursor = conn.cursor()

# Check if table exists and its columns
cursor.execute("""
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'customer_addresses' AND table_schema = 'public'
ORDER BY ordinal_position
""")
cols = cursor.fetchall()
if cols:
    print('=== customer_addresses columns ===')
    for c in cols:
        print(f'  {c[0]:30} {c[1]:20} nullable={c[2]}')
else:
    print('TABLE customer_addresses NOT FOUND')

# Check if RLS is enabled
cursor.execute("""
SELECT relrowsecurity, relforcerowsecurity 
FROM pg_class WHERE relname = 'customer_addresses'
""")
rls = cursor.fetchone()
if rls:
    print(f'\nRLS enabled: {rls[0]}, forced: {rls[1]}')

# Check existing RLS policies
cursor.execute("""
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'customer_addresses'
""")
policies = cursor.fetchall()
print(f'\n=== RLS policies ({len(policies)}) ===')
for p in policies:
    print(f'  Policy: {p[0]}')
    print(f'    CMD: {p[1]}')
    qual_str = str(p[2])[:200] if p[2] else 'None'
    check_str = str(p[3])[:200] if p[3] else 'None'
    print(f'    QUAL: {qual_str}')
    print(f'    WITH_CHECK: {check_str}')

conn.close()
print('\nDone.')
