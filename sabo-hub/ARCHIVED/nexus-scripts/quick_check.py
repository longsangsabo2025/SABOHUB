#!/usr/bin/env python3
import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

tables_to_check = [
    'manufacturing_production_order_items',
    'manufacturing_production_output',
    'manufacturing_payable_items',
    'manufacturing_payable_payments'
]

conn = psycopg2.connect(POOLER_URL)
cursor = conn.cursor()

for table in tables_to_check:
    cursor.execute(f"""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = '{table}'
        );
    """)
    exists = cursor.fetchone()[0]
    print(f"{table:45s} {'✅ EXISTS' if exists else '❌ MISSING'}")

cursor.close()
conn.close()
