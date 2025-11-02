#!/usr/bin/env python3
"""
Check existing tables in Supabase database
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
if not conn_string:
    print("❌ Missing SUPABASE_CONNECTION_STRING")
    exit(1)

print("🔌 Connecting to database...")
conn = psycopg2.connect(conn_string)
cursor = conn.cursor()

print("📋 Checking existing tables in public schema:\n")

cursor.execute("""
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    ORDER BY tablename;
""")

tables = cursor.fetchall()
if tables:
    for (table,) in tables:
        print(f"  ✓ {table}")
else:
    print("  ❌ No tables found in public schema")

print(f"\n📊 Total: {len(tables)} tables")

cursor.close()
conn.close()
