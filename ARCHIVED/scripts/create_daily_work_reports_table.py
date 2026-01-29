#!/usr/bin/env python3
"""
Create daily_work_reports table in Supabase
"""
from supabase import create_client
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

def create_daily_work_reports_table():
    """Create daily_work_reports table with proper schema and RLS"""
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    print("🔨 Creating daily_work_reports table...")
    
    # SQL to create table
    create_table_sql = """
    -- Create daily_work_reports table
    CREATE TABLE IF NOT EXISTS daily_work_reports (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
        branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
        
        -- Report metadata
        report_date DATE NOT NULL,
        
        -- Time tracking from attendance
        check_in_time TIMESTAMPTZ NOT NULL,
        check_out_time TIMESTAMPTZ NOT NULL,
        total_hours DECIMAL(5,2) NOT NULL,
        
        -- Report content
        tasks_summary TEXT,
        achievements TEXT,
        challenges TEXT,
        notes TEXT,
        
        -- Employee info (denormalized for performance)
        employee_name TEXT,
        employee_role TEXT,
        
        -- Timestamps
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        
        -- Constraints
        CONSTRAINT unique_daily_report UNIQUE(user_id, report_date),
        CONSTRAINT valid_hours CHECK (total_hours >= 0 AND total_hours <= 24)
    );
    
    -- Create indexes for performance
    CREATE INDEX IF NOT EXISTS idx_daily_reports_user_id ON daily_work_reports(user_id);
    CREATE INDEX IF NOT EXISTS idx_daily_reports_company_id ON daily_work_reports(company_id);
    CREATE INDEX IF NOT EXISTS idx_daily_reports_branch_id ON daily_work_reports(branch_id);
    CREATE INDEX IF NOT EXISTS idx_daily_reports_date ON daily_work_reports(report_date);
    CREATE INDEX IF NOT EXISTS idx_daily_reports_created_at ON daily_work_reports(created_at);
    
    -- Enable Row Level Security
    ALTER TABLE daily_work_reports ENABLE ROW LEVEL SECURITY;
    
    -- Drop existing policies if any
    DROP POLICY IF EXISTS "CEO can view all reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "Manager can view branch reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "Staff can view own reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "CEO can insert reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "Manager can insert reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "Staff can insert own reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "CEO can update all reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "Manager can update branch reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "Staff can update own reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "CEO can delete all reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "Manager can delete branch reports" ON daily_work_reports;
    DROP POLICY IF EXISTS "Staff can delete own reports" ON daily_work_reports;
    
    -- RLS Policy: CEO can view all reports in their company
    CREATE POLICY "CEO can view all reports"
    ON daily_work_reports FOR SELECT
    USING (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid()
        )
    );
    
    -- RLS Policy: Manager can view reports from their branch
    CREATE POLICY "Manager can view branch reports"
    ON daily_work_reports FOR SELECT
    USING (
        branch_id IN (
            SELECT branch_id FROM employees 
            WHERE id = auth.uid() AND role = 'MANAGER'
        )
    );
    
    -- RLS Policy: Staff can view their own reports
    CREATE POLICY "Staff can view own reports"
    ON daily_work_reports FOR SELECT
    USING (user_id = auth.uid());
    
    -- RLS Policy: CEO can insert any report in their company
    CREATE POLICY "CEO can insert reports"
    ON daily_work_reports FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid()
        )
    );
    
    -- RLS Policy: Manager can insert reports for their branch
    CREATE POLICY "Manager can insert reports"
    ON daily_work_reports FOR INSERT
    WITH CHECK (
        branch_id IN (
            SELECT branch_id FROM employees 
            WHERE id = auth.uid() AND role = 'MANAGER'
        )
    );
    
    -- RLS Policy: Staff can insert their own reports
    CREATE POLICY "Staff can insert own reports"
    ON daily_work_reports FOR INSERT
    WITH CHECK (user_id = auth.uid());
    
    -- RLS Policy: CEO can update all reports
    CREATE POLICY "CEO can update all reports"
    ON daily_work_reports FOR UPDATE
    USING (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid()
        )
    );
    
    -- RLS Policy: Manager can update branch reports
    CREATE POLICY "Manager can update branch reports"
    ON daily_work_reports FOR UPDATE
    USING (
        branch_id IN (
            SELECT branch_id FROM employees 
            WHERE id = auth.uid() AND role = 'MANAGER'
        )
    );
    
    -- RLS Policy: Staff can update own reports (within same day)
    CREATE POLICY "Staff can update own reports"
    ON daily_work_reports FOR UPDATE
    USING (user_id = auth.uid() AND report_date = CURRENT_DATE);
    
    -- RLS Policy: CEO can delete reports
    CREATE POLICY "CEO can delete all reports"
    ON daily_work_reports FOR DELETE
    USING (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid()
        )
    );
    
    -- RLS Policy: Manager can delete branch reports
    CREATE POLICY "Manager can delete branch reports"
    ON daily_work_reports FOR DELETE
    USING (
        branch_id IN (
            SELECT branch_id FROM employees 
            WHERE id = auth.uid() AND role = 'MANAGER'
        )
    );
    
    -- RLS Policy: Staff can delete own reports (same day only)
    CREATE POLICY "Staff can delete own reports"
    ON daily_work_reports FOR DELETE
    USING (user_id = auth.uid() AND report_date = CURRENT_DATE);
    
    -- Create function to auto-update updated_at
    CREATE OR REPLACE FUNCTION update_daily_work_reports_updated_at()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    
    -- Create trigger for updated_at
    DROP TRIGGER IF EXISTS daily_work_reports_updated_at ON daily_work_reports;
    CREATE TRIGGER daily_work_reports_updated_at
        BEFORE UPDATE ON daily_work_reports
        FOR EACH ROW
        EXECUTE FUNCTION update_daily_work_reports_updated_at();
    """
    
    try:
        # Execute SQL using Supabase RPC or direct query
        supabase.postgrest.rpc('exec', {'sql': create_table_sql}).execute()
        print("✅ Table created successfully!")
    except Exception as e:
        # If RPC doesn't work, we'll need to run this manually
        print(f"⚠️  Cannot create via RPC: {e}")
        print("\n📋 Please run this SQL manually in Supabase SQL Editor:")
        print("=" * 80)
        print(create_table_sql)
        print("=" * 80)
        
        # Save to file for manual execution
        with open('daily_work_reports_schema.sql', 'w', encoding='utf-8') as f:
            f.write(create_table_sql)
        print("\n💾 SQL saved to: daily_work_reports_schema.sql")
        print("👉 Copy and run this in Supabase Dashboard → SQL Editor")
        return False
    
    return True

if __name__ == '__main__':
    print("=" * 80)
    print("🔧 SABOHUB - Create Daily Work Reports Table")
    print("=" * 80)
    
    if create_daily_work_reports_table():
        print("\n✅ Setup complete!")
        print("\nNext steps:")
        print("1. Update Flutter code to save reports to this table")
        print("2. Test the full flow: check-in → check-out → report saved")
    else:
        print("\n⚠️  Manual setup required - see instructions above")
