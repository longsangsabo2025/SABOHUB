import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

print("=" * 70)
print("KIEM TRA SCHEMA BANG TASKS")
print("=" * 70)

cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'tasks'
    ORDER BY ordinal_position;
""")

columns = cur.fetchall()
print(f"\nCac columns trong tasks table ({len(columns)} columns):\n")
for col in columns:
    print(f"  {col[0]:30s} - {col[1]}")

# Check specific fields
print("\n" + "=" * 70)
print("CHECK: Co cac truong name khong?")
print("=" * 70)

name_fields = ['assigned_to_name', 'created_by_name', 'assigned_to_role']
for field in name_fields:
    exists = any(col[0] == field for col in columns)
    print(f"  {'✅' if exists else '❌'} {field}")

cur.close()
conn.close()
