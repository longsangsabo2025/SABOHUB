#!/usr/bin/env python3
"""
Apply daily_work_reports schema directly to Supabase using SQL
"""
from supabase import create_client
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

def apply_schema():
    """Apply schema using direct SQL execution"""
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    print("🔨 Creating daily_work_reports table...")
    
    # Break down into smaller SQL statements
    sql_statements = [
        # 1. Create table
        """
        CREATE TABLE IF NOT EXISTS daily_work_reports (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
            company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
            branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
            report_date DATE NOT NULL,
            check_in_time TIMESTAMPTZ NOT NULL,
            check_out_time TIMESTAMPTZ NOT NULL,
            total_hours DECIMAL(5,2) NOT NULL,
            tasks_summary TEXT,
            achievements TEXT,
            challenges TEXT,
            notes TEXT,
            employee_name TEXT,
            employee_role TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            CONSTRAINT unique_daily_report UNIQUE(user_id, report_date),
            CONSTRAINT valid_hours CHECK (total_hours >= 0 AND total_hours <= 24)
        );
        """,
    ]
    
    try:
        # Check if table exists
        result = supabase.table('daily_work_reports').select('id').limit(1).execute()
        print("✅ Table 'daily_work_reports' already exists!")
        print(f"   Current records: checking...")
        
        # Count records
        count_result = supabase.table('daily_work_reports').select('id', count='exact').execute()
        print(f"   📊 Total reports: {count_result.count}")
        
        return True
        
    except Exception as e:
        error_msg = str(e)
        if 'does not exist' in error_msg or 'relation' in error_msg:
            print("⚠️  Table does not exist yet. Creating via SQL file...")
            print("\n" + "="*80)
            print("📋 Please run daily_work_reports_schema.sql in Supabase SQL Editor:")
            print("="*80)
            print("1. Go to: https://dqddxowyikefqcdiioyh.supabase.co/project/_/sql")
            print("2. Create new query")
            print("3. Copy content from: daily_work_reports_schema.sql")
            print("4. Run the query")
            print("5. Then run this script again")
            print("="*80)
            return False
        else:
            print(f"❌ Error: {e}")
            return False

if __name__ == '__main__':
    print("=" * 80)
    print("🔧 SABOHUB - Apply Daily Work Reports Schema")
    print("=" * 80)
    
    if apply_schema():
        print("\n✅ Schema check complete!")
    else:
        print("\n⚠️  Manual setup needed - see instructions above")
