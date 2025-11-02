#!/usr/bin/env python3
"""Check and fix RLS policies for companies table"""

import os
from dotenv import load_dotenv
import psycopg2
from pathlib import Path

# Load environment
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
if not conn_str:
    print("Error: SUPABASE_CONNECTION_STRING not found")
    exit(1)

if '?' in conn_str:
    conn_str = conn_str.split('?')[0]

print("Checking RLS policies...")
print("=" * 60)

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Check current policies
    cur.execute("""
        SELECT policyname, cmd, qual::text, with_check::text
        FROM pg_policies
        WHERE tablename = 'companies'
        ORDER BY policyname;
    """)
    
    policies = cur.fetchall()
    print(f"\nCurrent policies ({len(policies)}):")
    for p in policies:
        print(f"  - {p[0]}: {p[1]}")
        print(f"    USING: {p[2]}")
        print(f"    WITH CHECK: {p[3]}\n")
    
    # Drop all existing policies
    print("Dropping old policies...")
    for p in policies:
        cur.execute(f"DROP POLICY IF EXISTS {p[0]} ON companies;")
    
    # Create new simplified policies
    print("\nCreating new policies...")
    
    # CEO can do everything
    cur.execute("""
        CREATE POLICY "companies_ceo_all"
        ON companies
        FOR ALL
        TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM users
                WHERE users.id = auth.uid()
                AND users.role = 'ceo'
            )
        )
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM users
                WHERE users.id = auth.uid()
                AND users.role = 'ceo'
            )
        );
    """)
    print("  ✓ companies_ceo_all")
    
    # Manager can view their company
    cur.execute("""
        CREATE POLICY "companies_manager_select"
        ON companies
        FOR SELECT
        TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM users
                WHERE users.id = auth.uid()
                AND users.role = 'manager'
                AND users.company_id = companies.id
            )
        );
    """)
    print("  ✓ companies_manager_select")
    
    # Employee can view their company
    cur.execute("""
        CREATE POLICY "companies_employee_select"
        ON companies
        FOR SELECT
        TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM users
                WHERE users.id = auth.uid()
                AND users.role = 'employee'
                AND users.company_id = companies.id
            )
        );
    """)
    print("  ✓ companies_employee_select")
    
    conn.commit()
    
    # Verify new policies
    cur.execute("""
        SELECT policyname, cmd
        FROM pg_policies
        WHERE tablename = 'companies'
        ORDER BY policyname;
    """)
    
    new_policies = cur.fetchall()
    print(f"\nNew policies created ({len(new_policies)}):")
    for p in new_policies:
        print(f"  ✓ {p[0]}: {p[1]}")
    
    print("\n✅ RLS policies updated successfully!")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
