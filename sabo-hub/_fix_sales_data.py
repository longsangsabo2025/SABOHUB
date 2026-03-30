"""Fix missing created_by and customer_name on sales_orders."""
import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

print("=" * 60)
print("FIX: Backfill created_by and customer_name")
print("=" * 60)

# 1. Set created_by = sale_id where missing
cur.execute("""
    UPDATE sales_orders
    SET created_by = sale_id, updated_at = NOW()
    WHERE created_by IS NULL AND sale_id IS NOT NULL
""")
print(f"1. Set created_by = sale_id: {cur.rowcount} orders updated")

# 2. Set customer_name from customers table where missing
cur.execute("""
    UPDATE sales_orders so
    SET customer_name = c.name, updated_at = NOW()
    FROM customers c
    WHERE so.customer_id = c.id
    AND (so.customer_name IS NULL OR so.customer_name = '')
""")
print(f"2. Set customer_name from customers: {cur.rowcount} orders updated")

conn.commit()

# Verify
cur.execute("SELECT COUNT(*) FROM sales_orders WHERE created_by IS NULL")
print(f"\nVerification:")
print(f"  Orders still missing created_by: {cur.fetchone()[0]}")

cur.execute("SELECT COUNT(*) FROM sales_orders WHERE customer_name IS NULL OR customer_name = ''")
print(f"  Orders still missing customer_name: {cur.fetchone()[0]}")

cur.close()
conn.close()
print("DONE!")
