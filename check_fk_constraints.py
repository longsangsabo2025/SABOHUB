import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

print("=" * 80)
print("CHECK FOREIGN KEY CONSTRAINTS ON TASKS TABLE")
print("=" * 80)

cur.execute("""
    SELECT
        tc.constraint_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'tasks'
    AND tc.table_schema = 'public'
    ORDER BY kcu.column_name
""")

fks = cur.fetchall()
print("\nForeign keys on tasks table:")
for fk in fks:
    print(f"  Column: {fk[1]}")
    print(f"    Constraint: {fk[0]}")
    print(f"    References: {fk[2]}.{fk[3]}")
    print()

print("=" * 80)
print("CHECK DAILY_REVENUE TABLE SCHEMA")
print("=" * 80)

cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'daily_revenue'
    AND table_schema = 'public'
    ORDER BY ordinal_position
""")

cols = cur.fetchall()
print("\ndaily_revenue table columns:")
for col in cols:
    print(f"  {col[0]}: {col[1]}")

cur.close()
conn.close()
