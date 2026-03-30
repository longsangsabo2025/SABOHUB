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

# 1. Check default value for order_type column
cur.execute("""
    SELECT column_default FROM information_schema.columns 
    WHERE table_name='sales_orders' AND column_name='order_type'
""")
r = cur.fetchone()
print(f"order_type default: {r[0] if r else 'NO COLUMN'}")

# 2. Check triggers on sales_orders
cur.execute("""
    SELECT trigger_name, event_manipulation, action_statement
    FROM information_schema.triggers 
    WHERE event_object_table='sales_orders'
""")
print('\nTriggers on sales_orders:')
for row in cur.fetchall():
    print(f'  {row[0]} ({row[1]}): {row[2][:100]}')

# 3. Check visit_photos column names vs StoreVisitService expectations
cur.execute("""
    SELECT column_name, data_type FROM information_schema.columns 
    WHERE table_name='visit_photos' ORDER BY ordinal_position
""")
print('\nvisit_photos schema:')
for row in cur.fetchall():
    print(f'  {row[0]}: {row[1]}')

# 4. Check store_visits columns
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name='store_visits' ORDER BY ordinal_position
""")
cols = [row[0] for row in cur.fetchall()]
print(f'\nstore_visits columns ({len(cols)}): {cols}')

# 5. Check in-progress visits (should be 0 if properly closed)
cur.execute("""
    SELECT id, customer_id, check_in_time, check_out_time, status, employee_id
    FROM store_visits WHERE status='in-progress'
    LIMIT 5
""")
print('\nIn-progress visits (first 5):')
for row in cur.fetchall():
    print(f'  visit_id={row[0][:8]}... | checkin={row[2]} | checkout={row[3]} | status={row[4]}')

# 6. Check product_samples with converted_to_order=true but no order
cur.execute("""
    SELECT ps.id, ps.status, ps.converted_to_order, ps.order_id, ps.product_name
    FROM product_samples ps
    WHERE ps.converted_to_order = true
""")
print('\nConverted samples:')
for row in cur.fetchall():
    print(f'  {row[4]} | status={row[1]} | converted={row[2]} | order_id={row[3]}')

# 7. Check sales_orders created_by and customer_name for SM- orders
cur.execute("""
    SELECT order_number, created_by, customer_name, order_type 
    FROM sales_orders WHERE order_number LIKE 'SM-%'
""")
print('\nSM- orders (created_by, customer_name):')
for row in cur.fetchall():
    print(f'  {row[0]} | created_by={row[1]} | customer_name={row[2]} | type={row[3]}')

conn.close()
print('\nDone.')
