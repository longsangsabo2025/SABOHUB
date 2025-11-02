"""
Seed Sample Management Tasks and Approvals
Creates sample data for testing CEO and Manager task features
"""
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from datetime import datetime, timedelta
import sys

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def seed_management_tasks():
    """Seed sample management tasks"""
    try:
        print("🚀 Connecting to Supabase...")
        conn = psycopg2.connect(CONNECTION_STRING)
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Get CEO and Manager users
        print("📋 Fetching users...")
        cursor.execute("""
            SELECT id, email, role, full_name 
            FROM users 
            WHERE role IN ('ceo', 'manager')
            ORDER BY role, created_at
            LIMIT 10
        """)
        users = cursor.fetchall()
        
        if len(users) < 2:
            print("❌ Need at least 1 CEO and 1 Manager user")
            print("💡 Please create users first using the authentication system")
            return False
        
        ceo_users = [u for u in users if u[2] == 'ceo']
        manager_users = [u for u in users if u[2] == 'manager']
        
        if not ceo_users:
            print("❌ No CEO user found")
            return False
        if not manager_users:
            print("❌ No Manager user found")  
            return False
        
        ceo_id = ceo_users[0][0]
        ceo_name = ceo_users[0][3]
        manager_id = manager_users[0][0]
        manager_name = manager_users[0][3]
        
        print(f"✅ Found CEO: {ceo_name}")
        print(f"✅ Found Manager: {manager_name}")
        
        # Get companies
        cursor.execute("SELECT id, name FROM companies LIMIT 3")
        companies = cursor.fetchall()
        company_id = companies[0][0] if companies else None
        
        print(f"\n🔨 Creating sample tasks...")
        
        # Sample tasks from CEO to Manager
        ceo_tasks = [
            {
                'title': 'Mở rộng thị trường miền Bắc',
                'description': 'Khảo sát và lập kế hoạch mở 3 chi nhánh tại Hà Nội trong Q1/2026',
                'priority': 'high',
                'status': 'in_progress',
                'progress': 45,
                'due_date': (datetime.now() + timedelta(days=30)).isoformat(),
            },
            {
                'title': 'Triển khai hệ thống AI quản lý tồn kho',
                'description': 'Tích hợp AI để tối ưu hóa quản lý nguyên liệu và dự đoán nhu cầu',
                'priority': 'critical',
                'status': 'in_progress',
                'progress': 30,
                'due_date': (datetime.now() + timedelta(days=45)).isoformat(),
            },
            {
                'title': 'Đánh giá hiệu suất Q4',
                'description': 'Tổng kết KPI toàn công ty và lập kế hoạch phát triển Q1 năm sau',
                'priority': 'medium',
                'status': 'pending',
                'progress': 0,
                'due_date': (datetime.now() + timedelta(days=60)).isoformat(),
            },
            {
                'title': 'Xây dựng chiến lược Marketing 2026',
                'description': 'Phát triển kế hoạch marketing tổng thể cho năm 2026',
                'priority': 'high',
                'status': 'pending',
                'progress': 0,
                'due_date': (datetime.now() + timedelta(days=90)).isoformat(),
            },
        ]
        
        created_count = 0
        for task_data in ceo_tasks:
            cursor.execute("""
                INSERT INTO tasks (
                    title, description, priority, status, progress,
                    due_date, created_by, assigned_to, company_id
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                task_data['title'],
                task_data['description'],
                task_data['priority'],
                task_data['status'],
                task_data['progress'],
                task_data['due_date'],
                ceo_id,
                manager_id,
                company_id,
            ))
            task_id = cursor.fetchone()[0]
            created_count += 1
            print(f"  ✓ Created: {task_data['title']}")
        
        print(f"\n✅ Created {created_count} tasks from CEO to Manager")
        
        # Create sample approvals from Manager to CEO
        print(f"\n🔨 Creating sample approval requests...")
        
        approvals = [
            {
                'title': 'Báo cáo doanh thu tháng 10/2025',
                'description': 'Báo cáo chi tiết doanh thu, chi phí và lợi nhuận tháng 10',
                'type': 'report',
                'status': 'pending',
            },
            {
                'title': 'Đề xuất ngân sách Marketing Q1/2026',
                'description': 'Ngân sách dự kiến 500 triệu đồng cho các hoạt động marketing quý 1',
                'type': 'budget',
                'status': 'pending',
            },
            {
                'title': 'Đề xuất mở chi nhánh mới tại Đà Nẵng',
                'description': 'Phân tích thị trường và đề xuất kế hoạch mở chi nhánh tại khu vực Đà Nẵng',
                'type': 'proposal',
                'status': 'pending',
            },
        ]
        
        approval_count = 0
        for approval_data in approvals:
            cursor.execute("""
                INSERT INTO task_approvals (
                    title, description, type, status,
                    submitted_by, company_id
                ) VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                approval_data['title'],
                approval_data['description'],
                approval_data['type'],
                approval_data['status'],
                manager_id,
                company_id,
            ))
            approval_id = cursor.fetchone()[0]
            approval_count += 1
            print(f"  ✓ Created: {approval_data['title']}")
        
        print(f"\n✅ Created {approval_count} approval requests")
        
        # Verify
        cursor.execute("SELECT COUNT(*) FROM tasks WHERE created_by = %s", (ceo_id,))
        total_tasks = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM task_approvals WHERE status = 'pending'")
        total_approvals = cursor.fetchone()[0]
        
        print(f"\n📊 Summary:")
        print(f"  • Total CEO tasks: {total_tasks}")
        print(f"  • Pending approvals: {total_approvals}")
        print(f"\n✅ Sample data seeded successfully!")
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.Error as e:
        print(f"\n❌ Database error: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    success = seed_management_tasks()
    sys.exit(0 if success else 1)
