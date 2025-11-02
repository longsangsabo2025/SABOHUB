#!/usr/bin/env python3
"""
Run SQL Migration via Supabase Transaction Pooler
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import os
import sys

# Connection string from .env
CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def run_migration(sql_file):
    """Run a SQL migration file"""
    print(f"🚀 Running migration: {sql_file}")
    print("=" * 80)
    
    try:
        # Read SQL file
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print(f"📄 Loaded SQL file ({len(sql_content)} characters)")
        
        # Connect to database
        print("🔌 Connecting to database...")
        conn = psycopg2.connect(CONNECTION_STRING)
        conn.autocommit = False  # Use transaction
        
        print("✅ Connected successfully!")
        
        # Execute SQL
        print("\n📊 Executing migration...")
        cursor = conn.cursor()
        
        try:
            cursor.execute(sql_content)
            conn.commit()
            print("✅ Migration executed successfully!")
            
            # Get any notices/messages
            for notice in conn.notices:
                print(notice.strip())
            
        except Exception as e:
            conn.rollback()
            print(f"❌ Migration failed: {str(e)}")
            return False
        finally:
            cursor.close()
        
        conn.close()
        print("\n✅ Migration completed successfully!")
        return True
        
    except FileNotFoundError:
        print(f"❌ Error: File not found: {sql_file}")
        return False
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def verify_migration_001():
    """Verify migration 001 results"""
    print("\n🔍 Verifying Migration 001...")
    print("=" * 80)
    
    try:
        conn = psycopg2.connect(CONNECTION_STRING)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Check branches count
        cursor.execute("SELECT COUNT(*) as count FROM branches WHERE deleted_at IS NULL")
        branches_count = cursor.fetchone()['count']
        print(f"✅ Active branches: {branches_count}")
        
        # Check stores soft deleted
        cursor.execute("SELECT COUNT(*) as count FROM stores WHERE deleted_at IS NOT NULL")
        deleted_stores = cursor.fetchone()['count']
        print(f"✅ Soft deleted stores: {deleted_stores}")
        
        # Check tables have branch_id
        cursor.execute("SELECT COUNT(*) as count FROM tables WHERE branch_id IS NOT NULL")
        tables_with_branch = cursor.fetchone()['count']
        print(f"✅ Tables with branch_id: {tables_with_branch}")
        
        # Check for orphaned records
        cursor.execute("""
            SELECT COUNT(*) as count FROM tables t
            WHERE NOT EXISTS (SELECT 1 FROM branches b WHERE b.id = t.branch_id)
        """)
        orphaned = cursor.fetchone()['count']
        if orphaned > 0:
            print(f"⚠️  Orphaned tables: {orphaned}")
        else:
            print("✅ No orphaned tables")
        
        cursor.close()
        conn.close()
        
        print("\n✅ Migration 001 verification passed!")
        return True
        
    except Exception as e:
        print(f"❌ Verification error: {str(e)}")
        return False

def verify_migration_002():
    """Verify migration 002 results"""
    print("\n🔍 Verifying Migration 002...")
    print("=" * 80)
    
    try:
        conn = psycopg2.connect(CONNECTION_STRING)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Check new tables exist
        cursor.execute("""
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name IN ('menu_items', 'orders', 'order_items', 'table_sessions')
            ORDER BY table_name
        """)
        tables = cursor.fetchall()
        print(f"✅ New tables created: {len(tables)}")
        for t in tables:
            print(f"   - {t['table_name']}")
        
        # Check menu items
        cursor.execute("SELECT COUNT(*) as count FROM menu_items WHERE deleted_at IS NULL")
        menu_count = cursor.fetchone()['count']
        print(f"✅ Menu items: {menu_count}")
        
        # Check functions
        cursor.execute("""
            SELECT routine_name FROM information_schema.routines
            WHERE routine_schema = 'public'
            AND (routine_name LIKE '%order%' OR routine_name LIKE '%session%')
            ORDER BY routine_name
        """)
        functions = cursor.fetchall()
        print(f"✅ Functions created: {len(functions)}")
        for f in functions:
            print(f"   - {f['routine_name']}")
        
        # Check views
        cursor.execute("""
            SELECT table_name FROM information_schema.views 
            WHERE table_schema = 'public'
            AND (table_name LIKE '%session%' OR table_name LIKE '%order%')
            ORDER BY table_name
        """)
        views = cursor.fetchall()
        print(f"✅ Views created: {len(views)}")
        for v in views:
            print(f"   - {v['table_name']}")
        
        cursor.close()
        conn.close()
        
        print("\n✅ Migration 002 verification passed!")
        return True
        
    except Exception as e:
        print(f"❌ Verification error: {str(e)}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python run_migration.py <migration_file>")
        print("\nAvailable migrations:")
        print("  001_consolidate_stores_branches.sql")
        print("  002_create_orders_sessions.sql")
        sys.exit(1)
    
    migration_file = sys.argv[1]
    
    # Add migrations/ prefix if not present
    if not migration_file.startswith('migrations/'):
        migration_file = f'migrations/{migration_file}'
    
    # Run migration
    success = run_migration(migration_file)
    
    if not success:
        sys.exit(1)
    
    # Verify based on migration number
    if '001' in migration_file:
        verify_migration_001()
    elif '002' in migration_file:
        verify_migration_002()
    
    print("\n" + "=" * 80)
    print("🎉 All done!")
    print("=" * 80)

if __name__ == "__main__":
    main()
