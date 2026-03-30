import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# 1. Check RLS DELETE policy detail for sales_orders
cur.execute("SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'sales_orders' AND cmd = 'DELETE'")
rows = cur.fetchall()
print('=== DELETE RLS policy on sales_orders ===')
for r in rows:
    print(f'  Policy: {r[0]}')
    print(f'  Qual: {r[2]}')

# 2. Check who created orders (sales_orders columns that link to employee)
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='sales_orders' AND column_name ILIKE '%employee%' OR (table_name='sales_orders' AND column_name ILIKE '%created%') OR (table_name='sales_orders' AND column_name ILIKE '%user%') OR (table_name='sales_orders' AND column_name ILIKE '%sales%rep%')")
cols = cur.fetchall()
print(f'\n=== sales_orders employee-related columns ===')
for c in cols:
    print(f'  {c[0]}')

# 3. Find stuck orders with delivery_status 'delivering' or 'awaiting_pickup'
cur.execute("""
    SELECT id, order_number, status, delivery_status, payment_status, created_by
    FROM sales_orders 
    WHERE delivery_status IN ('delivering', 'awaiting_pickup')
    AND status != 'cancelled'
    LIMIT 20
""")
stuck = cur.fetchall()
print(f'\n=== Stuck orders (delivery_status=delivering/awaiting_pickup): {len(stuck)} ===')
for s in stuck:
    print(f'  id={s[0]}, order#={s[1]}, status={s[2]}, delivery={s[3]}, payment={s[4]}, created_by={s[5]}')

# 4. Count sales_order_history records
cur.execute("SELECT COUNT(*) FROM sales_order_history")
hist_count = cur.fetchone()[0]
print(f'\n=== sales_order_history record count: {hist_count} ===')

# 5. Check track_order_status_change function
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'track_order_status_change'")
func = cur.fetchone()
print(f'\n=== track_order_status_change function ===')
if func:
    print(func[0][:500])
else:
    print('  NOT FOUND')

# 6. Check customer_payments - how many cash vs transfer
cur.execute("""
    SELECT payment_method, COUNT(*), SUM(amount) 
    FROM customer_payments 
    GROUP BY payment_method
""")
pm = cur.fetchall()
print(f'\n=== customer_payments by payment_method ===')
for p in pm:
    print(f'  {p[0]}: {p[1]} records, total={p[2]}')

# 7. Check if complete_delivery RPC exists and inspect it
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'complete_delivery'")
cd_func = cur.fetchone()
print(f'\n=== complete_delivery RPC ===')
if cd_func:
    print(cd_func[0][:800])
else:
    print('  NOT FOUND')

conn.close()
