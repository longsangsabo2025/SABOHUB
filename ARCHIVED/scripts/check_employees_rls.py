#!/usr/bin/env python3
"""
Check RLS policies on employees table for CEO access
"""

import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.environ.get("SUPABASE_CONNECTION_STRING")

print("=" * 80)
print("🔐 CHECKING RLS POLICIES ON EMPLOYEES TABLE")
print("=" * 80)

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    
    # Check if RLS is enabled
    print("\n1️⃣ RLS Status:")
    print("-" * 80)
    cursor.execute("""
        SELECT tablename, rowsecurity 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'employees';
    """)
    
    result = cursor.fetchone()
    if result:
        rls_enabled = result[1]
        print(f"Table: employees")
        print(f"RLS Enabled: {rls_enabled}")
    
    # Check policies
    print("\n2️⃣ Current Policies:")
    print("-" * 80)
    cursor.execute("""
        SELECT policyname, cmd, permissive, roles
        FROM pg_policies 
        WHERE tablename = 'employees'
        ORDER BY policyname;
    """)
    
    policies = cursor.fetchall()
    if policies:
        print(f"Found {len(policies)} policies:\n")
        for p in policies:
            print(f"  📋 {p[0]}")
            print(f"     Command: {p[1]}")
            print(f"     Permissive: {p[2]}")
            print(f"     Roles: {p[3]}")
            print()
    else:
        print("⚠️  No policies found!")
    
    # Check for CEO-specific SELECT policy
    print("\n3️⃣ CEO SELECT Policy Check:")
    print("-" * 80)
    cursor.execute("""
        SELECT policyname, qual
        FROM pg_policies 
        WHERE tablename = 'employees'
        AND cmd = 'SELECT'
        AND (policyname ILIKE '%ceo%' OR qual ILIKE '%ceo%');
    """)
    
    ceo_policies = cursor.fetchall()
    if ceo_policies:
        print(f"✅ Found {len(ceo_policies)} CEO-related SELECT policies:\n")
        for p in ceo_policies:
            print(f"  - {p[0]}")
            print(f"    Condition: {p[1][:100]}...")
            print()
    else:
        print("❌ NO CEO-specific SELECT policy found!")
        print("\n🔧 This might be why CEO can't see employees!")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 80)
    print("💡 RECOMMENDATION")
    print("=" * 80)
    
    if not ceo_policies:
        print("""
❌ PROBLEM: No CEO SELECT policy on employees table

🔧 SOLUTION: Run this SQL to fix:

CREATE POLICY "ceo_view_all_employees" 
ON employees
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'CEO'
  )
);

This will allow CEO to SELECT all employees.
        """)
    else:
        print("✅ CEO SELECT policy exists - check browser console for other errors")

except Exception as e:
    print(f"\n❌ ERROR: {e}")
