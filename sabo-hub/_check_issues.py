import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# 1. Check asm.nam user role
cur.execute("SELECT id, full_name, email, role, department, is_active FROM employees WHERE email ILIKE '%asm%' OR full_name ILIKE '%asm%' OR full_name ILIKE '%nam%'")
rows = cur.fetchall()
print('=== Employees matching asm/nam ===')
for r in rows:
    print(f'  id={r[0]}, name={r[1]}, email={r[2]}, role={r[3]}, dept={r[4]}, active={r[5]}')

# 2. Check if there's order_type column in sales_orders
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='sales_orders' AND column_name='order_type'")
ot = cur.fetchall()
print(f'\n=== order_type column exists in sales_orders: {len(ot) > 0} ===')

# 3. Check sales_order_history schema 
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name='sales_order_history' ORDER BY ordinal_position")
cols = cur.fetchall()
print(f'\n=== sales_order_history columns ({len(cols)}) ===')
for c in cols:
    print(f'  {c[0]} ({c[1]})')

# 4. Check if any triggers exist on sales_orders
cur.execute("SELECT trigger_name, event_manipulation, action_statement FROM information_schema.triggers WHERE event_object_table='sales_orders'")
triggers = cur.fetchall()
print(f'\n=== Triggers on sales_orders: {len(triggers)} ===')
for t in triggers:
    print(f'  {t[0]} on {t[1]}: {t[2][:100]}')

# 5. Check customer_payments schema
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='customer_payments' ORDER BY ordinal_position")
cp_cols = cur.fetchall()
print(f'\n=== customer_payments columns ===')
print(f'  {[c[0] for c in cp_cols]}')

# 6. Check RLS policies on sales_orders
cur.execute("SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'sales_orders'")
policies = cur.fetchall()
print(f'\n=== RLS policies on sales_orders: {len(policies)} ===')
for p in policies:
    print(f'  {p[0]} ({p[1]}): {str(p[2])[:120]}')

# 7. Check stuck orders for test/msthieutoi users
cur.execute("""
    SELECT so.id, so.order_number, so.status, so.delivery_status, so.payment_status, e.full_name
    FROM sales_orders so
    JOIN employees e ON so.employee_id = e.id
    WHERE (e.full_name ILIKE '%test%' OR e.full_name ILIKE '%msthieutoi%' OR e.email ILIKE '%test%' OR e.email ILIKE '%msthieutoi%')
    AND so.delivery_status IN ('delivering', 'awaiting_pickup')
    AND so.status != 'cancelled'
    LIMIT 10
""")
stuck = cur.fetchall()
print(f'\n=== Stuck orders (delivery_status=delivering/awaiting_pickup) ===')
for s in stuck:
    print(f'  id={s[0]}, order#={s[1]}, status={s[2]}, delivery={s[3]}, payment={s[4]}, employee={s[5]}')

# 8. Count sales_order_history records
cur.execute("SELECT COUNT(*) FROM sales_order_history")
hist_count = cur.fetchone()[0]
print(f'\n=== sales_order_history record count: {hist_count} ===')

conn.close()
