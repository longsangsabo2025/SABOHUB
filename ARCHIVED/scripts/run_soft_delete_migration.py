"""
Execute Soft Delete Migration for Companies Table
Adds deleted_at column and updates RLS policies
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.environ.get("SUPABASE_CONNECTION_STRING")

def run_soft_delete_migration():
    """Execute the soft delete migration"""
    print("🔄 Connecting to Supabase PostgreSQL...")
    
    try:
        conn = psycopg2.connect(conn_string)
        cur = conn.cursor()
        
        print("✅ Connected successfully!\n")
        
        # Step 1: Check if column exists
        print("📋 Step 1: Checking deleted_at column...")
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'companies' 
            AND column_name = 'deleted_at';
        """)
        
        if cur.fetchone():
            print("⚠️  Column already exists! Skipping...\n")
        else:
            print("➕ Adding deleted_at column...")
            cur.execute("""
                ALTER TABLE companies 
                ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
            """)
            conn.commit()
            print("✅ Column added!\n")
        
        # Step 2: Create index
        print("📋 Step 2: Creating index...")
        cur.execute("""
            DROP INDEX IF EXISTS idx_companies_deleted_at;
            CREATE INDEX idx_companies_deleted_at 
                ON companies(deleted_at) 
                WHERE deleted_at IS NULL;
        """)
        conn.commit()
        print("✅ Index created!\n")
        
        # Step 3: Update RLS policies
        print("📋 Step 3: Updating RLS policies...")
        
        # SELECT policy
        cur.execute("""
            DROP POLICY IF EXISTS "Users can view their companies" ON companies;
            CREATE POLICY "Users can view their companies" ON companies
                FOR SELECT
                USING (
                    created_by = auth.uid()
                    AND deleted_at IS NULL
                );
        """)
        print("✅ SELECT policy updated")
        
        # UPDATE policy
        cur.execute("""
            DROP POLICY IF EXISTS "Users can update their companies" ON companies;
            CREATE POLICY "Users can update their companies" ON companies
                FOR UPDATE
                USING (
                    created_by = auth.uid()
                    AND deleted_at IS NULL
                );
        """)
        print("✅ UPDATE policy updated")
        
        # INSERT policy
        cur.execute("""
            DROP POLICY IF EXISTS "Users can create companies" ON companies;
            CREATE POLICY "Users can create companies" ON companies
                FOR INSERT
                WITH CHECK (created_by = auth.uid());
        """)
        print("✅ INSERT policy updated")
        
        conn.commit()
        
        print("\n" + "="*60)
        print("🎉 MIGRATION COMPLETE!")
        print("="*60)
        
        # Verify
        print("\n✅ Verification:")
        cur.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns 
            WHERE table_name = 'companies' 
            AND column_name = 'deleted_at';
        """)
        col = cur.fetchone()
        if col:
            print(f"   Column: {col[0]} ({col[1]})")
        
        cur.execute("""
            SELECT COUNT(*) FROM pg_policies WHERE tablename = 'companies';
        """)
        count = cur.fetchone()[0]
        print(f"   RLS Policies: {count}")
        
        cur.close()
        conn.close()
        
        print("\n🎯 Ready to test soft delete!")
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        if 'conn' in locals():
            conn.rollback()
        raise

if __name__ == "__main__":
    run_soft_delete_migration()
