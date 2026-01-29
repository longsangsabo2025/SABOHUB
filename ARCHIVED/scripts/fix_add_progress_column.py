"""
Add progress column to tasks table - Simple version
"""
import os
from dotenv import load_dotenv
import requests

load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

def run_migration():
    """Run SQL migration to add progress column"""
    
    # SQL to add progress column
    sql_statements = [
        """
        ALTER TABLE public.tasks 
        ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0 
        CHECK (progress >= 0 AND progress <= 100);
        """,
        """
        UPDATE public.tasks
        SET progress = CASE 
            WHEN status = 'COMPLETED' THEN 100
            WHEN status = 'IN_PROGRESS' THEN 50
            ELSE 0
        END
        WHERE progress = 0;
        """,
        """
        CREATE INDEX IF NOT EXISTS idx_tasks_progress ON public.tasks(progress);
        """
    ]
    
    # Execute each SQL statement using Supabase REST API
    headers = {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json"
    }
    
    for i, sql in enumerate(sql_statements, 1):
        try:
            # Use PostgREST to execute SQL
            print(f"Executing statement {i}...")
            
            # We'll use psycopg2 if available, otherwise give instructions
            try:
                import psycopg2
                
                conn_string = os.getenv("SUPABASE_CONNECTION_STRING")
                conn = psycopg2.connect(conn_string)
                cur = conn.cursor()
                
                cur.execute(sql)
                conn.commit()
                
                cur.close()
                conn.close()
                
                print(f"✅ Statement {i} executed successfully")
                
            except ImportError:
                print("⚠️  psycopg2 not installed. Install it with: pip install psycopg2-binary")
                print(f"\nPlease run this SQL manually in Supabase SQL Editor:")
                print("="*60)
                print(sql)
                print("="*60)
                return False
                
        except Exception as e:
            print(f"❌ Error executing statement {i}: {str(e)}")
            return False
    
    print("\n✅ Migration completed successfully!")
    print("The 'progress' column has been added to the tasks table.")
    return True

if __name__ == "__main__":
    print("🔧 Adding progress column to tasks table...\n")
    run_migration()
