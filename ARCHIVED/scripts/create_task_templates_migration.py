"""
Create task_templates table for recurring tasks
"""
import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def run_migration():
    print("🚀 Creating task_templates table...")
    
    # Read SQL file
    with open('create_task_templates_table.sql', 'r', encoding='utf-8') as f:
        sql = f.read()
    
    try:
        # Execute SQL
        result = supabase.rpc('exec_sql', {'sql': sql}).execute()
        print("✅ task_templates table created successfully!")
        print(f"Result: {result}")
        return True
    except Exception as e:
        # If exec_sql doesn't exist, try direct execution
        print(f"⚠️  exec_sql RPC not found, trying alternative method...")
        print(f"Please run this SQL manually in Supabase SQL Editor:")
        print("\n" + "="*80)
        print(sql)
        print("="*80 + "\n")
        return False

if __name__ == "__main__":
    run_migration()
