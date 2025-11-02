#!/usr/bin/env python3
"""
🔧 SUPABASE DATABASE MIGRATOR
Tạo các bảng thiếu dựa trên cấu trúc hiện có
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

def connect_to_supabase():
    """Kết nối đến Supabase database"""
    connection_string = os.getenv('SUPABASE_CONNECTION_STRING')
    if not connection_string:
        print("❌ SUPABASE_CONNECTION_STRING not found in .env")
        return None
    
    try:
        conn = psycopg2.connect(connection_string)
        print("✅ Connected to Supabase database")
        return conn
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return None

def create_missing_tables(conn):
    """Tạo các bảng thiếu"""
    with conn.cursor() as cur:
        print("\n🔧 CREATING MISSING TABLES...")
        
        # 1. STORES TABLE (sử dụng branches làm stores)
        print("📊 Creating stores table (using branches structure)...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS stores (
              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
              company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
              name TEXT NOT NULL,
              code TEXT,
              address TEXT NOT NULL,
              phone TEXT,
              manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
              status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE')),
              created_at TIMESTAMPTZ DEFAULT NOW(),
              updated_at TIMESTAMPTZ DEFAULT NOW(),
              UNIQUE(company_id, code)
            );
        """)
        
        # 2. TABLES TABLE (bàn bi-a)
        print("📊 Creating tables table...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS tables (
              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
              store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
              company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
              name TEXT NOT NULL,
              table_type TEXT NOT NULL DEFAULT 'standard' CHECK (table_type IN ('standard', 'vip', 'premium')),
              hourly_rate DECIMAL(10,2) DEFAULT 0,
              status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'reserved', 'maintenance')),
              created_at TIMESTAMPTZ DEFAULT NOW(),
              updated_at TIMESTAMPTZ DEFAULT NOW(),
              UNIQUE(store_id, name)
            );
        """)
        
        # 3. TASKS TABLE
        print("📊 Creating tasks table...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
              company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
              store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
              title TEXT NOT NULL,
              description TEXT,
              priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
              assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
              created_by UUID REFERENCES users(id) ON DELETE SET NULL,
              status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
              due_date TIMESTAMPTZ,
              completed_at TIMESTAMPTZ,
              created_at TIMESTAMPTZ DEFAULT NOW(),
              updated_at TIMESTAMPTZ DEFAULT NOW()
            );
        """)
        
        # 4. Create indexes
        print("📊 Creating indexes...")
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_stores_company ON stores(company_id);
            CREATE INDEX IF NOT EXISTS idx_stores_manager ON stores(manager_id);
            CREATE INDEX IF NOT EXISTS idx_stores_status ON stores(status);
            
            CREATE INDEX IF NOT EXISTS idx_tables_store ON tables(store_id);
            CREATE INDEX IF NOT EXISTS idx_tables_company ON tables(company_id);
            CREATE INDEX IF NOT EXISTS idx_tables_status ON tables(status);
            
            CREATE INDEX IF NOT EXISTS idx_tasks_company ON tasks(company_id);
            CREATE INDEX IF NOT EXISTS idx_tasks_store ON tasks(store_id);
            CREATE INDEX IF NOT EXISTS idx_tasks_assigned ON tasks(assigned_to);
            CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
            CREATE INDEX IF NOT EXISTS idx_tasks_created ON tasks(created_at DESC);
        """)
        
        # 5. Migrate data from branches to stores (if needed)
        print("📊 Migrating data from branches to stores...")
        cur.execute("""
            INSERT INTO stores (id, company_id, name, code, address, phone, manager_id, status, created_at, updated_at)
            SELECT id, company_id, name, code, address, phone, manager_id, 
                   CASE 
                     WHEN is_active = true THEN 'ACTIVE'
                     ELSE 'INACTIVE'
                   END as status,
                   created_at, updated_at
            FROM branches
            ON CONFLICT (id) DO NOTHING;
        """)
        
        # 6. Insert sample tables data
        print("📊 Inserting sample tables data...")
        cur.execute("""
            INSERT INTO tables (store_id, company_id, name, table_type, hourly_rate, status)
            SELECT s.id, s.company_id, 
                   CASE 
                     WHEN ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.id) <= 3 THEN 'Bàn ' || ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.id)
                     ELSE 'VIP ' || (ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.id) - 3)
                   END as name,
                   CASE 
                     WHEN ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.id) <= 3 THEN 'standard'
                     ELSE 'vip'
                   END as table_type,
                   CASE 
                     WHEN ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.id) <= 3 THEN 50000
                     ELSE 80000
                   END as hourly_rate,
                   'available' as status
            FROM stores s
            CROSS JOIN generate_series(1, 5) -- 5 bàn mỗi store
            ON CONFLICT DO NOTHING;
        """)
        
        # 7. Insert sample tasks data
        print("📊 Inserting sample tasks data...")
        cur.execute("""
            INSERT INTO tasks (company_id, store_id, title, description, priority, status, created_by)
            SELECT c.id, s.id, 
                   'Dọn dẹp bàn ' || t.name,
                   'Vệ sinh và chuẩn bị bàn cho khách hàng',
                   'medium',
                   'pending',
                   (SELECT id FROM users WHERE company_id = c.id AND role = 'BRANCH_MANAGER' LIMIT 1)
            FROM companies c
            JOIN stores s ON s.company_id = c.id
            JOIN tables t ON t.store_id = s.id
            WHERE c.business_type = 'restaurant' -- Chỉ tạo task cho nhà hàng có bàn bi-a
            LIMIT 10
            ON CONFLICT DO NOTHING;
        """)
        
        conn.commit()
        print("✅ All tables created and data migrated successfully!")

def verify_migration(conn):
    """Kiểm tra kết quả migration"""
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        print("\n🔍 VERIFYING MIGRATION...")
        
        tables_to_check = ['stores', 'tables', 'tasks']
        for table_name in tables_to_check:
            cur.execute(f"SELECT COUNT(*) as count FROM {table_name};")
            count = cur.fetchone()['count']
            print(f"  📊 {table_name}: {count} rows")
        
        print("\n🎯 MIGRATION SUCCESSFUL!")

def main():
    """Main function"""
    print("🚀 Starting Supabase Database Migration...")
    
    conn = connect_to_supabase()
    if not conn:
        return
    
    try:
        create_missing_tables(conn)
        verify_migration(conn)
        
        print("\n✅ Migration completed successfully!")
        print("🎯 Database is now ready for SaboHub Flutter app!")
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        conn.rollback()
    finally:
        conn.close()
        print("🔌 Database connection closed")

if __name__ == "__main__":
    main()