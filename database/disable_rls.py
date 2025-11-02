#!/usr/bin/env python3
"""Disable RLS on companies table"""

import os
from dotenv import load_dotenv
import psycopg2
from pathlib import Path

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
if not conn_str:
    print("Error: SUPABASE_CONNECTION_STRING not found")
    exit(1)

if '?' in conn_str:
    conn_str = conn_str.split('?')[0]

print("Disabling RLS on companies table...")
print("=" * 60)

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Drop all policies
    cur.execute("""
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'companies';
    """)
    
    policies = cur.fetchall()
    print(f"\nDropping {len(policies)} policies:")
    for p in policies:
        print(f"  - {p[0]}")
        cur.execute(f"DROP POLICY IF EXISTS {p[0]} ON companies;")
    
    # Disable RLS
    cur.execute("ALTER TABLE companies DISABLE ROW LEVEL SECURITY;")
    
    conn.commit()
    
    print("\n✅ RLS DISABLED on companies table!")
    print("✅ All policies removed!")
    print("\n🎉 Now anyone can do anything with companies table!")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
