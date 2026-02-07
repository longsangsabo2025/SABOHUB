#!/usr/bin/env python3
"""Check product category structure in Supabase"""

import psycopg2

# Transaction pooler connection
DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Check products table schema
print("=== Products Table Schema ===")
cur.execute("""
    SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns 
    WHERE table_name = 'products' 
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  {row[0]:25} | {row[1]:20} | nullable: {row[2]}")

# Check sample products with category
print("\n=== Sample Products with Category ===")
cur.execute("""
    SELECT p.id, p.name, p.sku, p.category_id, pc.name as category_name
    FROM products p
    LEFT JOIN product_categories pc ON p.category_id = pc.id
    LIMIT 5
""")
for row in cur.fetchall():
    print(f"  {row[1][:30]:30} | SKU: {row[2]:15} | cat_id: {row[3]} | cat_name: {row[4]}")

# Check product_categories
print("\n=== Product Categories ===")
cur.execute("SELECT id, name FROM product_categories ORDER BY name LIMIT 10")
for row in cur.fetchall():
    print(f"  {row[0]} | {row[1]}")

cur.close()
conn.close()
