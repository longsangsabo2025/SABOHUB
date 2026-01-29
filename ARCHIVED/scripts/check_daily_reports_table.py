#!/usr/bin/env python3
"""
Create daily_work_reports table using Supabase REST API
"""
from supabase import create_client
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

def create_table_via_api():
    """Create table by checking if it exists via REST API"""
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    print("="*80)
    print("🔍 Checking daily_work_reports table...")
    print("="*80)
    
    try:
        # Try to query the table
        result = supabase.table('daily_work_reports').select('id').limit(1).execute()
        
        print("\n✅ Table 'daily_work_reports' EXISTS!")
        print(f"   Status: Can query successfully")
        
        # Try to count records
        try:
            count_result = supabase.table('daily_work_reports').select('*', count='exact').execute()
            total = len(count_result.data) if count_result.data else 0
            print(f"   📊 Current records: {total}")
            
            if total > 0:
                print("\n   Latest records:")
                for record in count_result.data[:3]:
                    print(f"   - {record.get('employee_name', 'N/A')} | {record.get('report_date', 'N/A')} | {record.get('total_hours', 0)}h")
        except:
            print(f"   📊 Current records: 0")
        
        print("\n" + "="*80)
        print("✅ Table is ready to use!")
        print("="*80)
        return True
        
    except Exception as e:
        error_msg = str(e)
        
        if 'does not exist' in error_msg.lower() or 'not found' in error_msg.lower():
            print("\n⚠️  Table 'daily_work_reports' DOES NOT EXIST\n")
            print("📋 To create the table:")
            print("-" * 80)
            print("1. Open Supabase SQL Editor:")
            print("   https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/sql/new")
            print("\n2. Run this SQL:")
            print("-" * 80)
            print_create_table_sql()
            print("-" * 80)
            print("\n3. Or copy from file: daily_work_reports_schema.sql")
            print("="*80)
            return False
        else:
            print(f"\n❌ Error checking table: {e}")
            print("="*80)
            return False

def print_create_table_sql():
    """Print concise CREATE TABLE SQL"""
    sql = """
-- Create daily_work_reports table
CREATE TABLE daily_work_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id),
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
    CONSTRAINT unique_daily_report UNIQUE(user_id, report_date)
);

-- Enable RLS
ALTER TABLE daily_work_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own reports" ON daily_work_reports 
    FOR SELECT USING (user_id = auth.uid());
    
CREATE POLICY "Users can insert own reports" ON daily_work_reports 
    FOR INSERT WITH CHECK (user_id = auth.uid());
"""
    print(sql)

if __name__ == '__main__':
    create_table_via_api()
