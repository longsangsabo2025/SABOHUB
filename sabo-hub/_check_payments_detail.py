import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# 1. Check the specific orders from screenshots (circled in red)
print("=== Specific orders from screenshots ===")
cur.execute("""
    SELECT order_number, customer_name, total, payment_status, payment_method, delivery_status, 
           paid_amount, payment_collected_at, created_at
    FROM sales_orders
    WHERE order_number LIKE 'SO-260328%' OR order_number LIKE 'SO-260329%'
    ORDER BY created_at DESC
    LIMIT 30
""")
for r in cur.fetchall():
    print(r)

# 2. Check ALL customer_payments from last 3 days with customer_id info
print("\n=== customer_payments last 3 days ===")
cur.execute("""
    SELECT cp.payment_date, cp.amount, cp.payment_method, cp.notes, c.name
    FROM customer_payments cp
    LEFT JOIN customers c ON cp.customer_id = c.id
    WHERE cp.payment_date >= '2026-03-27'
    ORDER BY cp.payment_date DESC
""")
for r in cur.fetchall():
    print(r)

# 3. Check if any orders have payment_collected_at for today
print("\n=== Orders with payment_collected today ===")
cur.execute("""
    SELECT order_number, customer_name, total, payment_status, payment_method, payment_collected_at
    FROM sales_orders
    WHERE payment_collected_at >= '2026-03-29'
    ORDER BY payment_collected_at DESC
""")
for r in cur.fetchall():
    print(r)

# 4. Check orders that were delivered (completed payment flow) 
print("\n=== Delivered & paid orders (last 3 days) ===")
cur.execute("""
    SELECT order_number, customer_name, total, payment_status, payment_method, 
           delivery_status, updated_at
    FROM sales_orders
    WHERE delivery_status = 'delivered' 
    AND (payment_status = 'paid' OR payment_status = 'pending_transfer' OR payment_status = 'debt')
    AND updated_at >= '2026-03-27'
    ORDER BY updated_at DESC
    LIMIT 20
""")
for r in cur.fetchall():
    print(r)

conn.close()
