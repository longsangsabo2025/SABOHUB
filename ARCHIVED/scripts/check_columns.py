#!/usr/bin/env python3
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

print("EMPLOYEES TABLE COLUMNS:")
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'employees' AND table_schema = 'public' 
    ORDER BY ordinal_position;
""")
for row in cur.fetchall():
    print(f"  - {row[0]} ({row[1]})")

print("\nTASKS TABLE COLUMNS:")
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'tasks' AND table_schema = 'public' 
    ORDER BY ordinal_position;
""")
for row in cur.fetchall():
    print(f"  - {row[0]} ({row[1]})")

cur.close()
conn.close()
