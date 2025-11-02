#!/usr/bin/env python3
"""Drop business_type check constraint"""

import os
from dotenv import load_dotenv
import psycopg2
from pathlib import Path

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
if conn_str and '?' in conn_str:
    conn_str = conn_str.split('?')[0]

print("Dropping business_type constraint...")
print("=" * 60)

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Drop constraint
    cur.execute("ALTER TABLE companies DROP CONSTRAINT IF EXISTS companies_business_type_check;")
    conn.commit()
    
    print("\nSUCCESS! business_type constraint DROPPED!")
    print("\nNow you can insert ANY value for business_type!")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\nERROR: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
