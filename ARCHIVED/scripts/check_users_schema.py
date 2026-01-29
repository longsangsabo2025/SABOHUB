import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name='users' 
    ORDER BY ordinal_position
""")
print("\n📋 USERS TABLE SCHEMA:")
for row in cur.fetchall():
    print(f"  - {row[0]}: {row[1]}")
cur.close()
conn.close()
