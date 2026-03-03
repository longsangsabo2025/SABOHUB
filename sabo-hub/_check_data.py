import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()

# Check employees per company
print("=== Employees by company ===")
cur.execute("""
    SELECT c.name, c.business_type, c.id,
        (SELECT COUNT(*) FROM employees e WHERE e.company_id = c.id) as total,
        (SELECT COUNT(*) FROM employees e WHERE e.company_id = c.id AND e.is_active = true) as active
    FROM companies c ORDER BY c.name
""")
for r in cur.fetchall():
    print(f"  {r[0]:25s} type={r[1]:15s} id={str(r[2])[:8]}  total={r[3]}  active={r[4]}")

# Check all employees
print("\n=== All employees ===")
cur.execute("SELECT id, full_name, role, company_id, is_active, email FROM employees ORDER BY full_name")
for r in cur.fetchall():
    print(f"  {r[1]:30s} role={r[2]:12s} company={str(r[3])[:8]} active={r[4]} email={r[5]}")

# Check branches
print("\n=== Branches ===")
cur.execute("SELECT b.id, b.name, b.company_id, c.name FROM branches b JOIN companies c ON b.company_id = c.id")
for r in cur.fetchall():
    print(f"  {r[1]:30s} company={r[3]}")

# Check key tables counts
for table in ['customers', 'sales_orders', 'warehouses', 'products', 'deliveries', 'tables', 'table_sessions', 'menu_items', 'monthly_pnl', 'payments', 'tasks']:
    cur.execute(f"SELECT COUNT(*) FROM {table}")
    cnt = cur.fetchone()[0]
    if cnt > 0:
        cur.execute(f"SELECT DISTINCT company_id FROM {table} LIMIT 5")
        cids = [str(r[0])[:8] for r in cur.fetchall()]
        print(f"  {table:20s}: {cnt:5d} rows  companies: {cids}")
    else:
        print(f"  {table:20s}: {cnt:5d} rows")

cur.close(); conn.close()
