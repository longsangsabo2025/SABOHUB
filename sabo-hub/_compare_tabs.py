import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123', sslmode='require')
cur = conn.cursor()

# Dashboard calculation: SUM from sales_orders where payment_status in (unpaid, debt, partial, pending_transfer)
cur.execute("SELECT SUM(total - COALESCE(paid_amount, 0)) FROM sales_orders WHERE payment_status IN ('unpaid', 'debt', 'partial', 'pending_transfer') AND status != 'cancelled'")
so_total = cur.fetchone()[0] or 0
print(f'Dashboard (SO only): {so_total:,.0f}')

cur.execute("SELECT COUNT(DISTINCT customer_id) FROM sales_orders WHERE payment_status IN ('unpaid', 'debt', 'partial', 'pending_transfer') AND status != 'cancelled' AND (total - COALESCE(paid_amount, 0)) > 0")
so_cust = cur.fetchone()[0]
print(f'Dashboard customers:  {so_cust}')

# Manual receivables (not linked to SO)
cur.execute("SELECT SUM(original_amount - COALESCE(paid_amount, 0) - COALESCE(write_off_amount, 0)) FROM receivables WHERE reference_type = 'manual' AND status != 'paid'")
recv_total = cur.fetchone()[0] or 0
print(f'Manual receivables:   {recv_total:,.0f}')

# Cong no tab (customers.total_debt)
cur.execute('SELECT SUM(total_debt) FROM customers WHERE total_debt > 0')
cust_total = cur.fetchone()[0] or 0
print(f'Cong no tab (customers.total_debt): {cust_total:,.0f}')

cur.execute('SELECT COUNT(*) FROM customers WHERE total_debt > 0')
cust_count = cur.fetchone()[0]
print(f'Cong no tab customers: {cust_count}')

print(f'\nDashboard + manual recv = {so_total + recv_total:,.0f}')
print(f'Difference: cong_no({cust_total:,.0f}) - dashboard({so_total:,.0f}) = {cust_total - so_total:,.0f}')
print(f'Manual recv = {recv_total:,.0f}')

# Also check: which SO have balance = 0 but still unpaid status?
cur.execute("SELECT COUNT(*), SUM(total - COALESCE(paid_amount,0)) FROM sales_orders WHERE payment_status IN ('unpaid', 'debt', 'partial', 'pending_transfer') AND status != 'cancelled' AND (total - COALESCE(paid_amount,0)) <= 0")
row = cur.fetchone()
print(f'\nSO with unpaid status but balance <= 0: {row[0]} orders, sum={row[1] or 0:,.0f}')

conn.close()
