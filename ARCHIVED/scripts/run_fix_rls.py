#!/usr/bin/env python3
"""
Quick fix RLS policies for companies table
"""
import os
from supabase import create_client

# Load environment variables
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

print("🔧 Fixing Companies RLS Policies...")

# Read SQL file
with open('fix_companies_rls_simple.sql', 'r', encoding='utf-8') as f:
    sql_script = f.read()

try:
    # Execute SQL
    result = supabase.rpc('exec_sql', {'query': sql_script}).execute()
    print("✅ RLS policies fixed successfully!")
    print(result)
except Exception as e:
    print(f"❌ Error: {e}")
    print("\n🔄 Trying alternative method...")
    
    # Alternative: Execute via PostgREST
    import psycopg2
    conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    try:
        cur.execute(sql_script)
        conn.commit()
        print("✅ RLS policies fixed via direct connection!")
    except Exception as e2:
        print(f"❌ Direct connection error: {e2}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()
