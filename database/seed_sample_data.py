#!/usr/bin/env python3
"""
Seed Sample Data for SABO HUB Database
Inserts sample data for development and testing
"""

import psycopg2
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection using transaction pooler
DB_CONFIG = {
    'host': 'aws-1-ap-southeast-2.pooler.supabase.com',
    'port': 6543,
    'database': 'postgres',
    'user': 'postgres.dqddxowyikefqcdiioyh',
    'password': os.getenv('SUPABASE_DB_PASSWORD', 'Acookingoil123'),
}

def seed_sample_data():
    """Insert 5 sample records for each main table"""
    conn = None
    try:
        print("🔌 Connecting to database...")
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        
        print("\n📊 Seeding sample data...")
        
        # First, get existing company IDs or create if none exist
        print("\n1️⃣ Checking/Inserting companies...")
        cur.execute("SELECT id, name FROM companies LIMIT 5")
        companies = cur.fetchall()
        
        if len(companies) < 5:
            # Need to insert more companies
            companies_sql = """
            INSERT INTO companies (name, business_type, address, phone, email, is_active, created_at)
            VALUES 
                ('SABO Billiards Central', 'billiards', '123 Nguyen Hue, Q1, HCMC', '0901234567', 'central@sabo.vn', true, NOW()),
                ('SABO Entertainment District 2', 'entertainment', '456 Le Lai, Q1, HCMC', '0901234568', 'district2@sabo.vn', true, NOW()),
                ('SABO Sports Binh Thanh', 'billiards', '789 Xo Viet Nghe Tinh, Binh Thanh, HCMC', '0901234569', 'binhthanh@sabo.vn', true, NOW()),
                ('SABO Premium Phu Nhuan', 'billiards', '321 Phan Dang Luu, Phu Nhuan, HCMC', '0901234570', 'phunhuan@sabo.vn', true, NOW()),
                ('SABO Club Tan Binh', 'entertainment', '654 Cong Hoa, Tan Binh, HCMC', '0901234571', 'tanbinh@sabo.vn', true, NOW())
            RETURNING id, name;
            """
            cur.execute(companies_sql)
            companies = cur.fetchall()
            print(f"✅ Inserted {len(companies)} companies")
        else:
            print(f"✅ Using {len(companies)} existing companies")
        
        company_ids = [str(c[0]) for c in companies]
        
        # 2. Insert 5 sample branches
        print("\n2️⃣ Inserting branches...")
        branches_sql = """
        INSERT INTO branches (id, company_id, name, address, phone, manager_name, is_active, created_at)
        VALUES 
            ('br-001', 'cmp-001', 'Chi nhánh Quận 1', '123 Nguyen Hue, Q1, HCMC', '0901234567', 'Nguyen Van A', true, NOW()),
            ('br-002', 'cmp-002', 'Chi nhánh Quận 2', '456 Le Lai, Q1, HCMC', '0901234568', 'Tran Thi B', true, NOW()),
            ('br-003', 'cmp-003', 'Chi nhánh Bình Thạnh', '789 Xo Viet Nghe Tinh, Binh Thanh, HCMC', '0901234569', 'Le Van C', true, NOW()),
            ('br-004', 'cmp-004', 'Chi nhánh Phú Nhuận', '321 Phan Dang Luu, Phu Nhuan, HCMC', '0901234570', 'Pham Van D', true, NOW()),
            ('br-005', 'cmp-005', 'Chi nhánh Tân Bình', '654 Cong Hoa, Tan Binh, HCMC', '0901234571', 'Hoang Thi E', true, NOW())
        ON CONFLICT (id) DO NOTHING;
        """
        cur.execute(branches_sql)
        print(f"✅ Inserted {cur.rowcount} branches")
        
        # 3. Insert 15 sample tables (3 per branch)
        print("\n3️⃣ Inserting tables...")
        tables_sql = """
        INSERT INTO tables (id, company_id, branch_id, table_number, table_type, hourly_rate, status, created_at)
        VALUES 
            ('tbl-001', 'cmp-001', 'br-001', 'B01', 'french', 80000, 'available', NOW()),
            ('tbl-002', 'cmp-001', 'br-001', 'B02', 'pool', 60000, 'available', NOW()),
            ('tbl-003', 'cmp-001', 'br-001', 'B03', 'carom', 70000, 'occupied', NOW()),
            ('tbl-004', 'cmp-002', 'br-002', 'B01', 'french', 85000, 'available', NOW()),
            ('tbl-005', 'cmp-002', 'br-002', 'B02', 'pool', 65000, 'occupied', NOW()),
            ('tbl-006', 'cmp-002', 'br-002', 'B03', 'french', 85000, 'available', NOW()),
            ('tbl-007', 'cmp-003', 'br-003', 'B01', 'carom', 75000, 'available', NOW()),
            ('tbl-008', 'cmp-003', 'br-003', 'B02', 'french', 90000, 'occupied', NOW()),
            ('tbl-009', 'cmp-003', 'br-003', 'B03', 'pool', 70000, 'available', NOW()),
            ('tbl-010', 'cmp-004', 'br-004', 'B01', 'french', 95000, 'available', NOW()),
            ('tbl-011', 'cmp-004', 'br-004', 'B02', 'french', 95000, 'occupied', NOW()),
            ('tbl-012', 'cmp-004', 'br-004', 'B03', 'pool', 75000, 'available', NOW()),
            ('tbl-013', 'cmp-005', 'br-005', 'B01', 'carom', 80000, 'available', NOW()),
            ('tbl-014', 'cmp-005', 'br-005', 'B02', 'french', 100000, 'available', NOW()),
            ('tbl-015', 'cmp-005', 'br-005', 'B03', 'pool', 70000, 'occupied', NOW())
        ON CONFLICT (id) DO NOTHING;
        """
        cur.execute(tables_sql)
        print(f"✅ Inserted {cur.rowcount} tables")
        
        # 4. Insert 10 sample users (2 per branch)
        print("\n4️⃣ Inserting users...")
        users_sql = """
        INSERT INTO users (id, company_id, branch_id, email, full_name, phone, role, is_active, created_at)
        VALUES 
            ('usr-001', 'cmp-001', 'br-001', 'manager1@sabo.vn', 'Nguyễn Văn A', '0901111111', 'manager', true, NOW()),
            ('usr-002', 'cmp-001', 'br-001', 'staff1@sabo.vn', 'Trần Văn B', '0901111112', 'staff', true, NOW()),
            ('usr-003', 'cmp-002', 'br-002', 'manager2@sabo.vn', 'Trần Thị B', '0901111113', 'manager', true, NOW()),
            ('usr-004', 'cmp-002', 'br-002', 'staff2@sabo.vn', 'Lê Thị C', '0901111114', 'staff', true, NOW()),
            ('usr-005', 'cmp-003', 'br-003', 'manager3@sabo.vn', 'Lê Văn C', '0901111115', 'manager', true, NOW()),
            ('usr-006', 'cmp-003', 'br-003', 'staff3@sabo.vn', 'Phạm Văn D', '0901111116', 'staff', true, NOW()),
            ('usr-007', 'cmp-004', 'br-004', 'manager4@sabo.vn', 'Phạm Văn D', '0901111117', 'manager', true, NOW()),
            ('usr-008', 'cmp-004', 'br-004', 'staff4@sabo.vn', 'Hoàng Thị E', '0901111118', 'staff', true, NOW()),
            ('usr-009', 'cmp-005', 'br-005', 'manager5@sabo.vn', 'Hoàng Thị E', '0901111119', 'manager', true, NOW()),
            ('usr-010', 'cmp-005', 'br-005', 'staff5@sabo.vn', 'Võ Văn F', '0901111120', 'staff', true, NOW())
        ON CONFLICT (id) DO NOTHING;
        """
        cur.execute(users_sql)
        print(f"✅ Inserted {cur.rowcount} users")
        
        # 5. Insert 10 sample tasks
        print("\n5️⃣ Inserting tasks...")
        tasks_sql = """
        INSERT INTO tasks (id, company_id, branch_id, title, description, assigned_to, status, priority, due_date, created_at)
        VALUES 
            ('tsk-001', 'cmp-001', 'br-001', 'Kiểm tra thiết bị bàn B01', 'Kiểm tra và bảo trì bàn bi-a số 1', 'usr-002', 'pending', 'high', CURRENT_DATE + INTERVAL '2 days', NOW()),
            ('tsk-002', 'cmp-001', 'br-001', 'Dọn dẹp khu vực chơi', 'Vệ sinh tổng thể khu vực', 'usr-002', 'in_progress', 'medium', CURRENT_DATE + INTERVAL '1 day', NOW()),
            ('tsk-003', 'cmp-002', 'br-002', 'Kiểm kê đồ uống', 'Kiểm tra số lượng đồ uống trong kho', 'usr-004', 'pending', 'low', CURRENT_DATE + INTERVAL '3 days', NOW()),
            ('tsk-004', 'cmp-002', 'br-002', 'Sửa chữa bàn B02', 'Thay nỉ bàn bi-a số 2', 'usr-004', 'in_progress', 'high', CURRENT_DATE + INTERVAL '1 day', NOW()),
            ('tsk-005', 'cmp-003', 'br-003', 'Training nhân viên mới', 'Đào tạo quy trình phục vụ', 'usr-006', 'completed', 'medium', CURRENT_DATE - INTERVAL '1 day', NOW()),
            ('tsk-006', 'cmp-003', 'br-003', 'Kiểm tra hệ thống điện', 'Kiểm tra an toàn điện', 'usr-006', 'pending', 'high', CURRENT_DATE + INTERVAL '2 days', NOW()),
            ('tsk-007', 'cmp-004', 'br-004', 'Chuẩn bị event cuối tuần', 'Tổ chức giải đấu bi-a', 'usr-008', 'in_progress', 'high', CURRENT_DATE + INTERVAL '5 days', NOW()),
            ('tsk-008', 'cmp-004', 'br-004', 'Báo cáo doanh thu tháng', 'Tổng hợp doanh thu tháng trước', 'usr-007', 'pending', 'medium', CURRENT_DATE + INTERVAL '7 days', NOW()),
            ('tsk-009', 'cmp-005', 'br-005', 'Đặt hàng thiết bị mới', 'Order thêm cơ bi-a và phấn', 'usr-009', 'pending', 'medium', CURRENT_DATE + INTERVAL '4 days', NOW()),
            ('tsk-010', 'cmp-005', 'br-005', 'Kiểm tra camera an ninh', 'Maintenance hệ thống camera', 'usr-010', 'in_progress', 'low', CURRENT_DATE + INTERVAL '3 days', NOW())
        ON CONFLICT (id) DO NOTHING;
        """
        cur.execute(tasks_sql)
        print(f"✅ Inserted {cur.rowcount} tasks")
        
        # 6. Insert 30 days of revenue data (last 30 days)
        print("\n6️⃣ Inserting daily revenue data...")
        revenue_records = []
        for i in range(30):
            date = (datetime.now() - timedelta(days=i)).date()
            # Generate revenue for each branch
            for branch_idx in range(1, 6):
                branch_id = f'br-{branch_idx:03d}'
                company_id = f'cmp-{branch_idx:03d}'
                # Random-ish revenue between 2M - 8M per day
                base_revenue = 2000000 + (branch_idx * 500000)
                daily_variance = (i % 7) * 300000  # Weekly pattern
                total_revenue = base_revenue + daily_variance
                
                revenue_records.append(
                    f"('{date}', '{company_id}', '{branch_id}', {total_revenue}, NOW())"
                )
        
        revenue_sql = f"""
        INSERT INTO daily_revenue (date, company_id, branch_id, total_revenue, created_at)
        VALUES {', '.join(revenue_records)}
        ON CONFLICT (date, company_id, branch_id) DO NOTHING;
        """
        cur.execute(revenue_sql)
        print(f"✅ Inserted {cur.rowcount} daily revenue records")
        
        # 7. Insert activity logs
        print("\n7️⃣ Inserting activity logs...")
        activity_sql = """
        INSERT INTO activity_logs (id, company_id, branch_id, user_id, action, entity_type, entity_id, description, created_at)
        VALUES 
            ('log-001', 'cmp-001', 'br-001', 'usr-001', 'create', 'task', 'tsk-001', 'Created new maintenance task', NOW() - INTERVAL '5 hours'),
            ('log-002', 'cmp-001', 'br-001', 'usr-002', 'update', 'task', 'tsk-002', 'Started cleaning task', NOW() - INTERVAL '4 hours'),
            ('log-003', 'cmp-002', 'br-002', 'usr-003', 'create', 'table', 'tbl-004', 'Added new billiard table', NOW() - INTERVAL '3 hours'),
            ('log-004', 'cmp-003', 'br-003', 'usr-005', 'complete', 'task', 'tsk-005', 'Completed staff training', NOW() - INTERVAL '2 hours'),
            ('log-005', 'cmp-004', 'br-004', 'usr-007', 'create', 'task', 'tsk-007', 'Created event preparation task', NOW() - INTERVAL '1 hour')
        ON CONFLICT (id) DO NOTHING;
        """
        cur.execute(activity_sql)
        print(f"✅ Inserted {cur.rowcount} activity logs")
        
        # Commit transaction
        conn.commit()
        
        print("\n" + "="*60)
        print("✨ Sample data seeding completed successfully!")
        print("="*60)
        print("\n📊 Summary:")
        print("  • 5 Companies")
        print("  • 5 Branches")
        print("  • 15 Tables")
        print("  • 10 Users")
        print("  • 10 Tasks")
        print("  • 150 Daily Revenue Records (30 days × 5 branches)")
        print("  • 5 Activity Logs")
        print("\n🎯 Database is now ready for development and testing!")
        
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"\n❌ Error seeding data: {e}")
        raise
    finally:
        if conn:
            cur.close()
            conn.close()
            print("\n🔌 Database connection closed")

if __name__ == '__main__':
    seed_sample_data()
