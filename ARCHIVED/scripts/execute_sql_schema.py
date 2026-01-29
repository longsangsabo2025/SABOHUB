#!/usr/bin/env python3
"""
Execute SQL directly to create daily_work_reports table
"""
import psycopg2
from dotenv import load_dotenv
import os
from urllib.parse import urlparse

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

# Parse connection string from Supabase URL
# Format: postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
# We'll construct it from the Supabase URL

def get_db_connection_string():
    """Get PostgreSQL connection string"""
    # Extract project ref from URL
    parsed = urlparse(SUPABASE_URL)
    project_ref = parsed.hostname.split('.')[0]  # dqddxowyikefqcdiioyh
    
    # For direct PostgreSQL connection, we need the password
    # This is typically stored separately, not in the service role key
    print(f"Project Ref: {project_ref}")
    print("\n⚠️  To connect directly to PostgreSQL, we need:")
    print("1. Database Password (different from Service Role Key)")
    print("2. Connection string format:")
    print(f"   postgresql://postgres:[PASSWORD]@db.{project_ref}.supabase.co:5432/postgres")
    print("\n📋 Get your database password from:")
    print(f"   https://supabase.com/dashboard/project/{project_ref}/settings/database")
    print("\n💡 Alternative: Run the SQL manually in Supabase SQL Editor")
    return None

def execute_sql_file():
    """Execute SQL from file"""
    conn_string = get_db_connection_string()
    
    if not conn_string:
        print("\n" + "="*80)
        print("📝 MANUAL SETUP INSTRUCTIONS:")
        print("="*80)
        print("\n1. Open Supabase Dashboard:")
        print("   https://dqddxowyikefqcdiioyh.supabase.co/project/_/sql/new")
        print("\n2. Copy SQL from file:")
        print("   daily_work_reports_schema.sql")
        print("\n3. Paste and run in SQL Editor")
        print("\n4. Verify table created:")
        print("   SELECT * FROM daily_work_reports LIMIT 1;")
        print("="*80)
        return False
    
    return True

if __name__ == '__main__':
    print("=" * 80)
    print("🔧 SABOHUB - Execute SQL Schema")
    print("=" * 80)
    
    execute_sql_file()
