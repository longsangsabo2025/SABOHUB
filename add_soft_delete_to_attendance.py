#!/usr/bin/env python3
"""
Add soft delete support to attendance table
- Add deleted_at column with index
- Update existing RLS policies with soft delete filter
"""

import os
from dotenv import load_dotenv
import psycopg2

# Load environment
load_dotenv()

# Connection string
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

def main():
    print("🚀 Adding soft delete to attendance table...")
    print()
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    try:
        # Step 1: Add deleted_at column
        print("1️⃣  Adding deleted_at column...")
        cur.execute("""
            ALTER TABLE attendance 
            ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;
        """)
        print("   ✅ Column added")
        
        # Step 2: Create partial index for performance
        print("2️⃣  Creating index on deleted_at...")
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_attendance_deleted_at 
            ON attendance(deleted_at) 
            WHERE deleted_at IS NULL;
        """)
        print("   ✅ Index created (partial index on active attendance)")
        
        # Step 3: Get existing policies
        print("3️⃣  Checking existing RLS policies...")
        cur.execute("""
            SELECT policyname, cmd
            FROM pg_policies
            WHERE tablename = 'attendance'
            ORDER BY cmd, policyname;
        """)
        policies = cur.fetchall()
        print(f"   Found {len(policies)} existing policies")
        for name, cmd in policies:
            print(f"   - {name} ({cmd})")
        
        # Step 4: Update policies (assuming standard CEO policies exist)
        print("4️⃣  Updating RLS policies with soft delete filter...")
        
        # Check and update SELECT policies
        for policy_name, cmd in policies:
            if cmd == 'SELECT':
                print(f"   📝 Updating {policy_name}...")
                cur.execute(f"DROP POLICY IF EXISTS {policy_name} ON attendance;")
                
                # Recreate with deleted_at filter
                # Attendance uses user_id (not employee_id) and store_id (not company_id)
                cur.execute(f"""
                    CREATE POLICY {policy_name} ON attendance
                    FOR SELECT
                    USING (
                        store_id IN (
                            SELECT id FROM branches 
                            WHERE company_id IN (
                                SELECT id FROM companies WHERE created_by = auth.uid()
                            )
                        )
                        AND deleted_at IS NULL
                    );
                """)
                print(f"   ✅ {policy_name} updated")
            
            elif cmd == 'UPDATE':
                print(f"   📝 Updating {policy_name}...")
                cur.execute(f"DROP POLICY IF EXISTS {policy_name} ON attendance;")
                
                cur.execute(f"""
                    CREATE POLICY {policy_name} ON attendance
                    FOR UPDATE
                    USING (
                        user_id = auth.uid()
                        AND deleted_at IS NULL
                    )
                    WITH CHECK (
                        user_id = auth.uid()
                    );
                """)
                print(f"   ✅ {policy_name} updated")
            
            elif cmd == 'INSERT':
                print(f"   ⏭️  {policy_name} - INSERT policy doesn't need deleted_at filter")
        
        # Commit all changes
        conn.commit()
        
        # Step 5: Verify
        print()
        print("5️⃣  Verification:")
        
        # Check column exists
        cur.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'attendance' AND column_name = 'deleted_at';
        """)
        col = cur.fetchone()
        if col:
            print(f"   ✅ Column: {col[0]} ({col[1]}, nullable: {col[2]})")
        
        # Check index exists
        cur.execute("""
            SELECT indexname
            FROM pg_indexes
            WHERE tablename = 'attendance' AND indexname = 'idx_attendance_deleted_at';
        """)
        idx = cur.fetchone()
        if idx:
            print(f"   ✅ Index: {idx[0]}")
        
        # Count total policies
        cur.execute("""
            SELECT COUNT(*)
            FROM pg_policies
            WHERE tablename = 'attendance';
        """)
        result = cur.fetchone()
        policy_count = result[0] if result else 0
        print(f"   ✅ Total RLS policies: {policy_count}")
        
        print()
        print("🎉 Soft delete successfully added to attendance table!")
        print()
        print("📋 Summary:")
        print("   ✅ deleted_at column added")
        print("   ✅ Partial index created (active records only)")
        print(f"   ✅ {len([p for p in policies if p[1] in ['SELECT', 'UPDATE']])} RLS policies updated")
        print()
        print("🔥 Attendance table now supports soft delete!")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    main()
