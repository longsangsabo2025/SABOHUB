#!/usr/bin/env python3
"""
Seed Sample Data for SABO HUB Database - Simplified Version
Uses existing company data and adds branches, tables, users, revenue data
"""

import psycopg2
from datetime import datetime, timedelta
import random

# Database connection using transaction pooler
DB_CONFIG = {
    'host': 'aws-1-ap-southeast-2.pooler.supabase.com',
    'port': 6543,
    'database': 'postgres',
    'user': 'postgres.dqddxowyikefqcdiioyh',
    'password': 'Acookingoil123',
}

def seed_sample_data():
    """Insert sample data using existing companies"""
    conn = None
    try:
        print("🔌 Connecting to database...")
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        
        print("\n📊 Seeding sample data...")
        
        # Get existing companies
        print("\n1️⃣ Getting existing companies...")
        cur.execute("SELECT id, name FROM companies WHERE is_active = true LIMIT 5")
        companies = cur.fetchall()
        
        if not companies:
            print("❌ No companies found! Please run the company creation first.")
            return
        
        print(f"✅ Found {len(companies)} companies")
        
        # 2. Insert branches for each company
        print("\n2️⃣ Inserting branches...")
        branch_ids = []
        for company in companies:
            company_id, company_name = company
            cur.execute("""
                INSERT INTO stores (company_id, name, address, phone, code, status, created_at)
                VALUES (%s, %s, %s, %s, %s, 'ACTIVE', NOW())
                ON CONFLICT DO NOTHING
                RETURNING id;
            """, (
                company_id,
                f"{company_name} - Chi nhánh chính",
                '123 Main Street, HCMC',
                f"090{random.randint(1000000, 9999999)}",
                f"BR{len(branch_ids) + 1:03d}"
            ))
            result = cur.fetchone()
            if result:
                branch_ids.append((result[0], company_id))
        
        print(f"✅ Inserted {len(branch_ids)} branches")
        
        # 3. Insert tables for each branch
        print("\n3️⃣ Inserting tables...")
        table_count = 0
        table_types = ['standard', 'vip']
        table_statuses = ['available', 'occupied', 'maintenance']
        
        for branch_id, company_id in branch_ids:
            # Insert 3 tables per branch
            for i in range(1, 4):
                cur.execute("""
                    INSERT INTO tables (company_id, store_id, name, table_type, hourly_rate, status, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, NOW())
                    ON CONFLICT DO NOTHING;
                """, (
                    company_id,
                    branch_id,
                    f"Bàn {i}",
                    random.choice(table_types),
                    random.randint(60, 100) * 1000,  # 60k - 100k VND
                    random.choice(table_statuses)
                ))
                table_count += cur.rowcount
        
        print(f"✅ Inserted {table_count} tables")
        
        # 4. Insert users for each branch
        print("\n4️⃣ Inserting users...")
        user_count = 0
        roles = ['manager', 'staff']
        
        for branch_id, company_id in branch_ids:
            # Insert 2 users per branch
            for i in range(2):
                role = roles[i % 2]
                cur.execute("""
                    INSERT INTO users (company_id, store_id, email, full_name, phone, role, is_active, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, true, NOW())
                    ON CONFLICT (email) DO NOTHING;
                """, (
                    company_id,
                    branch_id,
                    f"user{user_count + 1}@sabo.vn",
                    f"User {user_count + 1}",
                    f"090{random.randint(1000000, 9999999)}",
                    role
                ))
                user_count += cur.rowcount
        
        print(f"✅ Inserted {user_count} users")
        
        # 5. Insert 30 days of revenue data
        print("\n5️⃣ Inserting daily revenue data...")
        revenue_count = 0
        
        for branch_id, company_id in branch_ids:
            for i in range(30):
                date = (datetime.now() - timedelta(days=i)).date()
                # Random revenue between 2M - 8M per day
                total_revenue = random.randint(2000, 8000) * 1000
                
                cur.execute("""
                    INSERT INTO daily_revenue (date, company_id, store_id, total_revenue, created_at)
                    VALUES (%s, %s, %s, %s, NOW())
                    ON CONFLICT (date, company_id, store_id) DO NOTHING;
                """, (date, company_id, branch_id, total_revenue))
                revenue_count += cur.rowcount
        
        print(f"✅ Inserted {revenue_count} daily revenue records")
        
        # 6. Insert tasks
        print("\n6️⃣ Inserting tasks...")
        task_count = 0
        task_templates = [
            ('Kiểm tra thiết bị', 'Kiểm tra và bảo trì thiết bị', 'high'),
            ('Dọn dẹp khu vực', 'Vệ sinh tổng thể', 'medium'),
            ('Kiểm kê kho', 'Kiểm tra số lượng trong kho', 'low'),
            ('Training nhân viên', 'Đào tạo nhân viên mới', 'medium'),
            ('Báo cáo doanh thu', 'Tổng hợp báo cáo', 'high'),
        ]
        statuses = ['pending', 'in_progress', 'completed']
        
        # Get first user from each branch for task assignment
        for branch_id, company_id in branch_ids:
            cur.execute("SELECT id FROM users WHERE store_id = %s LIMIT 1", (branch_id,))
            user_result = cur.fetchone()
            if not user_result:
                continue
            
            user_id = user_result[0]
            
            # Create 2 tasks per branch
            for title, description, priority in task_templates[:2]:
                cur.execute("""
                    INSERT INTO tasks (company_id, store_id, title, description, assigned_to, status, priority, due_date, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW())
                    ON CONFLICT DO NOTHING;
                """, (
                    company_id,
                    branch_id,
                    title,
                    description,
                    user_id,
                    random.choice(statuses),
                    priority,
                    (datetime.now() + timedelta(days=random.randint(1, 7))).date()
                ))
                task_count += cur.rowcount
        
        print(f"✅ Inserted {task_count} tasks")
        
        # Commit transaction
        conn.commit()
        
        print("\n" + "="*60)
        print("✨ Sample data seeding completed successfully!")
        print("="*60)
        print("\n📊 Summary:")
        print(f"  • {len(companies)} Companies (existing)")
        print(f"  • {len(branch_ids)} Branches")
        print(f"  • {table_count} Tables")
        print(f"  • {user_count} Users")
        print(f"  • {task_count} Tasks")
        print(f"  • {revenue_count} Daily Revenue Records (30 days)")
        print("\n🎯 Database is now ready for development and testing!")
        
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"\n❌ Error seeding data: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if conn:
            cur.close()
            conn.close()
            print("\n🔌 Database connection closed")

if __name__ == '__main__':
    seed_sample_data()
