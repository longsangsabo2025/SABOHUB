import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()
CID = '9f8921df-3760-44b5-9a7f-20f8484b0300'

# Products
cur.execute('SELECT COUNT(*) FROM products WHERE company_id = %s', (CID,))
print(f'Products total: {cur.fetchone()[0]}')

# Customer addresses
try:
    cur.execute('SELECT COUNT(*) FROM customer_addresses ca JOIN customers c ON ca.customer_id = c.id WHERE c.company_id = %s', (CID,))
    print(f'Customer addresses: {cur.fetchone()[0]}')
except:
    conn.rollback()
    print('customer_addresses: error')

# Employees
cur.execute('SELECT COUNT(*) FROM employees WHERE company_id = %s', (CID,))
print(f'Employees total: {cur.fetchone()[0]}')
cur.execute('SELECT full_name, role, is_active FROM employees WHERE company_id = %s ORDER BY full_name', (CID,))
for e in cur.fetchall():
    print(f'  - {(e[0] or "")[:30]:<32} role={e[1]:<15} active={e[2]}')

# Delivery routes
try:
    cur.execute('SELECT COUNT(*) FROM delivery_routes WHERE company_id = %s', (CID,))
    print(f'Delivery routes: {cur.fetchone()[0]}')
except:
    conn.rollback()
    print('delivery_routes: error')

# Warehouses
cur.execute('SELECT id, name FROM warehouses WHERE company_id = %s', (CID,))
for w in cur.fetchall():
    print(f'Warehouse: {w[1]} ({w[0][:8]}...)')

# No Name customers count
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND (name = 'No Name' OR name IS NULL OR name = '')", (CID,))
print(f'\nNo Name customers: {cur.fetchone()[0]}')

# Customers with 0 orders (type=other)
cur.execute("""
    SELECT COUNT(*) FROM customers c 
    WHERE c.company_id = %s AND c.type = 'other'
    AND NOT EXISTS (SELECT 1 FROM sales_orders so WHERE so.customer_id = c.id)
""", (CID,))
print(f'Other-type customers with 0 orders: {cur.fetchone()[0]}')

# Customers with 0 orders total
cur.execute("""
    SELECT COUNT(*) FROM customers c 
    WHERE c.company_id = %s
    AND NOT EXISTS (SELECT 1 FROM sales_orders so WHERE so.customer_id = c.id)
""", (CID,))
print(f'ALL customers with 0 orders: {cur.fetchone()[0]}')

# Test customer
cur.execute("SELECT id, name, phone FROM customers WHERE company_id = %s AND (name ILIKE '%%test%%' OR name ILIKE '%%teét%%')", (CID,))
tests = cur.fetchall()
print(f'Test customers: {len(tests)}')
for t in tests:
    print(f'  - {t[1]} (phone: {t[2]})')

# Orders with pending status
cur.execute("SELECT status, COUNT(*) FROM sales_orders WHERE company_id = %s AND status NOT IN ('completed', 'cancelled') GROUP BY status", (CID,))
pending = cur.fetchall()
print(f'Pending orders: {pending}')

# total_debt non-zero
cur.execute('SELECT COUNT(*) FROM customers WHERE company_id = %s AND total_debt IS NOT NULL AND total_debt != 0', (CID,))
print(f'Customers with debt != 0: {cur.fetchone()[0]}')

# Negative debts
cur.execute('SELECT name, total_debt FROM customers WHERE company_id = %s AND total_debt < 0', (CID,))
neg = cur.fetchall()
print(f'Customers with NEGATIVE debt: {len(neg)}')
for n in neg:
    print(f'  - {n[0]}: {n[1]}')

# Product samples
try:
    cur.execute('SELECT COUNT(*) FROM product_samples WHERE company_id = %s', (CID,))
    print(f'Product samples: {cur.fetchone()[0]}')
except:
    conn.rollback()
    print('product_samples: N/A')

conn.close()
