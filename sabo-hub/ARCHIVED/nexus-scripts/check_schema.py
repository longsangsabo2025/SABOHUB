#!/usr/bin/env python3
import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(POOLER_URL)
cursor = conn.cursor()

# Check production_orders schema
cursor.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'manufacturing_production_orders'
    ORDER BY ordinal_position;
""")

print("manufacturing_production_orders columns:")
for col, dtype in cursor.fetchall():
    print(f"  {col:30s} {dtype}")

cursor.close()
conn.close()
