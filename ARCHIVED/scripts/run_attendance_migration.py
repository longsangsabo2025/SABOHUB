import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🚀 RUNNING ATTENDANCE SCHEMA MIGRATION")
print("=" * 80)

# Read migration file
migration_file = "supabase/migrations/20251113_fix_attendance_schema.sql"
with open(migration_file, 'r', encoding='utf-8') as f:
    migration_sql = f.read()

print(f"📄 Loaded migration: {migration_file}")
print("=" * 80)

try:
    # Execute migration using service role
    print("\n⚡ Executing migration...")
    print("-" * 80)
    
    # Note: We can't directly execute multi-statement SQL via Supabase client
    # We'll break it into logical parts
    
    # For now, show the user they need to run it in Supabase SQL Editor
    print("\n⚠️  IMPORTANT: This migration needs to be run in Supabase SQL Editor")
    print("\nSteps:")
    print("1. Go to: https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/sql/new")
    print("2. Copy the SQL from: supabase/migrations/20251113_fix_attendance_schema.sql")
    print("3. Paste and execute in SQL Editor")
    print("\nOR run this command if you have Supabase CLI:")
    print("  supabase db push")
    
    print("\n" + "=" * 80)
    print("⏳ Waiting for manual execution...")
    print("=" * 80)
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    print("\nPlease run migration manually in Supabase SQL Editor")
