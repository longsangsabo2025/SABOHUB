"""
Test KPI System and Create Sample Data
Run this to verify database tables and create test data
"""

import os
from datetime import datetime, timedelta
from supabase import create_client, Client

# Initialize Supabase client
SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://ucxvgavqslwqiksohccs.supabase.co')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjeHZnYXZxc2x3cWlrc29oY2NzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE0ODE5OTUsImV4cCI6MjA0NzA1Nzk5NX0.h3QBNMK4JiNhRZdHxeZqIZjQ8h3dUg8g3-KWlf7uDww')

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def check_tables():
    """Verify KPI tables exist"""
    print("\n🔍 === CHECKING DATABASE TABLES ===\n")
    
    try:
        # Check performance_metrics table
        response = supabase.table('performance_metrics').select('*').limit(1).execute()
        print("✅ performance_metrics table: EXISTS")
        print(f"   Columns: {list(response.data[0].keys()) if response.data else 'Empty table'}")
    except Exception as e:
        print(f"❌ performance_metrics table: {e}")
    
    try:
        # Check kpi_targets table  
        response = supabase.table('kpi_targets').select('*').limit(1).execute()
        print("✅ kpi_targets table: EXISTS")
        print(f"   Columns: {list(response.data[0].keys()) if response.data else 'Empty table'}")
    except Exception as e:
        print(f"❌ kpi_targets table: {e}")
    
    print()

def get_employees():
    """Get list of employees"""
    try:
        response = supabase.table('employees').select('id, full_name, role, company_id').limit(10).execute()
        print(f"✅ Found {len(response.data)} employees")
        return response.data
    except Exception as e:
        print(f"❌ Error getting employees: {e}")
        return []

def create_kpi_targets(employees):
    """Create KPI targets for employees"""
    print("\n📊 === CREATING KPI TARGETS ===\n")
    
    # Default targets by role
    default_targets = {
        'STAFF': [
            {
                'metric_name': 'Tỷ lệ hoàn thành nhiệm vụ',
                'metric_type': 'completion_rate',
                'target_value': 90.0,
                'period': 'weekly',
            },
            {
                'metric_name': 'Đúng giờ',
                'metric_type': 'timeliness',
                'target_value': 95.0,
                'period': 'weekly',
            },
        ],
        'MANAGER': [
            {
                'metric_name': 'Tỷ lệ hoàn thành nhiệm vụ quản lý',
                'metric_type': 'completion_rate',
                'target_value': 95.0,
                'period': 'weekly',
            },
        ],
        'SHIFT_LEADER': [
            {
                'metric_name': 'Tỷ lệ hoàn thành nhiệm vụ ca',
                'metric_type': 'completion_rate',
                'target_value': 92.0,
                'period': 'weekly',
            },
        ],
    }
    
    created = 0
    for employee in employees[:5]:  # Only first 5 employees
        role = employee.get('role', 'STAFF')
        targets = default_targets.get(role, default_targets['STAFF'])
        
        for target in targets:
            try:
                data = {
                    'user_id': employee['id'],
                    'role': role,
                    'metric_name': target['metric_name'],
                    'metric_type': target['metric_type'],
                    'target_value': target['target_value'],
                    'period': target['period'],
                    'is_active': True,
                }
                
                response = supabase.table('kpi_targets').insert(data).execute()
                print(f"✅ Created KPI target for {employee['full_name']}: {target['metric_name']}")
                created += 1
            except Exception as e:
                print(f"⚠️  KPI target may already exist: {e}")
    
    print(f"\n✅ Created {created} KPI targets\n")

def create_performance_metrics(employees):
    """Create sample performance metrics"""
    print("\n📈 === CREATING PERFORMANCE METRICS ===\n")
    
    created = 0
    # Create metrics for last 7 days
    for day in range(7):
        date = datetime.now() - timedelta(days=day)
        date_str = date.strftime('%Y-%m-%d')
        
        for employee in employees[:5]:  # Only first 5 employees
            # Simulate performance data
            tasks_assigned = 10 + (day % 3)
            tasks_completed = int(tasks_assigned * (0.75 + (employee['id'][:2].count('0') * 0.05)))
            
            completion_rate = (tasks_completed / tasks_assigned * 100) if tasks_assigned > 0 else 0
            
            data = {
                'user_id': employee['id'],
                'user_name': employee['full_name'],
                'metric_date': date_str,
                'tasks_assigned': tasks_assigned,
                'tasks_completed': tasks_completed,
                'tasks_overdue': max(0, tasks_assigned - tasks_completed - 1),
                'tasks_cancelled': 0,
                'completion_rate': round(completion_rate, 2),
                'avg_quality_score': round(7.5 + (day * 0.2), 2),
                'on_time_rate': round(85.0 + (day * 1.5), 2),
                'photo_submission_rate': round(90.0 + (day * 0.8), 2),
                'total_work_duration': 480 + (day * 15),  # minutes
                'checklists_completed': tasks_completed,
                'incidents_reported': 0,
            }
            
            try:
                response = supabase.table('performance_metrics').upsert(data).execute()
                print(f"✅ Created metrics for {employee['full_name']} on {date_str}")
                created += 1
            except Exception as e:
                print(f"❌ Error creating metrics: {e}")
    
    print(f"\n✅ Created {created} performance metrics records\n")

def query_sample_data():
    """Query and display sample data"""
    print("\n🔎 === SAMPLE DATA QUERY ===\n")
    
    try:
        # Get recent performance metrics
        response = supabase.table('performance_metrics')\
            .select('user_name, metric_date, completion_rate, avg_quality_score')\
            .order('metric_date', desc=True)\
            .limit(10)\
            .execute()
        
        print("Recent Performance Metrics:")
        for record in response.data:
            print(f"  - {record['user_name']}: {record['completion_rate']}% completion, "
                  f"{record['avg_quality_score']} quality (Date: {record['metric_date']})")
        print()
    except Exception as e:
        print(f"❌ Error querying metrics: {e}")
    
    try:
        # Get active KPI targets
        response = supabase.table('kpi_targets')\
            .select('metric_name, metric_type, target_value, period')\
            .eq('is_active', True)\
            .limit(10)\
            .execute()
        
        print(f"\nActive KPI Targets ({len(response.data)}):")
        for record in response.data:
            print(f"  - {record['metric_name']}: {record['target_value']} ({record['period']})")
        print()
    except Exception as e:
        print(f"❌ Error querying KPI targets: {e}")

def calculate_statistics():
    """Calculate and display statistics"""
    print("\n📊 === STATISTICS ===\n")
    
    try:
        # Count records
        metrics_count = len(supabase.table('performance_metrics').select('id').execute().data)
        targets_count = len(supabase.table('kpi_targets').select('id').execute().data)
        
        print(f"Total Performance Metrics: {metrics_count}")
        print(f"Total KPI Targets: {targets_count}")
        
        # Average completion rate
        metrics = supabase.table('performance_metrics')\
            .select('completion_rate')\
            .not_('completion_rate', 'is', None)\
            .execute()
        
        if metrics.data:
            avg_completion = sum(m['completion_rate'] for m in metrics.data) / len(metrics.data)
            print(f"Average Completion Rate: {avg_completion:.2f}%")
        
        print()
    except Exception as e:
        print(f"❌ Error calculating statistics: {e}")

def main():
    print("🎯 === KPI SYSTEM TEST & SETUP ===")
    
    # Step 1: Check tables
    check_tables()
    
    # Step 2: Get employees
    print("\n👥 === GETTING EMPLOYEES ===\n")
    employees = get_employees()
    
    if not employees:
        print("❌ No employees found. Cannot proceed.")
        return
    
    # Step 3: Create KPI targets
    create_kpi_targets(employees)
    
    # Step 4: Create performance metrics
    create_performance_metrics(employees)
    
    # Step 5: Query sample data
    query_sample_data()
    
    # Step 6: Calculate statistics
    calculate_statistics()
    
    print("\n✅ === TEST COMPLETE ===\n")
    print("🎉 KPI system is ready to use!")
    print("\n📱 Next steps:")
    print("  1. Run Flutter app: flutter run -d chrome")
    print("  2. Login as Manager")
    print("  3. Go to Settings → 'Đánh giá nhân viên'")
    print("  4. Click 'Calculate' button to compute today's metrics")
    print("  5. View employee rankings and performance")

if __name__ == '__main__':
    main()
