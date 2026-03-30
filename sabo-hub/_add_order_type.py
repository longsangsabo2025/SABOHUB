"""Add order_type column to sales_orders and add check for sample orders in warehouse."""
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

# Check if order_type column exists
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='sales_orders' AND column_name='order_type'")
exists = cur.fetchone()

if exists:
    print("order_type column already exists")
else:
    # Add order_type column with default 'regular'
    cur.execute("""
        ALTER TABLE sales_orders 
        ADD COLUMN order_type text NOT NULL DEFAULT 'regular'
        CHECK (order_type IN ('regular', 'sample', 'return', 'exchange'))
    """)
    print("Added order_type column to sales_orders")

    # Mark existing orders linked to product_samples as 'sample'
    cur.execute("""
        UPDATE sales_orders so
        SET order_type = 'sample'
        FROM product_samples ps
        WHERE ps.order_id = so.id
        AND ps.converted_to_order = false
        RETURNING so.id, so.order_number
    """)
    sample_orders = cur.fetchall()
    print(f"Marked {len(sample_orders)} orders as 'sample'")

conn.commit()

# Verify
cur.execute("SELECT order_type, COUNT(*) FROM sales_orders GROUP BY order_type")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]} orders")

cur.close()
conn.close()
print("Done!")
