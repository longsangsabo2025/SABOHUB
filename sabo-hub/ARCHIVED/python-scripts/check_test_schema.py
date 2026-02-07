"""Check sales_targets schema"""
import psycopg2
import os
from dotenv import load_dotenv
from pathlib import Path

load_dotenv(Path("sabohub-automation/.env"))
conn = psycopg2.connect(os.getenv("DATABASE_URL"))
cur = conn.cursor()

for table in ['sales_targets', 'competitor_reports', 'surveys', 'distributor_promotions']:
    cur.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = %s
    """, (table,))
    
    print(f"\n{table} columns:")
    rows = cur.fetchall()
    if not rows:
        print("  (table not found)")
    for row in rows:
        print(f"  {row[0]}: {row[1]}")

cur.close()
conn.close()
