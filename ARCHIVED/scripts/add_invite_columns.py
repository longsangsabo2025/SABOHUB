"""
Add invite token columns to users table for employee onboarding flow
Run this script to update your Supabase database
"""

import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

def add_invite_columns():
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    
    if not supabase_url or not supabase_key:
        print("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
        return
    
    supabase = create_client(supabase_url, supabase_key)
    
    print("🔧 Adding invite token columns to users table...")
    
    # SQL migration
    sql = """
    -- Add invite token columns
    ALTER TABLE public.users 
    ADD COLUMN IF NOT EXISTS invite_token UUID DEFAULT gen_random_uuid(),
    ADD COLUMN IF NOT EXISTS invite_expires_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS onboarded_at TIMESTAMPTZ;
    
    -- Create index
    CREATE INDEX IF NOT EXISTS idx_users_invite_token ON public.users(invite_token) WHERE invite_token IS NOT NULL;
    """
    
    try:
        result = supabase.rpc('exec_sql', {'sql': sql}).execute()
        print("✅ Successfully added invite columns!")
        print("📋 Columns added:")
        print("   - invite_token (UUID)")
        print("   - invite_expires_at (TIMESTAMPTZ)")
        print("   - invited_at (TIMESTAMPTZ)")
        print("   - onboarded_at (TIMESTAMPTZ)")
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n💡 Please run this SQL manually in Supabase SQL Editor:")
        print(sql)

if __name__ == "__main__":
    add_invite_columns()
