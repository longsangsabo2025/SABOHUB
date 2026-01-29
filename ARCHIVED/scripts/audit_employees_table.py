"""
Employees Table Schema Audit
Check structure, columns, constraints, and RLS policies
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn_string = os.environ.get("SUPABASE_CONNECTION_STRING")

def audit_employees_schema():
    """Audit employees table structure"""
    print("="*60)
    print("📋 EMPLOYEES TABLE SCHEMA AUDIT")
    print("="*60)
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # 1. List all columns
    print("\n1️⃣  COLUMNS:")
    print("-"*60)
    cur.execute("""
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns 
        WHERE table_name = 'employees' 
        AND table_schema = 'public'
        ORDER BY ordinal_position;
    """)
    
    columns = cur.fetchall()
    print(f"Found {len(columns)} columns:\n")
    
    for col in columns:
        nullable = "NULL" if col[2] == 'YES' else "NOT NULL"
        default = f"DEFAULT {col[3]}" if col[3] else ""
        print(f"   {col[0]:<20} {col[1]:<20} {nullable:<10} {default}")
    
    # 2. Check foreign keys
    print("\n2️⃣  FOREIGN KEYS:")
    print("-"*60)
    cur.execute("""
        SELECT
            tc.constraint_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'employees';
    """)
    
    fks = cur.fetchall()
    if fks:
        print(f"Found {len(fks)} foreign keys:\n")
        for fk in fks:
            print(f"   {fk[0]}")
            print(f"      {fk[1]} → {fk[2]}.{fk[3]}")
    else:
        print("⚠️  No foreign keys found")
    
    # 3. Check indexes
    print("\n3️⃣  INDEXES:")
    print("-"*60)
    cur.execute("""
        SELECT
            indexname,
            indexdef
        FROM pg_indexes
        WHERE tablename = 'employees'
        AND schemaname = 'public';
    """)
    
    indexes = cur.fetchall()
    if indexes:
        print(f"Found {len(indexes)} indexes:\n")
        for idx in indexes:
            print(f"   {idx[0]}")
    else:
        print("⚠️  No indexes found")
    
    # 4. Check RLS status
    print("\n4️⃣  ROW LEVEL SECURITY:")
    print("-"*60)
    cur.execute("""
        SELECT rowsecurity
        FROM pg_tables
        WHERE tablename = 'employees'
        AND schemaname = 'public';
    """)
    
    rls = cur.fetchone()
    if rls and rls[0]:
        print("✅ RLS is ENABLED")
    else:
        print("❌ RLS is DISABLED")
    
    # 5. List RLS policies
    print("\n5️⃣  RLS POLICIES:")
    print("-"*60)
    cur.execute("""
        SELECT
            policyname,
            cmd,
            qual,
            with_check
        FROM pg_policies
        WHERE tablename = 'employees';
    """)
    
    policies = cur.fetchall()
    if policies:
        print(f"Found {len(policies)} policies:\n")
        for policy in policies:
            print(f"   📜 {policy[0]}")
            print(f"      Command: {policy[1]}")
            if policy[2]:
                print(f"      USING: {policy[2]}")
            if policy[3]:
                print(f"      WITH CHECK: {policy[3]}")
            print()
    else:
        print("⚠️  No RLS policies found")
    
    # 6. Check for user_id column
    print("\n6️⃣  CRITICAL COLUMN CHECK:")
    print("-"*60)
    
    column_names = [col[0] for col in columns]
    
    checks = [
        ('user_id', 'Link to auth.users'),
        ('company_id', 'Company association'),
        ('role', 'Employee role (manager, staff, etc)'),
        ('deleted_at', 'Soft delete support'),
    ]
    
    for col_name, description in checks:
        if col_name in column_names:
            print(f"   ✅ {col_name:<20} - {description}")
        else:
            print(f"   ❌ {col_name:<20} - {description} (MISSING)")
    
    # 7. Sample data
    print("\n7️⃣  SAMPLE DATA (First 3 rows):")
    print("-"*60)
    cur.execute("""
        SELECT id, full_name, company_id, role
        FROM employees
        LIMIT 3;
    """)
    
    samples = cur.fetchall()
    if samples:
        for emp in samples:
            print(f"   ID: {emp[0][:8]}... | {emp[1]} | Role: {emp[3]}")
    else:
        print("⚠️  No employee data found")
    
    cur.close()
    conn.close()
    
    print("\n" + "="*60)
    print("✅ AUDIT COMPLETE")
    print("="*60)

if __name__ == "__main__":
    audit_employees_schema()
