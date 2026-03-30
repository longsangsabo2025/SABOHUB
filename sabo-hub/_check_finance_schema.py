import psycopg2
conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543, dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

# Check receivables columns
cur.execute("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'receivables' AND table_schema = 'public' ORDER BY ordinal_position")
print('=== RECEIVABLES TABLE ===')
for r in cur.fetchall():
    print(f'  {r[0]} | {r[1]} | nullable={r[2]}')

# Check payments columns
cur.execute("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'payments' AND table_schema = 'public' ORDER BY ordinal_position")
print('=== PAYMENTS TABLE ===')
for r in cur.fetchall():
    print(f'  {r[0]} | {r[1]} | nullable={r[2]}')

# Check customer_payments columns
cur.execute("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'customer_payments' AND table_schema = 'public' ORDER BY ordinal_position")
print('=== CUSTOMER_PAYMENTS TABLE ===')
for r in cur.fetchall():
    print(f'  {r[0]} | {r[1]} | nullable={r[2]}')

# Check v_receivables_aging view
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'v_receivables_aging' AND table_schema = 'public' ORDER BY ordinal_position")
rows = cur.fetchall()
print('=== V_RECEIVABLES_AGING VIEW ===')
if rows:
    for r in rows:
        print(f'  {r[0]} | {r[1]}')
else:
    print('  VIEW DOES NOT EXIST!')

# Check create_manual_receivable RPC
cur.execute("SELECT routine_name, data_type FROM information_schema.routines WHERE routine_name = 'create_manual_receivable' AND routine_schema = 'public'")
rows = cur.fetchall()
print('=== create_manual_receivable RPC ===')
if rows:
    for r in rows:
        print(f'  {r[0]} | returns {r[1]}')
else:
    print('  RPC DOES NOT EXIST!')

# Check customers debt columns
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'customers' AND column_name IN ('total_debt', 'credit_limit', 'payment_terms') AND table_schema = 'public'")
print('=== CUSTOMERS DEBT COLUMNS ===')
for r in cur.fetchall():
    print(f'  {r[0]} | {r[1]}')

# Check actual data counts
cur.execute('SELECT COUNT(*) FROM receivables')
print(f'Receivables count: {cur.fetchone()[0]}')
cur.execute('SELECT COUNT(*) FROM payments')
print(f'Payments count: {cur.fetchone()[0]}')
cur.execute('SELECT COUNT(*) FROM customer_payments')
print(f'Customer_payments count: {cur.fetchone()[0]}')

# Check sales_orders payment statuses
cur.execute("SELECT DISTINCT payment_status FROM sales_orders WHERE payment_status IS NOT NULL ORDER BY payment_status")
print('=== SALES_ORDERS PAYMENT STATUSES ===')
for r in cur.fetchall():
    print(f'  {r[0]}')

# Check receivables statuses
cur.execute("SELECT DISTINCT status FROM receivables WHERE status IS NOT NULL ORDER BY status")
print('=== RECEIVABLES STATUSES ===')
for r in cur.fetchall():
    print(f'  {r[0]}')

# Check receivables reference_types
cur.execute("SELECT DISTINCT reference_type FROM receivables WHERE reference_type IS NOT NULL ORDER BY reference_type")
print('=== RECEIVABLES REFERENCE TYPES ===')
for r in cur.fetchall():
    print(f'  {r[0]}')

# Sample receivables data
cur.execute("SELECT id, reference_number, reference_type, original_amount, paid_amount, write_off_amount, status FROM receivables LIMIT 5")
print('=== SAMPLE RECEIVABLES ===')
for r in cur.fetchall():
    print(f'  id={str(r[0])[:8]}... ref={r[1]} type={r[2]} orig={r[3]} paid={r[4]} wo={r[5]} status={r[6]}')

# Sample customer_payments
cur.execute("SELECT id, amount, payment_date, payment_method, reference, status FROM customer_payments LIMIT 5")
print('=== SAMPLE CUSTOMER_PAYMENTS ===')
for r in cur.fetchall():
    print(f'  id={str(r[0])[:8]}... amount={r[1]} date={r[2]} method={r[3]} ref={r[4]} status={r[5]}')

conn.close()
