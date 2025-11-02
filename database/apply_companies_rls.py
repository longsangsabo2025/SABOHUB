#!/usr/bin/env python3
"""Apply RLS policies to companies table"""

import os
from dotenv import load_dotenv
import psycopg2
from pathlib import Path

# Load environment from root .env file
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

# Parse connection string  
conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
if not conn_str:
    print("❌ Error: SUPABASE_CONNECTION_STRING not found in .env")
    exit(1)
# Remove ?sslmode parameter if exists
if '?' in conn_str:
    conn_str = conn_str.split('?')[0]

print("🔐 Applying RLS policies to companies table...")
print("=" * 60)

try:
    # Connect to database
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Read SQL file from same directory as script
    sql_path = Path(__file__).parent / 'fix_companies_rls.sql'
    with open(sql_path, 'r') as f:
        sql = f.read()
    
    # Execute SQL
    cur.execute(sql)
    conn.commit()
    
    print("✅ RLS policies applied successfully!")
    
    # Verify policies
    cur.execute("""
        SELECT schemaname, tablename, policyname, permissive, roles, cmd
        FROM pg_policies
        WHERE tablename = 'companies'
        ORDER BY policyname;
    """)
    
    policies = cur.fetchall()
    print(f"\n📋 Found {len(policies)} policies on companies table:")
    for policy in policies:
        print(f"  - {policy[2]}: {policy[5]} for {policy[4]}")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
    exit(1)
