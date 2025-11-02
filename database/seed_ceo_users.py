#!/usr/bin/env python3
"""
Seed CEO users and additional test data
"""

import psycopg2
import sys
from datetime import datetime, timedelta
import random

# Database configuration
DB_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
DB_PORT = 6543
DB_NAME = "postgres"
DB_USER = "postgres.dqddxowyikefqcdiioyh"
DB_PASSWORD = "Acookingoil123"

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

def seed_ceo_users(conn):
    """Seed CEO users"""
    print("\n👑 Seeding CEO users...")
    
    cursor = conn.cursor()
    
    # Check if CEO users already exist
    cursor.execute("SELECT COUNT(*) FROM users WHERE role = 'CEO'")
    existing_count = cursor.fetchone()[0]
    
    if existing_count >= 2:
        print(f"✅ CEO users already exist ({existing_count} records)")
        cursor.execute("""
            SELECT id, email, full_name, company_id 
            FROM users 
            WHERE role = 'CEO'
        """)
        return cursor.fetchall()
    
    # Get companies
    cursor.execute("SELECT id, name FROM companies ORDER BY created_at")
    companies = cursor.fetchall()
    
    ceo_users = []
    ceo_names = ["Nguyễn Văn CEO", "Trần Thị CEO"]
    
    # Create 1 CEO per company
    for i, (company_id, company_name) in enumerate(companies[:2]):
        cursor.execute("""
            INSERT INTO users (
                email, full_name, role, company_id, is_active, created_at
            )
            VALUES (%s, %s, %s, %s, true, NOW())
            RETURNING id
        """, (
            f"ceo{i+1}@sabohub.com",
            ceo_names[i],
            "CEO",
            company_id
        ))
        
        user_id = cursor.fetchone()[0]
        ceo_users.append((user_id, f"ceo{i+1}@sabohub.com", ceo_names[i], company_id))
        print(f"  ✓ Created CEO: {ceo_names[i]} ({f'ceo{i+1}@sabohub.com'})")
    
    conn.commit()
    return ceo_users

def seed_overdue_tasks(conn):
    """Seed overdue tasks"""
    print("\n⏰ Seeding overdue tasks...")
    
    cursor = conn.cursor()
    
    # Get companies and users
    cursor.execute("SELECT id FROM companies")
    company_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT id FROM branches")
    branch_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT id FROM users WHERE role IN ('BRANCH_MANAGER', 'STAFF')")
    user_ids = [row[0] for row in cursor.fetchall()]
    
    if not user_ids or not branch_ids:
        print("  ⚠️ No users or branches found, skipping...")
        return
    
    overdue_tasks = [
        ("Hoàn thành báo cáo tháng trước", "Báo cáo đã quá hạn, cần hoàn thành gấp"),
        ("Kiểm tra hệ thống camera", "Hệ thống camera cần được bảo trì định kỳ"),
        ("Đào tạo nhân viên mới", "Khóa đào tạo đã được lên lịch từ tuần trước"),
    ]
    
    tasks_created = 0
    for i in range(3):
        # Create tasks that are 5-15 days overdue
        days_overdue = random.randint(5, 15)
        due_date = datetime.now() - timedelta(days=days_overdue)
        created_at = due_date - timedelta(days=random.randint(7, 14))
        
        cursor.execute("""
            INSERT INTO tasks (
                title, description, priority, status,
                company_id, branch_id, created_by, assigned_to,
                due_date, created_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            overdue_tasks[i][0],
            overdue_tasks[i][1],
            "urgent",
            "pending",
            random.choice(company_ids),
            random.choice(branch_ids),
            random.choice(user_ids),
            random.choice(user_ids),
            due_date,
            created_at
        ))
        tasks_created += 1
    
    conn.commit()
    print(f"  ✓ Created {tasks_created} overdue tasks")

def main():
    print("=" * 60)
    print("🌱 SEED CEO USERS & ADDITIONAL DATA")
    print("=" * 60)
    
    conn = create_connection()
    print("✅ Connected to database")
    
    try:
        # Seed CEO users
        ceo_users = seed_ceo_users(conn)
        
        # Seed overdue tasks
        seed_overdue_tasks(conn)
        
        print("\n" + "=" * 60)
        print("✅ SEEDING COMPLETE!")
        print("=" * 60)
        
        print("\n📊 Summary:")
        print(f"  - CEO users: {len(ceo_users)}")
        print(f"  - Overdue tasks: 3")
        
        print("\n🎉 Data ready for testing!")
        print("\n📝 CEO Login Credentials:")
        for user_id, email, name, company_id in ceo_users:
            print(f"  - {name}: {email}")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        conn.rollback()
        sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
