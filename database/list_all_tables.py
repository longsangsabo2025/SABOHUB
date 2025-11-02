#!/usr/bin/env python3
"""Check all tables in database"""

import os
from dotenv import load_dotenv
import psycopg2

load_dotenv('.env')

conn_str = os.getenv('SUPABASE_CONNECTION_STRING')

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Get all tables
    cur.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        ORDER BY table_name;
    """)
    
    tables = cur.fetchall()
    print("📋 PUBLIC SCHEMA TABLES:")
    print("=" * 40)
    for table in tables:
        print(f"  - {table[0]}")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
