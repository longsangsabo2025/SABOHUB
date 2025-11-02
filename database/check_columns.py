#!/usr/bin/env python3
import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

print("STORES TABLE COLUMNS:")
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'stores' AND table_schema = 'public' ORDER BY ordinal_position;")
columns = cur.fetchall()
for col in columns:
    print(f"  {col[0]}: {col[1]}")

print("\nCOMPANIES TABLE COLUMNS:")
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'companies' AND table_schema = 'public' ORDER BY ordinal_position;")
columns = cur.fetchall()
for col in columns:
    print(f"  {col[0]}: {col[1]}")

cur.close()
conn.close()