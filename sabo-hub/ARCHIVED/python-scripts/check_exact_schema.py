#!/usr/bin/env python3
"""Check EXACT schema for products and customers tables"""

import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
COMPANY_ID = "9f8921df-3760-44b5-9a7f-20f8484b0300"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

print("=" * 70)
print("PRODUCTS TABLE SCHEMA")
print("=" * 70)
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'products'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]}")

print("\n" + "=" * 70)
print("CUSTOMERS TABLE SCHEMA")
print("=" * 70)
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'customers'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]}")

print("\n" + "=" * 70)
print("SALES_ORDERS TABLE SCHEMA")
print("=" * 70)
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'sales_orders'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]}")

print("\n" + "=" * 70)
print("INVENTORY TABLE SCHEMA")
print("=" * 70)
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'inventory'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]}")

print("\n" + "=" * 70)
print("SAMPLE DATA")
print("=" * 70)

# Products
print("\n--- Products (limit 3) ---")
cur.execute("SELECT * FROM products WHERE company_id = %s LIMIT 3", (COMPANY_ID,))
cols = [desc[0] for desc in cur.description]
print(f"Columns: {cols}")
for row in cur.fetchall():
    print(f"  {dict(zip(cols, row))}")

# Customers  
print("\n--- Customers (limit 3) ---")
cur.execute("SELECT * FROM customers WHERE company_id = %s LIMIT 3", (COMPANY_ID,))
cols = [desc[0] for desc in cur.description]
print(f"Columns: {cols}")
for row in cur.fetchall():
    print(f"  {dict(zip(cols, row))}")

# Sales orders
print("\n--- Sales Orders (all) ---")
cur.execute("SELECT * FROM sales_orders WHERE company_id = %s", (COMPANY_ID,))
cols = [desc[0] for desc in cur.description]
print(f"Columns: {cols}")
for row in cur.fetchall():
    d = dict(zip(cols, row))
    print(f"  status={d.get('status')} payment={d.get('payment_status')} delivery={d.get('delivery_status')} total={d.get('total')} created_at={d.get('created_at')}")

# Inventory
print("\n--- Inventory (limit 5) ---")
cur.execute("SELECT * FROM inventory WHERE company_id = %s LIMIT 5", (COMPANY_ID,))
cols = [desc[0] for desc in cur.description]
print(f"Columns: {cols}")
for row in cur.fetchall():
    print(f"  {dict(zip(cols, row))}")

cur.close()
conn.close()
