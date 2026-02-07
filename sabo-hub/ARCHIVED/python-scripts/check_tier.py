import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-nexus/.env')
conn = psycopg2.connect(os.getenv('VITE_SUPABASE_POOLER_URL'))
cur = conn.cursor()

# Check if tier column exists
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'customers' AND column_name IN ('tier', 'customer_tier', 'total_revenue')
""")
cols = cur.fetchall()
print('Relevant columns:', [c[0] for c in cols])

cur.close()
conn.close()
