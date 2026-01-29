#!/usr/bin/env python3
"""
Test daily report database persistence
Verify that reports are saved to daily_work_reports table
"""
from supabase import create_client
from dotenv import load_dotenv
import os
from datetime import datetime

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

def test_report_persistence():
    """Test if daily_work_reports table exists and has data"""
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    print("="*80)
    print("🧪 Testing Daily Work Reports - Database Persistence")
    print("="*80)
    
    # Step 1: Check table exists
    print("\n📍 STEP 1: Check Table Exists")
    try:
        result = supabase.table('daily_work_reports').select('id').limit(1).execute()
        print("✅ Table 'daily_work_reports' EXISTS")
    except Exception as e:
        print(f"❌ Table not found: {e}")
        print("\n💡 Run this SQL first:")
        print("   daily_work_reports_schema_fixed.sql")
        return False
    
    # Step 2: Check for reports
    print("\n📍 STEP 2: Check for Reports")
    try:
        today = datetime.now().strftime('%Y-%m-%d')
        all_reports = supabase.table('daily_work_reports')\
            .select('*')\
            .execute()
        
        today_reports = supabase.table('daily_work_reports')\
            .select('*')\
            .eq('report_date', today)\
            .execute()
        
        print(f"📊 Total reports in database: {len(all_reports.data)}")
        print(f"📊 Reports for today ({today}): {len(today_reports.data)}")
        
        if len(all_reports.data) == 0:
            print("\n⚠️  No reports found yet")
            print("\n📋 To generate a report:")
            print("   1. Run Flutter app")
            print("   2. Login as employee")
            print("   3. Check-in")
            print("   4. Check-out")
            print("   5. Report will auto-generate and save to database")
            return False
        
        # Step 3: Show report details
        print("\n📍 STEP 3: Report Details")
        for report in all_reports.data[:5]:
            print(f"\n✅ Report Found:")
            print(f"   ID: {report['id']}")
            print(f"   Employee: {report['employee_name']} ({report['employee_role']})")
            print(f"   Date: {report['report_date']}")
            print(f"   Company: {report['company_id']}")
            print(f"   Branch: {report.get('branch_id', 'N/A')}")
            print(f"   Check-in: {report['check_in_time']}")
            print(f"   Check-out: {report['check_out_time']}")
            print(f"   Total Hours: {report['total_hours']}")
            
            if report.get('tasks_summary'):
                print(f"   Tasks Summary:")
                summary_lines = report['tasks_summary'].split('\n')[:3]
                for line in summary_lines:
                    print(f"      {line}")
                if len(report['tasks_summary'].split('\n')) > 3:
                    print("      ...")
            
            if report.get('achievements'):
                print(f"   Achievements: {report['achievements']}")
            if report.get('challenges'):
                print(f"   Challenges: {report['challenges']}")
            if report.get('notes'):
                print(f"   Notes: {report['notes']}")
            
            print(f"   Created: {report['created_at']}")
        
        print("\n" + "="*80)
        print("✅ DATABASE PERSISTENCE IS WORKING!")
        print("="*80)
        return True
        
    except Exception as e:
        print(f"❌ Error querying reports: {e}")
        return False

if __name__ == '__main__':
    success = test_report_persistence()
    exit(0 if success else 1)
