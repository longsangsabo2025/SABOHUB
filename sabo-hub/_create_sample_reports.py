import psycopg2
from datetime import datetime, timedelta
import uuid

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

# Get SABO company and branch info
cur.execute("SELECT id FROM companies WHERE LOWER(name) LIKE '%bida sabo%' LIMIT 1")
company_row = cur.fetchone()
if not company_row:
    cur.execute("SELECT id FROM companies WHERE LOWER(name) = 'sabo' LIMIT 1")
    company_row = cur.fetchone()

COMPANY_ID = company_row[0] if company_row else 'd6ff05cc-9440-4e8e-985a-eb6219dec3ec'
print(f"SABO Company ID: {COMPANY_ID}")

# Get branch_id
cur.execute("SELECT DISTINCT branch_id FROM employees WHERE company_id = %s AND branch_id IS NOT NULL LIMIT 1", (COMPANY_ID,))
branch_row = cur.fetchone()
BRANCH_ID = branch_row[0] if branch_row else '4ccdc579-0b71-4e32-8a5d-5e3f7c8b9d0a'
print(f"Branch ID: {BRANCH_ID}")

# Get SABO employees
cur.execute('''SELECT id, full_name, role FROM employees 
               WHERE company_id = %s AND is_active = true
               ORDER BY full_name''', (COMPANY_ID,))
employees = cur.fetchall()
print(f"Found {len(employees)} SABO employees")

# Create sample reports for last 7 days
reports_created = 0
for i in range(7):
    report_date = datetime.now().date() - timedelta(days=i)
    
    for emp in employees:
        emp_id, emp_name, emp_role = emp
        
        # Random work hours between 6-9 hours
        total_hours = 7.5 + (hash(str(emp_id) + str(report_date)) % 20) / 10.0
        
        check_in = datetime.combine(report_date, datetime.min.time().replace(hour=8, minute=0))
        check_out = check_in + timedelta(hours=total_hours)
        
        # Sample tasks summary
        tasks = [
            "Dọn dẹp khu vực bàn bi-da",
            "Phục vụ khách hàng",
            "Kiểm tra thiết bị",
            "Ghi nhận đơn hàng",
            "Tính tiền và thanh toán"
        ]
        sample_tasks = "\n".join([f"{j+1}. {tasks[(hash(str(emp_id)+str(j))%len(tasks))]}" for j in range(3)])
        
        try:
            cur.execute('''INSERT INTO daily_work_reports 
                          (employee_id, company_id, branch_id, report_date, check_in_time, check_out_time, 
                           total_hours, hours_worked, tasks_summary, employee_name, employee_role)
                          VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                          ON CONFLICT (employee_id, report_date) DO NOTHING''',
                       (emp_id, COMPANY_ID, BRANCH_ID, report_date, check_in, check_out,
                        total_hours, total_hours, sample_tasks, emp_name, emp_role or 'staff'))
            reports_created += 1
        except Exception as e:
            print(f"  Error for {emp_name} on {report_date}: {e}")

conn.commit()
print(f"\n✅ Created {reports_created} sample reports!")

# Verify
cur.execute("SELECT COUNT(*) FROM daily_work_reports WHERE company_id = %s", (COMPANY_ID,))
print(f"Total SABO reports in database: {cur.fetchone()[0]}")

conn.close()
