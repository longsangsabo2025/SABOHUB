"""
Create task_templates tables via direct SQL execution
This uses psycopg2 to connect directly to PostgreSQL
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Get database connection string from .env
db_url = os.environ.get("DATABASE_URL") or os.environ.get("SUPABASE_DB_URL")

if not db_url:
    print("❌ DATABASE_URL not found in .env file")
    print("Please add it like: DATABASE_URL=postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres")
    exit(1)

def run_migration():
    print("🚀 Connecting to database...")
    
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        print("✅ Connected! Creating tables...")
        
        # Read and execute SQL file
        with open('create_task_templates_table.sql', 'r', encoding='utf-8') as f:
            sql = f.read()
        
        cur.execute(sql)
        conn.commit()
        
        print("✅ task_templates table created successfully!")
        
        # Verify
        cur.execute("SELECT COUNT(*) FROM task_templates")
        count = cur.fetchone()[0]
        print(f"📊 Current templates: {count}")
        
        cur.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n💡 Alternative: Run SQL manually in Supabase SQL Editor")
        print("   File: create_task_templates_table.sql")
        return False

if __name__ == "__main__":
    run_migration()
