#!/usr/bin/env python3
"""Check companies table schema"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

print("\n📊 COMPANIES TABLE STRUCTURE:")
print("="*60)

cur.execute("""
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'companies'
    ORDER BY ordinal_position;
""")

for col in cur.fetchall():
    print(f"{col[0]:20s} {col[1]:20s} {'NULL' if col[2]=='YES' else 'NOT NULL':10s} {col[3] or ''}")

cur.close()
conn.close()
