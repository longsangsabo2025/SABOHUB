#!/usr/bin/env python3
"""Check attendance table schema"""

import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

conn = psycopg2.connect(conn_string)
cur = conn.cursor()

# Get columns
cur.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'attendance'
    ORDER BY ordinal_position;
""")
columns = cur.fetchall()

print("📋 Attendance Table Columns:")
for col, dtype, nullable in columns:
    print(f"   - {col}: {dtype} (nullable: {nullable})")

# Get existing policies
cur.execute("""
    SELECT policyname, cmd
    FROM pg_policies
    WHERE tablename = 'attendance';
""")
policies = cur.fetchall()

print(f"\n🔐 RLS Policies ({len(policies)} total):")
for name, cmd in policies:
    print(f"   - {name} ({cmd})")

cur.close()
conn.close()
