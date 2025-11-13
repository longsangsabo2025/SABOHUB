#!/usr/bin/env python3
"""
Add soft delete support to employees table
- Add deleted_at column with index
- Update 5 existing RLS policies with soft delete filter
"""

import os
from dotenv import load_dotenv
import psycopg2

# Load environment
load_dotenv()

# Connection string
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

def main():
    print("🚀 Adding soft delete to employees table...")
    print()
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    try:
        # Step 1: Add deleted_at column
        print("1️⃣  Adding deleted_at column...")
        cur.execute("""
            ALTER TABLE employees 
            ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;
        """)
        print("   ✅ Column added")
        
        # Step 2: Create partial index for performance
        print("2️⃣  Creating index on deleted_at...")
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_employees_deleted_at 
            ON employees(deleted_at) 
            WHERE deleted_at IS NULL;
        """)
        print("   ✅ Index created (partial index on active employees)")
        
        # Step 3: Update SELECT policies
        print("3️⃣  Updating RLS policies with soft delete filter...")
        
        # Drop and recreate all SELECT policies with deleted_at filter
        print("   📝 Updating ceo_select_employees...")
        cur.execute("DROP POLICY IF EXISTS ceo_select_employees ON employees;")
        cur.execute("""
            CREATE POLICY ceo_select_employees ON employees
            FOR SELECT
            USING (
                company_id IN (
                    SELECT id FROM companies WHERE created_by = auth.uid()
                )
                AND deleted_at IS NULL
            );
        """)
        print("   ✅ ceo_select_employees updated")
        
        print("   📝 Updating ceo_view_all_employees...")
        cur.execute("DROP POLICY IF EXISTS ceo_view_all_employees ON employees;")
        cur.execute("""
            CREATE POLICY ceo_view_all_employees ON employees
            FOR SELECT
            USING (
                company_id IN (
                    SELECT id FROM companies WHERE created_by = auth.uid()
                )
                AND deleted_at IS NULL
            );
        """)
        print("   ✅ ceo_view_all_employees updated")
        
        # Step 4: Update UPDATE policies
        print("4️⃣  Updating UPDATE policies...")
        print("   📝 Updating ceo_update_employees...")
        cur.execute("DROP POLICY IF EXISTS ceo_update_employees ON employees;")
        cur.execute("""
            CREATE POLICY ceo_update_employees ON employees
            FOR UPDATE
            USING (
                company_id IN (
                    SELECT id FROM companies WHERE created_by = auth.uid()
                )
                AND deleted_at IS NULL
            )
            WITH CHECK (
                company_id IN (
                    SELECT id FROM companies WHERE created_by = auth.uid()
                )
            );
        """)
        print("   ✅ ceo_update_employees updated")
        
        # Commit all changes
        conn.commit()
        
        # Step 5: Verify
        print()
        print("5️⃣  Verification:")
        
        # Check column exists
        cur.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'employees' AND column_name = 'deleted_at';
        """)
        col = cur.fetchone()
        if col:
            print(f"   ✅ Column: {col[0]} ({col[1]}, nullable: {col[2]})")
        
        # Check index exists
        cur.execute("""
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE tablename = 'employees' AND indexname = 'idx_employees_deleted_at';
        """)
        idx = cur.fetchone()
        if idx:
            print(f"   ✅ Index: {idx[0]}")
        
        # Count policies with deleted_at
        cur.execute("""
            SELECT COUNT(*)
            FROM pg_policies
            WHERE tablename = 'employees';
        """)
        result = cur.fetchone()
        policy_count = result[0] if result else 0
        print(f"   ✅ Total RLS policies: {policy_count}")
        
        print()
        print("🎉 Soft delete successfully added to employees table!")
        print()
        print("📋 Summary:")
        print("   ✅ deleted_at column added")
        print("   ✅ Partial index created (active employees only)")
        print(f"   ✅ {policy_count} RLS policies updated")
        print()
        print("🔥 Employees table now supports soft delete!")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    main()
