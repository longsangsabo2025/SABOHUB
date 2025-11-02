#!/usr/bin/env python3
"""
Seed Company Tasks Data
Creates sample companies and tasks for CEO dashboard testing
"""

import os
import sys
from datetime import datetime, timedelta
import random
import psycopg2
from psycopg2.extras import execute_values

# Supabase connection details (using transaction pooler)
DB_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
DB_PORT = "6543"
DB_NAME = "postgres"
DB_USER = "postgres.dqddxowyikefqcdiioyh"
DB_PASSWORD = "Acookingoil123"

# Sample data
COMPANIES = [
    {"name": "Công ty TNHH Billiards Sài Gòn", "tax_code": "0123456789"},
    {"name": "Công ty CP Billiards Hà Nội", "tax_code": "0987654321"},
]

TASK_TITLES = [
    "Cải thiện chất lượng dịch vụ khách hàng",
    "Tối ưu hóa quy trình quản lý bàn",
    "Đào tạo nhân viên kỹ năng mới",
    "Nâng cấp hệ thống POS",
    "Mở rộng thị trường khu vực mới",
    "Cải thiện chất lượng bàn bi-a",
    "Tăng cường marketing online",
    "Xây dựng chương trình khách hàng thân thiết",
    "Tối ưu chi phí vận hành",
    "Phát triển dịch vụ F&B",
]

TASK_DESCRIPTIONS = [
    "Nhiệm vụ chiến lược quan trọng cần hoàn thành trong quý này",
    "Dự án dài hạn yêu cầu phối hợp nhiều bộ phận",
    "Nhiệm vụ cấp bách cần giải quyết ngay",
    "Kế hoạch phát triển cho năm tới",
    "Tối ưu hóa quy trình hiện tại",
]

STATUSES = ["pending", "in_progress", "completed"]
PRIORITIES = ["low", "medium", "high", "urgent"]

def create_connection():
    """Create database connection"""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        return conn
    except Exception as e:
        print(f"❌ Connection error: {e}")
        sys.exit(1)

def seed_companies(conn):
    """Seed companies table"""
    print("\n📊 Seeding companies...")
    
    cursor = conn.cursor()
    
    # Check if companies already exist
    cursor.execute("SELECT COUNT(*) FROM companies")
    existing_count = cursor.fetchone()[0]
    
    if existing_count >= 2:
        print(f"✅ Companies already exist ({existing_count} records)")
        cursor.execute("SELECT id, name FROM companies LIMIT 2")
        return [row[0] for row in cursor.fetchall()]
    
    company_ids = []
    for company in COMPANIES:
        cursor.execute("""
            INSERT INTO companies (name, tax_code, created_at)
            VALUES (%s, %s, NOW())
            RETURNING id
        """, (company['name'], company['tax_code']))
        
        company_id = cursor.fetchone()[0]
        company_ids.append(company_id)
        print(f"  ✓ Created: {company['name']}")
    
    conn.commit()
    return company_ids

def seed_branches(conn, company_ids):
    """Seed branches table"""
    print("\n🏢 Seeding branches...")
    
    cursor = conn.cursor()
    
    branches = []
    branch_names = ["Chi nhánh Quận 1", "Chi nhánh Quận 3", "Chi nhánh Đống Đa"]
    
    for i, company_id in enumerate(company_ids):
        for j, branch_name in enumerate(branch_names[:2]):  # 2 branches per company
            cursor.execute("""
                INSERT INTO branches (company_id, name, address, phone, is_active, created_at)
                VALUES (%s, %s, %s, %s, true, NOW())
                RETURNING id
            """, (
                company_id,
                branch_name,
                f"123 Đường {branch_name}",
                f"028123456{i}{j}"
            ))
            
            branch_id = cursor.fetchone()[0]
            branches.append((branch_id, company_id))
            print(f"  ✓ Created: {branch_name} for company {i+1}")
    
    conn.commit()
    return branches

def seed_users(conn, branches):
    """Seed users (managers and staff)"""
    print("\n👥 Seeding users...")
    
    cursor = conn.cursor()
    
    # Check if users already exist
    cursor.execute("SELECT COUNT(*) FROM users WHERE role IN ('BRANCH_MANAGER', 'STAFF')")
    existing_count = cursor.fetchone()[0]
    
    if existing_count >= 4:
        print(f"✅ Users already exist ({existing_count} records)")
        cursor.execute("""
            SELECT id, role, company_id, branch_id 
            FROM users 
            WHERE role IN ('BRANCH_MANAGER', 'STAFF')
            LIMIT 10
        """)
        return cursor.fetchall()
    
    users = []
    manager_names = ["Nguyễn Văn A", "Trần Thị B", "Lê Văn C", "Phạm Thị D"]
    staff_names = ["Nguyễn Văn E", "Trần Thị F", "Lê Văn G", "Phạm Thị H"]
    
    # Create managers (2 per company)
    for i, (branch_id, company_id) in enumerate(branches[:4]):
        cursor.execute("""
            INSERT INTO users (
                email, full_name, role, company_id, branch_id, is_active, created_at
            )
            VALUES (%s, %s, %s, %s, %s, true, NOW())
            RETURNING id
        """, (
            f"manager{i+1}@sabohub.com",
            manager_names[i],
            "BRANCH_MANAGER",
            company_id,
            branch_id
        ))
        
        user_id = cursor.fetchone()[0]
        users.append((user_id, "BRANCH_MANAGER", company_id, branch_id))
        print(f"  ✓ Created manager: {manager_names[i]}")
    
    # Create staff (2 per branch)
    for i, (branch_id, company_id) in enumerate(branches[:4]):
        cursor.execute("""
            INSERT INTO users (
                email, full_name, role, company_id, branch_id, is_active, created_at
            )
            VALUES (%s, %s, %s, %s, %s, true, NOW())
            RETURNING id
        """, (
            f"staff{i+1}@sabohub.com",
            staff_names[i],
            "STAFF",
            company_id,
            branch_id
        ))
        
        user_id = cursor.fetchone()[0]
        users.append((user_id, "STAFF", company_id, branch_id))
        print(f"  ✓ Created staff: {staff_names[i]}")
    
    conn.commit()
    return users

def seed_tasks(conn, company_ids, branches, users):
    """Seed management tasks"""
    print("\n📝 Seeding tasks...")
    
    cursor = conn.cursor()
    
    # Check if tasks already exist
    cursor.execute("SELECT COUNT(*) FROM tasks")
    existing_count = cursor.fetchone()[0]
    
    if existing_count >= 10:
        print(f"✅ Tasks already exist ({existing_count} records)")
        return
    
    managers = [u for u in users if u[1] == 'BRANCH_MANAGER']
    staff = [u for u in users if u[1] == 'STAFF']
    
    tasks_created = 0
    
    # Create 5-8 tasks per company
    for company_id in company_ids:
        company_branches = [b for b in branches if b[1] == company_id]
        company_managers = [m for m in managers if m[2] == company_id]
        company_staff = [s for s in staff if s[2] == company_id]
        
        num_tasks = random.randint(5, 8)
        
        for i in range(num_tasks):
            # Random manager as creator
            creator = random.choice(company_managers) if company_managers else None
            if not creator:
                continue
            
            # Random assignee (manager or staff)
            assignee = random.choice(company_managers + company_staff)
            
            # Random branch
            branch = random.choice(company_branches) if company_branches else None
            if not branch:
                continue
            
            # Random dates
            created_days_ago = random.randint(1, 30)
            created_at = datetime.now() - timedelta(days=created_days_ago)
            due_date = created_at + timedelta(days=random.randint(7, 30))
            
            # Random status
            status = random.choice(STATUSES)
            
            cursor.execute("""
                INSERT INTO tasks (
                    title, description, priority, status,
                    company_id, branch_id, created_by, assigned_to,
                    due_date, created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                random.choice(TASK_TITLES),
                random.choice(TASK_DESCRIPTIONS),
                random.choice(PRIORITIES),
                status,
                company_id,
                branch[0],
                creator[0],
                assignee[0],
                due_date,
                created_at
            ))
            
            tasks_created += 1
    
    conn.commit()
    print(f"  ✓ Created {tasks_created} tasks")

def main():
    """Main execution"""
    print("=" * 60)
    print("🌱 SEED COMPANY TASKS DATA")
    print("=" * 60)
    
    conn = create_connection()
    print("✅ Connected to database")
    
    try:
        # Seed data
        company_ids = seed_companies(conn)
        branches = seed_branches(conn, company_ids)
        users = seed_users(conn, branches)
        seed_tasks(conn, company_ids, branches, users)
        
        print("\n" + "=" * 60)
        print("✅ SEEDING COMPLETE!")
        print("=" * 60)
        print(f"\n📊 Summary:")
        print(f"  - Companies: {len(company_ids)}")
        print(f"  - Branches: {len(branches)}")
        print(f"  - Users: {len(users)}")
        print("\n🎉 Data ready for CEO dashboard testing!")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        conn.rollback()
        sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
