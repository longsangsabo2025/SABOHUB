#!/usr/bin/env python3
"""
Add soft delete support to companies table
Migration: Add deleted_at column
"""

import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

# Initialize Supabase client
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def add_soft_delete_column():
    """Add deleted_at column to companies table"""
    
    print("=" * 60)
    print("ADDING SOFT DELETE SUPPORT TO COMPANIES TABLE")
    print("=" * 60)
    
    # Note: This requires running SQL via Supabase SQL Editor or migration
    sql = """
    -- Add deleted_at column if it doesn't exist
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'companies' AND column_name = 'deleted_at'
        ) THEN
            ALTER TABLE companies ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
            COMMENT ON COLUMN companies.deleted_at IS 'Timestamp when company was soft deleted';
            
            -- Create index for performance
            CREATE INDEX IF NOT EXISTS idx_companies_deleted_at 
                ON companies(deleted_at) 
                WHERE deleted_at IS NULL;
            
            RAISE NOTICE 'Added deleted_at column to companies table';
        ELSE
            RAISE NOTICE 'deleted_at column already exists';
        END IF;
    END $$;
    
    -- Update RLS policies to exclude deleted companies
    DROP POLICY IF EXISTS "Users can view their companies" ON companies;
    CREATE POLICY "Users can view their companies" ON companies
        FOR SELECT
        USING (
            (created_by = auth.uid() OR owner_id = auth.uid())
            AND deleted_at IS NULL
        );
    
    DROP POLICY IF EXISTS "Users can update their companies" ON companies;
    CREATE POLICY "Users can update their companies" ON companies
        FOR UPDATE
        USING (
            (created_by = auth.uid() OR owner_id = auth.uid())
            AND deleted_at IS NULL
        );
    
    DROP POLICY IF EXISTS "Users can delete their companies" ON companies;
    CREATE POLICY "Users can delete their companies" ON companies
        FOR DELETE
        USING (
            (created_by = auth.uid() OR owner_id = auth.uid())
            AND deleted_at IS NULL
        );
    """
    
    print("\n📋 SQL Migration:")
    print("-" * 60)
    print(sql)
    print("-" * 60)
    
    print("\n⚠️  MANUAL ACTION REQUIRED:")
    print("1. Go to Supabase Dashboard → SQL Editor")
    print("2. Copy and paste the SQL above")
    print("3. Click 'Run' to execute the migration")
    print("4. Verify in Table Editor that 'deleted_at' column exists")
    
    print("\n✅ After migration, the app will:")
    print("   - Soft delete companies (set deleted_at timestamp)")
    print("   - Automatically filter out deleted companies in queries")
    print("   - Preserve data for audit purposes")
    
    # Test if we can add column via RPC (usually not allowed)
    print("\n🔍 Checking current schema...")
    try:
        # Check if deleted_at already exists
        response = supabase.table('companies').select('id, deleted_at').limit(1).execute()
        print("✅ deleted_at column already exists!")
        return True
    except Exception as e:
        if 'does not exist' in str(e).lower():
            print("❌ deleted_at column does NOT exist yet")
            print("   Please run the SQL migration above manually")
            return False
        else:
            print(f"⚠️  Error checking schema: {e}")
            return False

if __name__ == "__main__":
    add_soft_delete_column()
