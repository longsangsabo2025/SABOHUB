"""
Check manager_permissions table structure
"""
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

# Get all columns
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'manager_permissions'
    ORDER BY ordinal_position
""")

cols = cur.fetchall()

print("=" * 60)
print("MANAGER_PERMISSIONS TABLE STRUCTURE")
print("=" * 60)

for col_name, data_type in cols:
    print(f"  - {col_name}: {data_type}")

print(f"\nTotal columns: {len(cols)}")

cur.close()
conn.close()
