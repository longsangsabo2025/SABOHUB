"""
Apply Tasks Management Migration to Supabase
Creates tables: tasks, task_comments, task_attachments, task_approvals
"""
import os
import sys
from pathlib import Path
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# Database connection string
CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def run_migration():
    """Execute the tasks tables migration"""
    try:
        print("🚀 Connecting to Supabase...")
        conn = psycopg2.connect(CONNECTION_STRING)
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Read migration file
        migration_file = Path(__file__).parent / "migrations" / "create_tasks_tables.sql"
        print(f"📝 Reading migration: {migration_file.name}")
        
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql = f.read()
        
        print("⚙️  Executing migration...")
        print("   Creating tables: tasks, task_comments, task_attachments, task_approvals")
        
        # Execute the migration
        cursor.execute(sql)
        
        print("\n✅ Migration executed successfully!")
        print("\n📊 Created tables:")
        print("  ✓ tasks - Main task management")
        print("  ✓ task_comments - Task discussions")  
        print("  ✓ task_attachments - File uploads")
        print("  ✓ task_approvals - CEO approval workflow")
        print("\n🔐 RLS policies enabled for all tables")
        print("\n💡 Tables are ready for use!")
        
        # Verify tables were created
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name IN ('tasks', 'task_comments', 'task_attachments', 'task_approvals')
            ORDER BY table_name
        """)
        
        tables = cursor.fetchall()
        if len(tables) == 4:
            print(f"\n✅ Verified: All 4 tables created successfully")
        else:
            print(f"\n⚠️  Warning: Only {len(tables)} tables found")
        
        cursor.close()
        conn.close()
        
        return True
        
    except psycopg2.Error as e:
        print(f"\n❌ Database error: {e}")
        print(f"   Code: {e.pgcode}")
        print(f"   Details: {e.pgerror}")
        return False
    except FileNotFoundError:
        print(f"\n❌ Migration file not found: {migration_file}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
