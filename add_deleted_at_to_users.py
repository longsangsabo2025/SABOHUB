"""
Add deleted_at column to users table for soft delete functionality
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("🔧 Adding deleted_at column to users table...")

try:
    # Add deleted_at column (PostgreSQL uses TIMESTAMP WITH TIME ZONE)
    supabase.rpc('exec_sql', {
        'sql': 'ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;'
    }).execute()
    
    print("✅ deleted_at column added successfully!")
    
    # Verify
    result = supabase.table('users').select('id, deleted_at').limit(1).execute()
    print(f"✅ Verified: {len(result.data)} users queried with deleted_at column")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print("\nTrying alternative method using SQL Editor...")
    print("\nPlease run this SQL manually in Supabase SQL Editor:")
    print("="*60)
    print("ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;")
    print("="*60)
