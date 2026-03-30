import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# 1. Full track_order_status_change function
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'track_order_status_change'")
func = cur.fetchone()
print('=== track_order_status_change (FULL) ===')
if func:
    print(func[0])

# 2. Check complete_delivery RPC full
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'complete_delivery'")
cd = cur.fetchone()
print('\n=== complete_delivery RPC (FULL) ===')
if cd:
    print(cd[0])

# 3. Check asm.nam auth_user_id (to understand RLS)
cur.execute("SELECT id, auth_user_id, full_name, role FROM employees WHERE email = 'asm.nam@odori.vn'")
user = cur.fetchone()
print(f'\n=== asm.nam employee ===')
if user:
    print(f'  id={user[0]}, auth_user_id={user[1]}, name={user[2]}, role={user[3]}')

# 4. Check if asm.nam can access orders (is the role matching RLS delete policy)
# Policy allows: ceo, manager, CEO, MANAGER
# asm.nam role is: MANAGER
print(f'\n=== Role "{user[3] if user else "?"}" matches DELETE policy roles: {user[3] in ["ceo","manager","CEO","MANAGER"] if user else False} ===')

# 5. Check the 5 stuck orders - are they linked to deliveries?
cur.execute("""
    SELECT so.id, so.order_number, so.status, so.delivery_status, 
           d.id as delivery_id, d.status as delivery_table_status, d.driver_id
    FROM sales_orders so
    LEFT JOIN deliveries d ON d.order_id = so.id
    WHERE so.delivery_status IN ('delivering', 'awaiting_pickup')
    AND so.status != 'cancelled'
    LIMIT 20
""")
stuck = cur.fetchall()
print(f'\n=== Stuck orders with delivery records ===')
for s in stuck:
    print(f'  order={s[1]}, so.status={s[2]}, so.delivery_status={s[3]}, delivery_id={s[4]}, d.status={s[5]}, driver={s[6]}')

# 6. Check driver_route_page cash flow - is customer_payments getting cash records?
cur.execute("""
    SELECT cp.payment_method, cp.amount, cp.payment_date, c.name as customer
    FROM customer_payments cp
    JOIN customers c ON cp.customer_id = c.id
    WHERE cp.payment_method = 'cash'
    ORDER BY cp.created_at DESC
    LIMIT 5
""")
cash = cur.fetchall()
print(f'\n=== Recent cash payments in customer_payments ===')
for c in cash:
    print(f'  method={c[0]}, amount={c[1]}, date={c[2]}, customer={c[3]}')

# 7. Check sales_orders with payment_method=cash but NOT in customer_payments
cur.execute("""
    SELECT so.id, so.order_number, so.payment_status, so.payment_method, so.total,
           so.customer_id, c.name as customer
    FROM sales_orders so
    JOIN customers c ON so.customer_id = c.id
    WHERE so.payment_method = 'cash' AND so.payment_status = 'paid'
    AND NOT EXISTS (
        SELECT 1 FROM customer_payments cp 
        WHERE cp.customer_id = so.customer_id 
        AND cp.amount = so.total
        AND cp.payment_method = 'cash'
    )
    LIMIT 10
""")
missing = cur.fetchall()
print(f'\n=== Cash-paid orders WITHOUT customer_payments record: {len(missing)} ===')
for m in missing:
    print(f'  order={m[1]}, status={m[2]}, method={m[3]}, total={m[4]}, customer={m[6]}')

conn.close()
