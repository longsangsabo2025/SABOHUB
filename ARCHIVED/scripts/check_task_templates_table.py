"""
Simplified migration - execute SQL directly via postgrest
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

def run_migration():
    print("🚀 Creating task_templates table...")
    
    # Try to create table by checking if it exists first
    try:
        # Try to select from task_templates
        result = supabase.table('task_templates').select('id').limit(1).execute()
        print("✅ task_templates table already exists!")
        print(f"Found {len(result.data)} records")
        return True
    except Exception as e:
        error_msg = str(e)
        if "relation" in error_msg and "does not exist" in error_msg:
            print("📝 Table doesn't exist yet.")
            print("\n" + "="*80)
            print("Please run the SQL from 'create_task_templates_table.sql'")
            print("in your Supabase SQL Editor:")
            print("="*80)
            print("\n1. Go to: https://supabase.com/dashboard/project/[your-project]/sql/new")
            print("2. Copy content from: create_task_templates_table.sql")
            print("3. Click 'Run' button")
            print("4. Run this script again to verify")
            return False
        else:
            print(f"❌ Error: {error_msg}")
            return False

if __name__ == "__main__":
    success = run_migration()
    if success:
        print("\n🎉 Migration completed successfully!")
    else:
        print("\n⚠️  Please run SQL manually in Supabase dashboard")
