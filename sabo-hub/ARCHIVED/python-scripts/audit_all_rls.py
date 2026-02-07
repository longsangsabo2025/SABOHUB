#!/usr/bin/env python3
"""
Comprehensive RLS audit:
1. Find ALL policies that reference 'users' table (potentially broken)
2. Find ALL policies that reference 'employees' table (working correctly)
3. Find ALL policies that reference neither (may use other mechanisms)
4. Show the full QUAL and WITH_CHECK for broken ones
"""

import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cursor = conn.cursor()

# Get ALL RLS policies with full details
cursor.execute("""
SELECT tablename, policyname, cmd, 
       coalesce(qual::text, '') as qual, 
       coalesce(with_check::text, '') as with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname
""")
policies = cursor.fetchall()

# Categorize
only_users = []  # References 'users' but NOT 'employees' - POTENTIALLY BROKEN
uses_employees = []  # References 'employees' - likely OK
uses_neither = []  # References neither
uses_both = []  # References both

for p in policies:
    tablename, policyname, cmd, qual, with_check = p
    combined = qual + ' ' + with_check
    
    has_users = 'public.users' in combined or 'FROM users' in combined
    has_employees = 'employees' in combined
    
    if has_users and not has_employees:
        only_users.append(p)
    elif has_employees and not has_users:
        uses_employees.append(p)
    elif has_users and has_employees:
        uses_both.append(p)
    else:
        uses_neither.append(p)

print(f"=== AUDIT SUMMARY ===")
print(f"Total policies: {len(policies)}")
print(f"  Uses ONLY 'users' table (POTENTIALLY BROKEN): {len(only_users)}")
print(f"  Uses 'employees' table: {len(uses_employees)}")
print(f"  Uses BOTH: {len(uses_both)}")
print(f"  Uses neither (other mechanisms): {len(uses_neither)}")

print(f"\n{'='*80}")
print(f"=== POTENTIALLY BROKEN POLICIES (reference 'users' only) ===")
print(f"{'='*80}")
for p in only_users:
    tablename, policyname, cmd, qual, with_check = p
    print(f"\n📍 {tablename}.{policyname} [{cmd}]")
    if qual:
        print(f"   QUAL: {qual[:300]}")
    if with_check:
        print(f"   WITH_CHECK: {with_check[:300]}")

print(f"\n{'='*80}")
print(f"=== WORKING POLICIES (reference 'employees') ===")
print(f"{'='*80}")
for p in uses_employees:
    tablename, policyname, cmd, qual, with_check = p
    print(f"  ✅ {tablename}.{policyname} [{cmd}]")

print(f"\n{'='*80}")
print(f"=== OTHER POLICIES (no user/employee reference) ===")
print(f"{'='*80}")
# Group by table
from collections import defaultdict
by_table = defaultdict(list)
for p in uses_neither:
    by_table[p[0]].append(p)
for table in sorted(by_table.keys()):
    policies_list = by_table[table]
    cmds = [p[2] for p in policies_list]
    print(f"  {table}: {', '.join(cmds)}")

# Also check which tables have RLS enabled but NO policies
cursor.execute("""
SELECT c.relname 
FROM pg_class c 
JOIN pg_namespace n ON n.oid = c.relnamespace 
WHERE n.nspname = 'public' 
  AND c.relkind = 'r' 
  AND c.relrowsecurity = true
  AND c.relname NOT IN (SELECT DISTINCT tablename FROM pg_policies WHERE schemaname = 'public')
ORDER BY c.relname
""")
no_policy_tables = cursor.fetchall()
if no_policy_tables:
    print(f"\n{'='*80}")
    print(f"=== TABLES WITH RLS ENABLED BUT NO POLICIES (ALL BLOCKED!) ===")
    print(f"{'='*80}")
    for t in no_policy_tables:
        print(f"  ⚠️  {t[0]}")

conn.close()
