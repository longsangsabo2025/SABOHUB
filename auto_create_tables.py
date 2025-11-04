"""
Auto-run SQL migration to create task_templates tables
Uses direct PostgreSQL connection
"""
import os
import sys

# Check if psycopg2 is available
try:
    import psycopg2
    from psycopg2 import sql
except ImportError:
    print("❌ psycopg2 not installed")
    print("Installing psycopg2-binary...")
    os.system("pip install psycopg2-binary")
    import psycopg2
    from psycopg2 import sql

# Connection string from .env
DB_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def run_migration():
    print("🚀 Connecting to Supabase PostgreSQL...")
    
    try:
        # Connect to database
        conn = psycopg2.connect(DB_URL)
        conn.autocommit = True
        cur = conn.cursor()
        
        print("✅ Connected successfully!")
        print("📝 Reading SQL file...")
        
        # Read SQL file
        with open('create_task_templates_table.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("⚡ Executing SQL migration...")
        
        # Execute SQL
        cur.execute(sql_content)
        
        print("✅ SQL executed successfully!")
        
        # Verify tables created
        print("\n🔍 Verifying tables...")
        
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name IN ('task_templates', 'recurring_task_instances')
            ORDER BY table_name
        """)
        
        tables = cur.fetchall()
        print(f"\n📊 Tables created: {len(tables)}")
        for table in tables:
            print(f"   ✅ {table[0]}")
        
        # Check columns in task_templates
        cur.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'task_templates'
            ORDER BY ordinal_position
            LIMIT 10
        """)
        
        columns = cur.fetchall()
        print(f"\n📋 task_templates columns (first 10):")
        for col in columns:
            print(f"   • {col[0]} ({col[1]})")
        
        # Check initial record count
        cur.execute("SELECT COUNT(*) FROM task_templates")
        count = cur.fetchone()[0]
        print(f"\n📊 Current templates in DB: {count}")
        
        cur.close()
        conn.close()
        
        print("\n🎉 Migration completed successfully!")
        print("\n✨ Next step: Implement TaskTemplateService and UI")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print(f"\nError type: {type(e).__name__}")
        
        if "password authentication failed" in str(e):
            print("\n💡 Tip: Check database password in connection string")
        elif "could not connect" in str(e):
            print("\n💡 Tip: Check network connection and database URL")
        
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
