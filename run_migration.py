"""
Auto-run migration to add invite token columns
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

def run_migration():
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    
    if not supabase_url or not supabase_key:
        print("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
        return
    
    print("🔧 Connecting to Supabase...")
    supabase = create_client(supabase_url, supabase_key)
    
    print("📊 Adding invite token columns to users table...")
    
    # Run migration SQL
    sql_commands = [
        """
        ALTER TABLE public.users 
        ADD COLUMN IF NOT EXISTS invite_token TEXT,
        ADD COLUMN IF NOT EXISTS invite_expires_at TIMESTAMPTZ,
        ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ,
        ADD COLUMN IF NOT EXISTS onboarded_at TIMESTAMPTZ;
        """,
        """
        CREATE INDEX IF NOT EXISTS idx_users_invite_token 
        ON public.users(invite_token) 
        WHERE invite_token IS NOT NULL;
        """
    ]
    
    try:
        # Execute via RPC (if you have exec_sql function)
        # OR use psycopg2 directly with connection string
        import psycopg2
        
        conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
        if not conn_string:
            print("❌ Missing SUPABASE_CONNECTION_STRING")
            print("\n📋 Please run this SQL manually in Supabase SQL Editor:")
            for cmd in sql_commands:
                print(cmd)
            return
        
        conn = psycopg2.connect(conn_string)
        cur = conn.cursor()
        
        for sql in sql_commands:
            print(f"⚙️ Executing: {sql[:50]}...")
            cur.execute(sql)
        
        conn.commit()
        cur.close()
        conn.close()
        
        print("✅ Migration completed successfully!")
        print("📋 Columns added:")
        print("   - invite_token (TEXT)")
        print("   - invite_expires_at (TIMESTAMPTZ)")
        print("   - invited_at (TIMESTAMPTZ)")
        print("   - onboarded_at (TIMESTAMPTZ)")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n📋 Please run this SQL manually in Supabase SQL Editor:")
        for cmd in sql_commands:
            print(cmd)

if __name__ == "__main__":
    run_migration()
