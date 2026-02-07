import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-nexus/.env')

conn = psycopg2.connect(os.getenv('VITE_SUPABASE_POOLER_URL'))
cur = conn.cursor()

cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'sales_orders'
    ORDER BY ordinal_position
""")
print('sales_orders columns:')
for row in cur.fetchall():
    print(f'  {row[0]}: {row[1]}')

cur.close()
conn.close()
