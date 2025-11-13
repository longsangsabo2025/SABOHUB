import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

conn = psycopg2.connect(os.getenv("SUPABASE_CONNECTION_STRING"))
cur = conn.cursor()

print("\n🔍 CHECKING ALL TABLES AND THEIR COLUMNS\n")
print("="*80)

# Get all tables with created_by or company_id
cur.execute("""
    SELECT 
        t.table_name,
        string_agg(c.column_name, ', ') as key_columns
    FROM information_schema.tables t
    LEFT JOIN information_schema.columns c 
        ON t.table_name = c.table_name 
        AND t.table_schema = c.table_schema
        AND c.column_name IN ('company_id', 'created_by', 'branch_id')
    WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
    AND t.table_name NOT LIKE '%_old'
    AND t.table_name NOT LIKE 'pg_%'
    GROUP BY t.table_name
    HAVING string_agg(c.column_name, ', ') IS NOT NULL
    ORDER BY t.table_name
""")

tables = cur.fetchall()

print("\n📋 TABLES WITH FOREIGN KEYS:\n")
for table, columns in tables:
    print(f"   {table:<30} → {columns}")

print("\n" + "="*80 + "\n")

cur.close()
conn.close()
