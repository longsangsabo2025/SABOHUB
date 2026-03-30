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

# 1. Check customers with total_debt > 0
print('=== CUSTOMERS total_debt > 0 ===')
cur.execute("SELECT id, name, code, total_debt, credit_limit FROM customers WHERE total_debt > 0 ORDER BY total_debt DESC")
total_cust_debt = 0
for r in cur.fetchall():
    total_cust_debt += r[3]
    print(f'  {r[1]} ({r[2]}): debt={r[3]:,.0f}, limit={r[4]:,.0f}')
print(f'  TOTAL customers.total_debt: {total_cust_debt:,.0f}')

# 2. Check unpaid sales orders
print()
print('=== UNPAID SALES ORDERS (payment_status != paid, status != cancelled) ===')
cur.execute("""
    SELECT c.name, c.code, so.total, so.paid_amount, so.payment_status, so.status, so.order_date, so.id
    FROM sales_orders so JOIN customers c ON c.id = so.customer_id
    WHERE so.payment_status != 'paid' AND so.status != 'cancelled'
    ORDER BY c.name, so.order_date
""")
total_so_unpaid = 0
for r in cur.fetchall():
    balance = (r[2] or 0) - (r[3] or 0)
    total_so_unpaid += balance
    print(f'  {r[0]} ({r[1]}): total={r[2]:,.0f}, paid={r[3]:,.0f}, balance={balance:,.0f}, pay_status={r[4]}, status={r[5]}, date={r[6]}')
print(f'  TOTAL unpaid SO balance: {total_so_unpaid:,.0f}')

# 3. Check receivables
print()
print('=== RECEIVABLES (status != paid) ===')
cur.execute("""
    SELECT c.name, r.original_amount, r.paid_amount, r.status, r.due_date, r.reference_number
    FROM receivables r JOIN customers c ON c.id = r.customer_id
    WHERE r.status != 'paid'
    ORDER BY c.name
""")
total_recv = 0
for r in cur.fetchall():
    balance = (r[1] or 0) - (r[2] or 0)
    total_recv += balance
    print(f'  {r[0]}: orig={r[1]:,.0f}, paid={r[2]:,.0f}, balance={balance:,.0f}, status={r[3]}, due={r[4]}, ref={r[5]}')
print(f'  TOTAL receivables balance: {total_recv:,.0f}')

# 4. Customer-level check: what's the REAL debt per customer?
print()
print('=== PER-CUSTOMER: stored debt vs actual debt ===')
cur.execute("""
    SELECT c.id, c.name, c.code, c.total_debt,
        COALESCE((SELECT SUM(so.total - so.paid_amount) FROM sales_orders so 
            WHERE so.customer_id = c.id AND so.payment_status != 'paid' AND so.status != 'cancelled'), 0) as so_debt,
        COALESCE((SELECT SUM(r.original_amount - r.paid_amount) FROM receivables r 
            WHERE r.customer_id = c.id AND r.status != 'paid'), 0) as recv_debt
    FROM customers c
    WHERE c.total_debt > 0 
        OR c.id IN (SELECT customer_id FROM sales_orders WHERE payment_status != 'paid' AND status != 'cancelled')
        OR c.id IN (SELECT customer_id FROM receivables WHERE status != 'paid')
    ORDER BY c.name
""")
total_stored = 0
total_actual = 0
for r in cur.fetchall():
    stored = r[3] or 0
    actual = (r[4] or 0) + (r[5] or 0)
    total_stored += stored
    total_actual += actual
    diff = actual - stored
    flag = ' *** MISMATCH' if abs(diff) > 1 else ''
    print(f'  {r[1]} ({r[2]}): stored={stored:,.0f}, so_debt={r[4]:,.0f}, recv_debt={r[5]:,.0f}, actual={actual:,.0f}, diff={diff:,.0f}{flag}')

print()
print('=== SUMMARY ===')
print(f'  customers.total_debt SUM:    {total_stored:,.0f}')
print(f'  Actual (SO+Recv) SUM:        {total_actual:,.0f}')
print(f'  DIFFERENCE:                  {total_actual - total_stored:,.0f}')

# 5. Check if there's a trigger to update total_debt
print()
print('=== CHECK TRIGGERS on sales_orders ===')
cur.execute("""
    SELECT trigger_name, event_manipulation, action_statement 
    FROM information_schema.triggers 
    WHERE event_object_table IN ('sales_orders', 'customer_payments', 'receivables')
""")
for r in cur.fetchall():
    print(f'  trigger={r[0]}, event={r[1]}, action={r[2][:100]}')

# 6. Check if there's a function to recalculate
print()
print('=== FUNCTIONS related to debt ===')
cur.execute("""
    SELECT routine_name FROM information_schema.routines 
    WHERE routine_schema = 'public' AND (routine_name LIKE '%debt%' OR routine_name LIKE '%recalc%')
""")
for r in cur.fetchall():
    print(f'  {r[0]}')

conn.close()
