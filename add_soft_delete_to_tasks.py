#!/usr/bin/env python3
"""
Add soft delete support to tasks table
- Add deleted_at column with index
- Update 3 existing RLS policies with soft delete filter
"""

import os
from dotenv import load_dotenv
import psycopg2

# Load environment
load_dotenv()

# Connection string
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

def main():
    print("🚀 Adding soft delete to tasks table...")
    print()
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    try:
        # Step 1: Add deleted_at column
        print("1️⃣  Adding deleted_at column...")
        cur.execute("""
            ALTER TABLE tasks 
            ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;
        """)
        print("   ✅ Column added")
        
        # Step 2: Create partial index for performance
        print("2️⃣  Creating index on deleted_at...")
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_tasks_deleted_at 
            ON tasks(deleted_at) 
            WHERE deleted_at IS NULL;
        """)
        print("   ✅ Index created (partial index on active tasks)")
        
        # Step 3: Update SELECT policy
        print("3️⃣  Updating RLS policies with soft delete filter...")
        
        print("   📝 Updating ceo_tasks_select...")
        cur.execute("DROP POLICY IF EXISTS ceo_tasks_select ON tasks;")
        cur.execute("""
            CREATE POLICY ceo_tasks_select ON tasks
            FOR SELECT
            USING (
                (
                    company_id IN (
                        SELECT id FROM companies WHERE created_by = auth.uid()
                    )
                    OR assigned_to IN (
                        SELECT id FROM employees 
                        WHERE company_id IN (
                            SELECT id FROM companies WHERE created_by = auth.uid()
                        )
                    )
                )
                AND deleted_at IS NULL
            );
        """)
        print("   ✅ ceo_tasks_select updated")
        
        # Step 4: Update INSERT policy
        print("4️⃣  Updating INSERT policy...")
        print("   📝 Updating ceo_tasks_insert...")
        cur.execute("DROP POLICY IF EXISTS ceo_tasks_insert ON tasks;")
        cur.execute("""
            CREATE POLICY ceo_tasks_insert ON tasks
            FOR INSERT
            WITH CHECK (
                company_id IN (
                    SELECT id FROM companies WHERE created_by = auth.uid()
                )
            );
        """)
        print("   ✅ ceo_tasks_insert updated (no deleted_at needed for INSERT)")
        
        # Step 5: Update UPDATE policy
        print("5️⃣  Updating UPDATE policy...")
        print("   📝 Updating ceo_tasks_update...")
        cur.execute("DROP POLICY IF EXISTS ceo_tasks_update ON tasks;")
        cur.execute("""
            CREATE POLICY ceo_tasks_update ON tasks
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
        print("   ✅ ceo_tasks_update updated")
        
        # Commit all changes
        conn.commit()
        
        # Step 6: Verify
        print()
        print("6️⃣  Verification:")
        
        # Check column exists
        cur.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'tasks' AND column_name = 'deleted_at';
        """)
        col = cur.fetchone()
        if col:
            print(f"   ✅ Column: {col[0]} ({col[1]}, nullable: {col[2]})")
        
        # Check index exists
        cur.execute("""
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE tablename = 'tasks' AND indexname = 'idx_tasks_deleted_at';
        """)
        idx = cur.fetchone()
        if idx:
            print(f"   ✅ Index: {idx[0]}")
        
        # Count total policies
        cur.execute("""
            SELECT COUNT(*)
            FROM pg_policies
            WHERE tablename = 'tasks';
        """)
        result = cur.fetchone()
        policy_count = result[0] if result else 0
        print(f"   ✅ Total RLS policies: {policy_count}")
        
        print()
        print("🎉 Soft delete successfully added to tasks table!")
        print()
        print("📋 Summary:")
        print("   ✅ deleted_at column added")
        print("   ✅ Partial index created (active tasks only)")
        print("   ✅ 3 RLS policies updated (SELECT, UPDATE)")
        print("   ✅ INSERT policy kept unchanged (no filter needed)")
        print()
        print("🔥 Tasks table now supports soft delete!")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    main()
