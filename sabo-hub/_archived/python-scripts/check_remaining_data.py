"""
Check remaining data across ALL tables for Odori company.
"""
import psycopg2

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

CID = '9f8921df-3760-44b5-9a7f-20f8484b0300'

print("=" * 60)
print("SCAN TAT CA BANG DU LIEU CON LAI")
print("=" * 60)

# List all tables with company_id column
cur.execute("""
    SELECT table_name 
    FROM information_schema.columns 
    WHERE column_name = 'company_id' 
    AND table_schema = 'public'
    ORDER BY table_name
""")
tables = [r[0] for r in cur.fetchall()]

print(f"\nBang co company_id ({len(tables)} bang):")
for t in tables:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {t} WHERE company_id = %s", (CID,))
        count = cur.fetchone()[0]
        if count > 0:
            marker = " <<<" if t not in ('customers', 'employees', 'products', 'warehouses', 'companies', 'inventory', 'product_categories') else ""
            print(f"  {t:<40} {count:>6} records{marker}")
        else:
            print(f"  {t:<40} {count:>6}")
    except Exception as e:
        conn.rollback()
        print(f"  {t:<40} ERROR: {str(e)[:50]}")

# Check tables with customer_id (might reference old customers)
print(f"\n{'='*60}")
print("BANG CO CUSTOMER_ID (co the lien quan):")
print("=" * 60)
cur.execute("""
    SELECT table_name 
    FROM information_schema.columns 
    WHERE column_name = 'customer_id' 
    AND table_schema = 'public'
    ORDER BY table_name
""")
cust_tables = [r[0] for r in cur.fetchall()]
for t in cust_tables:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {t}", ())
        count = cur.fetchone()[0]
        if count > 0:
            print(f"  {t:<40} {count:>6} records")
    except Exception as e:
        conn.rollback()

# Check tables with order_id
print(f"\n{'='*60}")
print("BANG CO ORDER_ID:")
print("=" * 60)
cur.execute("""
    SELECT table_name 
    FROM information_schema.columns 
    WHERE column_name = 'order_id' 
    AND table_schema = 'public'
    ORDER BY table_name
""")
order_tables = [r[0] for r in cur.fetchall()]
for t in order_tables:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {t}", ())
        count = cur.fetchone()[0]
        if count > 0:
            print(f"  {t:<40} {count:>6} records")
    except Exception as e:
        conn.rollback()

# Specific checks
print(f"\n{'='*60}")
print("CHI TIET TUNG BANG CON DATA:")
print("=" * 60)

# Receivables
try:
    cur.execute("SELECT COUNT(*) FROM receivables WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\nreceivables: {count}")
    if count > 0:
        cur.execute("SELECT id, customer_id, amount, status, created_at FROM receivables WHERE company_id = %s LIMIT 10", (CID,))
        for r in cur.fetchall():
            print(f"  - amount={r[2]}, status={r[3]}, date={r[4]}")
except: conn.rollback()

# Delivery routes
try:
    cur.execute("SELECT COUNT(*) FROM delivery_routes WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\ndelivery_routes: {count}")
    if count > 0:
        cur.execute("SELECT * FROM delivery_routes WHERE company_id = %s LIMIT 5", (CID,))
        for r in cur.fetchall():
            print(f"  - {r}")
except: conn.rollback()

# Visit logs
try:
    cur.execute("SELECT COUNT(*) FROM visit_logs WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\nvisit_logs: {count}")
except: conn.rollback()

# Check-ins
try:
    cur.execute("SELECT COUNT(*) FROM check_ins WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\ncheck_ins: {count}")
except: conn.rollback()

# Notifications
try:
    cur.execute("SELECT COUNT(*) FROM notifications WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\nnotifications: {count}")
except: conn.rollback()

# Product samples
try:
    cur.execute("SELECT COUNT(*) FROM product_samples WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\nproduct_samples: {count}")
except: conn.rollback()

# Commission programs
try:
    cur.execute("SELECT COUNT(*) FROM commission_programs WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\ncommission_programs: {count}")
    if count > 0:
        cur.execute("SELECT name, status FROM commission_programs WHERE company_id = %s", (CID,))
        for r in cur.fetchall():
            print(f"  - {r[0]}: {r[1]}")
except: conn.rollback()

# Bills
try:
    cur.execute("SELECT COUNT(*) FROM bills WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\nbills: {count}")
except: conn.rollback()

# Price lists
try:
    cur.execute("SELECT COUNT(*) FROM price_lists WHERE company_id = %s", (CID,))
    count = cur.fetchone()[0]
    print(f"\nprice_lists: {count}")
    if count > 0:
        cur.execute("SELECT name, status FROM price_lists WHERE company_id = %s", (CID,))
        for r in cur.fetchall():
            print(f"  - {r[0]}: {r[1]}")
except: conn.rollback()

# Customer addresses remaining
try:
    cur.execute("""
        SELECT COUNT(*) FROM customer_addresses ca
        JOIN customers c ON ca.customer_id = c.id
        WHERE c.company_id = %s
    """, (CID,))
    count = cur.fetchone()[0]
    print(f"\ncustomer_addresses: {count}")
except: conn.rollback()

# last_order_date on customers (should be null after cleanup)
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND last_order_date IS NOT NULL", (CID,))
print(f"\nKH co last_order_date != null: {cur.fetchone()[0]}")

# last_visit_date
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND last_visit_date IS NOT NULL", (CID,))
print(f"KH co last_visit_date != null: {cur.fetchone()[0]}")

# Customers with stale data pointing to old orders
cur.execute("""
    SELECT COUNT(*) FROM customers c 
    WHERE c.company_id = %s AND c.last_order_date IS NOT NULL
    AND c.last_order_date < '2026-02-24'
""", (CID,))
print(f"KH co last_order_date truoc hom nay: {cur.fetchone()[0]}")

conn.close()
print(f"\n{'='*60}")
print("SCAN HOAN TAT")
print("=" * 60)
