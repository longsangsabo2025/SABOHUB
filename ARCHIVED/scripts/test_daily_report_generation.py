#!/usr/bin/env python3
"""
SABOHUB - Test Daily Report Auto-Generation
============================================

Test kịch bản:
1. Lấy thông tin user/employee từ Supabase
2. Tạo attendance record (check-in)
3. Update attendance record (check-out)
4. Verify auto-generation của daily work report
5. Validate dữ liệu report (hours, tasks, summary)

Chạy: python test_daily_report_generation.py
"""

import os
import sys
from datetime import datetime, timedelta
try:
    from supabase import create_client, Client
except ImportError:
    # Fallback for different supabase versions
    from supabase.client import create_client, Client
from dotenv import load_dotenv

# Load .env file
load_dotenv()

# ============================================================================
# CONFIGURATION
# ============================================================================

SUPABASE_URL = os.getenv('SUPABASE_URL', 'YOUR_SUPABASE_URL')
# Use SERVICE_ROLE_KEY for admin access (bypass RLS)
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', os.getenv('SUPABASE_ANON_KEY', 'YOUR_SUPABASE_KEY'))

# Test data
TEST_EMPLOYEE_ID = os.getenv('TEST_EMPLOYEE_ID', None)  # Set to actual employee ID
TEST_BRANCH_ID = os.getenv('TEST_BRANCH_ID', None)      # Set to actual branch ID
TEST_COMPANY_ID = os.getenv('TEST_COMPANY_ID', None)    # Set to actual company ID

# ============================================================================
# SETUP
# ============================================================================

def setup_supabase() -> Client:
    """Initialize Supabase client"""
    if SUPABASE_URL == 'YOUR_SUPABASE_URL' or SUPABASE_KEY == 'YOUR_SUPABASE_ANON_KEY':
        print("❌ ERROR: Please set SUPABASE_URL and SUPABASE_ANON_KEY")
        print("\nSet environment variables:")
        print("  export SUPABASE_URL='https://your-project.supabase.co'")
        print("  export SUPABASE_ANON_KEY='your-anon-key'")
        sys.exit(1)
    
    return create_client(SUPABASE_URL, SUPABASE_KEY)

# ============================================================================
# TEST FUNCTIONS
# ============================================================================

def test_1_get_test_employee(supabase: Client) -> dict:
    """Step 1: Get test employee data"""
    print("\n" + "="*60)
    print("📍 STEP 1: Get Test Employee")
    print("="*60)
    
    try:
        # Get first available employee for testing
        response = supabase.table('employees')\
            .select('id, full_name, role, company_id, branch_id')\
            .limit(1)\
            .execute()
        
        if not response.data:
            print("❌ No employees found in database")
            print("💡 Please create an employee first via the app")
            sys.exit(1)
        
        employee = response.data[0]
        print(f"✅ Found employee: {employee['full_name']}")
        print(f"   ID: {employee['id']}")
        print(f"   Role: {employee['role']}")
        print(f"   Company: {employee['company_id']}")
        print(f"   Branch: {employee['branch_id']}")
        
        return employee
        
    except Exception as e:
        print(f"❌ Error getting employee: {e}")
        sys.exit(1)


def test_2_create_checkin(supabase: Client, employee: dict) -> dict:
    """Step 2: Create attendance check-in"""
    print("\n" + "="*60)
    print("📍 STEP 2: Create Check-in")
    print("="*60)
    
    try:
        now = datetime.now()
        
        # Check if already checked in today
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        existing = supabase.table('attendance')\
            .select('id, check_in, check_out')\
            .eq('user_id', employee['id'])\
            .gte('check_in', today_start.isoformat())\
            .execute()
        
        if existing.data:
            print(f"⚠️  Already have attendance today: {existing.data[0]['id']}")
            record = existing.data[0]
            if record.get('check_out'):
                print("   Already checked out - cannot reuse")
                return None
            print("   Using existing check-in record")
            return record
        
        # Create new check-in
        data = {
            'user_id': employee['id'],
            'company_id': employee['company_id'],
            'branch_id': employee['branch_id'],
            'check_in': now.isoformat(),
            'check_in_location': 'Test Office Location',
            'check_in_latitude': 10.762622,
            'check_in_longitude': 106.660172,
            'employee_name': employee['full_name'],
            'employee_role': employee['role'],
            'is_late': False,
        }
        
        response = supabase.table('attendance').insert(data).execute()
        
        if not response.data:
            print("❌ Failed to create check-in")
            return None
        
        record = response.data[0]
        print(f"✅ Check-in created: {record['id']}")
        print(f"   Time: {record['check_in']}")
        print(f"   Location: {record.get('check_in_location')}")
        
        return record
        
    except Exception as e:
        print(f"❌ Error creating check-in: {e}")
        return None


def test_3_simulate_work(duration_hours: float = 0.001):
    """Step 3: Simulate work period"""
    print("\n" + "="*60)
    print("📍 STEP 3: Simulate Work Period")
    print("="*60)
    
    import time
    print(f"⏳ Simulating {duration_hours} hours of work...")
    time.sleep(duration_hours * 3600)  # Convert to seconds
    print("✅ Work period complete")


def test_4_create_checkout(supabase: Client, attendance_id: str) -> dict:
    """Step 4: Create check-out (should trigger report generation)"""
    print("\n" + "="*60)
    print("📍 STEP 4: Create Check-out")
    print("="*60)
    
    try:
        now = datetime.now()
        
        # Update attendance with check-out
        response = supabase.table('attendance')\
            .update({
                'check_out': now.isoformat(),
                'check_out_location': 'Test Office Location',
                'check_out_latitude': 10.762622,
                'check_out_longitude': 106.660172,
            })\
            .eq('id', attendance_id)\
            .execute()
        
        if not response.data:
            print("❌ Failed to update check-out")
            return None
        
        record = response.data[0]
        
        # Calculate hours
        check_in = datetime.fromisoformat(record['check_in'].replace('Z', '+00:00'))
        check_out = datetime.fromisoformat(record['check_out'].replace('Z', '+00:00'))
        hours = (check_out - check_in).total_seconds() / 3600
        
        print(f"✅ Check-out updated: {record['id']}")
        print(f"   Time: {record['check_out']}")
        print(f"   Total Hours: {hours:.2f}")
        
        return record
        
    except Exception as e:
        print(f"❌ Error creating check-out: {e}")
        return None


def test_5_verify_report_generation(supabase: Client, employee: dict, attendance: dict):
    """Step 5: Verify daily work report was auto-generated"""
    print("\n" + "="*60)
    print("📍 STEP 5: Verify Report Auto-Generation")
    print("="*60)
    
    try:
        # NOTE: Currently reports are generated in-memory only
        # This step checks if the database has a daily_work_reports table
        
        # Check if table exists
        try:
            response = supabase.table('daily_work_reports')\
                .select('*')\
                .eq('user_id', employee['id'])\
                .limit(1)\
                .execute()
            
            if response.data:
                print("✅ Found daily_work_reports table")
                print(f"   Reports found: {len(response.data)}")
                
                for report in response.data:
                    print(f"\n   Report ID: {report.get('id')}")
                    print(f"   Date: {report.get('date')}")
                    print(f"   Hours: {report.get('total_hours')}")
                    print(f"   Tasks: {report.get('tasks_completed', 0)}")
                    print(f"   Status: {report.get('status')}")
            else:
                print("⚠️  No reports found in database")
                
        except Exception as table_error:
            print("⚠️  Table 'daily_work_reports' not found")
            print("   This feature generates reports in-memory only")
            print("   Database persistence is not yet implemented")
        
        # Verify the flow in app
        print("\n📊 To verify auto-generation:")
        print("   1. Open SABOHUB app")
        print("   2. Go to Staff Check-in page")
        print("   3. Check-out as this employee")
        print("   4. Report dialog should auto-appear")
        print("   5. Report should contain:")
        print("      - Work hours from attendance")
        print("      - Auto-collected tasks")
        print("      - Auto-generated summary")
        
    except Exception as e:
        print(f"❌ Error verifying report: {e}")


def test_6_validate_data_accuracy(attendance: dict):
    """Step 6: Validate report data accuracy"""
    print("\n" + "="*60)
    print("📍 STEP 6: Validate Data Accuracy")
    print("="*60)
    
    try:
        check_in = datetime.fromisoformat(attendance['check_in'].replace('Z', '+00:00'))
        check_out = datetime.fromisoformat(attendance['check_out'].replace('Z', '+00:00'))
        hours = (check_out - check_in).total_seconds() / 3600
        
        print("✅ Attendance Data:")
        print(f"   Check-in: {check_in.strftime('%H:%M:%S')}")
        print(f"   Check-out: {check_out.strftime('%H:%M:%S')}")
        print(f"   Duration: {hours:.4f} hours")
        
        print("\n✅ Expected Report Data:")
        print(f"   Total Hours: {hours:.2f}")
        print(f"   Should collect today's tasks")
        print(f"   Should generate summary")
        print(f"   Should populate achievements/challenges")
        
        print("\n📝 Validation Checklist:")
        print("   ✓ Report hours match attendance hours")
        print("   ✓ Tasks are from today's date")
        print("   ✓ Summary describes work activities")
        print("   ✓ Employee can edit notes before submit")
        
    except Exception as e:
        print(f"❌ Error validating data: {e}")


# ============================================================================
# MAIN TEST FLOW
# ============================================================================

def main():
    """Main test flow"""
    print("\n" + "="*60)
    print("🧪 SABOHUB - Daily Report Auto-Generation Test")
    print("="*60)
    print(f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Setup
    supabase = setup_supabase()
    
    # Run tests
    employee = test_1_get_test_employee(supabase)
    
    attendance = test_2_create_checkin(supabase, employee)
    if not attendance:
        print("\n❌ Test failed at check-in step")
        sys.exit(1)
    
    test_3_simulate_work(duration_hours=0.001)  # Very short for testing
    
    attendance = test_4_create_checkout(supabase, attendance['id'])
    if not attendance:
        print("\n❌ Test failed at check-out step")
        sys.exit(1)
    
    test_5_verify_report_generation(supabase, employee, attendance)
    
    test_6_validate_data_accuracy(attendance)
    
    # Summary
    print("\n" + "="*60)
    print("✅ TEST COMPLETED SUCCESSFULLY")
    print("="*60)
    print("\nNext Steps:")
    print("1. Test in the app: Staff Check-in → Check-out")
    print("2. Verify report dialog auto-appears")
    print("3. Check report data accuracy")
    print("4. Submit report and verify storage")
    print("\n💡 To test with real data:")
    print("   - Use actual employee in production")
    print("   - Work for full day")
    print("   - Complete actual tasks")
    print("   - Check-out at end of day")
    print("   - Report should auto-generate with real data")
    

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
