#!/usr/bin/env python3
"""List exact policy names for all broken policies (reference users but not employees)"""
import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cursor = conn.cursor()

cursor.execute("""
SELECT tablename, policyname, cmd, 
       coalesce(qual::text, '') as qual, 
       coalesce(with_check::text, '') as with_check
FROM pg_policies 
WHERE schemaname = 'public'
  AND ((coalesce(qual::text,'') LIKE '%public.users%' OR coalesce(qual::text,'') LIKE '%FROM users%')
       OR (coalesce(with_check::text,'') LIKE '%public.users%' OR coalesce(with_check::text,'') LIKE '%FROM users%'))
  AND (coalesce(qual::text,'') || coalesce(with_check::text,'')) NOT LIKE '%employees%'
ORDER BY tablename, cmd, policyname
""")
policies = cursor.fetchall()

print(f"Total broken policies: {len(policies)}\n")
for p in policies:
    tablename, policyname, cmd, qual, with_check = p
    print(f"('{tablename}', '{policyname}', '{cmd}'),")
    if qual:
        print(f"  QUAL: {qual[:500]}")
    if with_check:
        print(f"  WITH_CHECK: {with_check[:500]}")
    print()

cursor.close()
conn.close()
