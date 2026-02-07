"""
COMPREHENSIVE SYSTEM AUDIT - Elon Musk Mode
Check EVERYTHING related to database access, auth, and RLS
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

print("=" * 60)
print("  SABOHUB COMPREHENSIVE SYSTEM AUDIT")
print("=" * 60)

# ============================================================
# 1. RLS STATUS - Make sure ALL tables are clean
# ============================================================
print("\n📋 1. RLS STATUS ON ALL PUBLIC TABLES")
print("-" * 40)
cur.execute("""
    SELECT tablename, rowsecurity
    FROM pg_tables
    WHERE schemaname = 'public'
    ORDER BY tablename
""")
tables = cur.fetchall()
rls_enabled = [t for t in tables if t[1]]
rls_disabled = [t for t in tables if not t[1]]
print(f"  Total tables: {len(tables)}")
print(f"  RLS disabled: {len(rls_disabled)} ✅")
print(f"  RLS enabled:  {len(rls_enabled)}")
if rls_enabled:
    print("  ⚠️ TABLES STILL WITH RLS ENABLED:")
    for t in rls_enabled:
        print(f"    ❌ {t[0]}")
else:
    print("  ✅ ALL tables have RLS disabled - CLEAN!")

# ============================================================
# 2. REMAINING POLICIES - Ghost policies that could cause issues
# ============================================================
print("\n📋 2. REMAINING RLS POLICIES (ghost policies)")
print("-" * 40)
cur.execute("""
    SELECT schemaname, tablename, policyname, permissive, cmd
    FROM pg_policies
    WHERE schemaname = 'public'
    ORDER BY tablename, policyname
""")
policies = cur.fetchall()
print(f"  Total remaining policies: {len(policies)}")
if policies:
    print("  Note: Policies exist but RLS is disabled, so they won't block")
    tables_with_policies = set(p[1] for p in policies)
    for t in sorted(tables_with_policies):
        t_policies = [p for p in policies if p[1] == t]
        print(f"    {t}: {len(t_policies)} policies")
else:
    print("  ✅ No policies remaining")

# ============================================================
# 3. SUPABASE ANON KEY PERMISSIONS
# ============================================================
print("\n📋 3. ANON ROLE PERMISSIONS")
print("-" * 40)
# Check if anon role has proper grants
cur.execute("""
    SELECT grantee, table_name, privilege_type
    FROM information_schema.table_privileges
    WHERE grantee = 'anon' AND table_schema = 'public'
    ORDER BY table_name, privilege_type
""")
anon_grants = cur.fetchall()
if anon_grants:
    # Group by table
    from collections import defaultdict
    grants_by_table = defaultdict(list)
    for g in anon_grants:
        grants_by_table[g[1]].append(g[2])
    
    # Check key tables have full CRUD
    key_tables = [
        'companies', 'employees', 'customers', 'customer_contacts', 
        'customer_addresses', 'sales_orders', 'sales_order_items',
        'products', 'product_categories', 'inventory', 'warehouses',
        'branches', 'store_visits', 'journey_plans', 'sales_routes',
    ]
    
    missing_grants = []
    for t in key_tables:
        if t in grants_by_table:
            privs = grants_by_table[t]
            needed = {'SELECT', 'INSERT', 'UPDATE', 'DELETE'}
            missing = needed - set(privs)
            if missing:
                missing_grants.append((t, missing))
                print(f"    ⚠️ {t}: has {privs}, MISSING {missing}")
            else:
                pass  # All good
        else:
            missing_grants.append((t, {'SELECT', 'INSERT', 'UPDATE', 'DELETE'}))
            print(f"    ❌ {t}: NO grants for anon role!")
    
    if not missing_grants:
        print(f"  ✅ All {len(key_tables)} key tables have full CRUD grants for anon")
    else:
        print(f"  ❌ {len(missing_grants)} tables with missing grants!")
    
    print(f"  Total tables with anon grants: {len(grants_by_table)}")
else:
    print("  ❌ NO grants for anon role at all!")

# ============================================================
# 4. CHECK AUTHENTICATED ROLE
# ============================================================
print("\n📋 4. AUTHENTICATED ROLE PERMISSIONS")
print("-" * 40)
cur.execute("""
    SELECT grantee, table_name, privilege_type
    FROM information_schema.table_privileges
    WHERE grantee = 'authenticated' AND table_schema = 'public'
    ORDER BY table_name, privilege_type
""")
auth_grants = cur.fetchall()
if auth_grants:
    from collections import defaultdict
    auth_by_table = defaultdict(list)
    for g in auth_grants:
        auth_by_table[g[1]].append(g[2])
    print(f"  Total tables with authenticated grants: {len(auth_by_table)}")
else:
    print("  ⚠️ No grants for authenticated role")

# ============================================================
# 5. KEY TABLES EXISTENCE CHECK
# ============================================================
print("\n📋 5. KEY TABLES EXISTENCE")
print("-" * 40)
cur.execute("""
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
""")
all_tables = set(r[0] for r in cur.fetchall())

required_tables = [
    'companies', 'employees', 'customers', 'customer_contacts',
    'customer_addresses', 'sales_orders', 'sales_order_items',
    'products', 'product_categories', 'inventory', 'warehouses',
    'branches', 'store_visits', 'journey_plans', 'journey_plan_stops',
    'sales_routes', 'route_customers', 'daily_reports', 'debt_records',
]
missing = [t for t in required_tables if t not in all_tables]
if missing:
    print(f"  ❌ Missing tables: {missing}")
else:
    print(f"  ✅ All {len(required_tables)} required tables exist")
print(f"  Total public tables: {len(all_tables)}")

# ============================================================
# 6. employee_login RPC CHECK
# ============================================================
print("\n📋 6. CRITICAL RPCs")
print("-" * 40)
rpcs = ['employee_login', 'change_employee_password', 'get_daily_report', 
        'get_dashboard_stats', 'get_revenue_summary']
for rpc in rpcs:
    cur.execute("""
        SELECT COUNT(*) FROM information_schema.routines 
        WHERE routine_name = %s AND routine_schema = 'public'
    """, (rpc,))
    exists = cur.fetchone()[0] > 0
    print(f"  {'✅' if exists else '❌'} {rpc}")

# ============================================================
# 7. DATA INTEGRITY
# ============================================================
print("\n📋 7. DATA INTEGRITY CHECKS")
print("-" * 40)

# Check employees with NULL company_id
cur.execute("SELECT COUNT(*) FROM employees WHERE company_id IS NULL")
null_company = cur.fetchone()[0]
print(f"  Employees with NULL company_id: {null_company} {'❌' if null_company else '✅'}")

# Check customers with NULL company_id
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id IS NULL")
null_company = cur.fetchone()[0]
print(f"  Customers with NULL company_id: {null_company} {'❌' if null_company else '✅'}")

# Check customer_contacts with NULL company_id
cur.execute("SELECT COUNT(*) FROM customer_contacts WHERE company_id IS NULL")
null_company = cur.fetchone()[0]
print(f"  Customer contacts with NULL company_id: {null_company} {'❌' if null_company else '✅'}")

# Check sales_orders with NULL company_id
try:
    cur.execute("SELECT COUNT(*) FROM sales_orders WHERE company_id IS NULL")
    null_company = cur.fetchone()[0]
    print(f"  Sales orders with NULL company_id: {null_company} {'❌' if null_company else '✅'}")
except:
    conn.rollback()
    print(f"  Sales orders: no company_id column (OK)")

# Check products with NULL company_id
try:
    cur.execute("SELECT COUNT(*) FROM products WHERE company_id IS NULL")
    null_company = cur.fetchone()[0]
    print(f"  Products with NULL company_id: {null_company} {'❌' if null_company else '✅'}")
except:
    conn.rollback()
    print(f"  Products: no company_id column")

# ============================================================
# 8. TEST ACTUAL OPERATIONS (simulate what the app does)
# ============================================================
print("\n📋 8. SIMULATED APP OPERATIONS")
print("-" * 40)

# Test SELECT on key tables
test_tables = ['companies', 'employees', 'customers', 'customer_contacts',
               'customer_addresses', 'products', 'sales_orders', 'inventory']
for t in test_tables:
    try:
        cur.execute(f'SELECT COUNT(*) FROM "{t}"')
        count = cur.fetchone()[0]
        print(f"  ✅ SELECT {t}: {count} rows")
    except Exception as e:
        conn.rollback()
        print(f"  ❌ SELECT {t}: {e}")

# ============================================================
# 9. CHECK FOR BROKEN FOREIGN KEYS
# ============================================================
print("\n📋 9. FOREIGN KEY INTEGRITY")
print("-" * 40)

# customer_contacts -> customers
cur.execute("""
    SELECT COUNT(*) FROM customer_contacts cc 
    LEFT JOIN customers c ON cc.customer_id = c.id 
    WHERE c.id IS NULL
""")
orphans = cur.fetchone()[0]
print(f"  customer_contacts orphans (no customer): {orphans} {'❌' if orphans else '✅'}")

# customer_contacts -> companies
cur.execute("""
    SELECT COUNT(*) FROM customer_contacts cc 
    LEFT JOIN companies c ON cc.company_id = c.id 
    WHERE cc.company_id IS NOT NULL AND c.id IS NULL
""")
orphans = cur.fetchone()[0]
print(f"  customer_contacts broken company_id: {orphans} {'❌' if orphans else '✅'}")

# sales_orders -> customers
try:
    cur.execute("""
        SELECT COUNT(*) FROM sales_orders so 
        LEFT JOIN customers c ON so.customer_id = c.id 
        WHERE c.id IS NULL
    """)
    orphans = cur.fetchone()[0]
    print(f"  sales_orders orphans (no customer): {orphans} {'❌' if orphans else '✅'}")
except:
    conn.rollback()
    print(f"  sales_orders FK check: skipped")

# employees -> companies
cur.execute("""
    SELECT COUNT(*) FROM employees e 
    LEFT JOIN companies c ON e.company_id = c.id 
    WHERE e.company_id IS NOT NULL AND c.id IS NULL
""")
orphans = cur.fetchone()[0]
print(f"  employees broken company_id: {orphans} {'❌' if orphans else '✅'}")

# ============================================================
# 10. CEO ACCOUNTS CHECK
# ============================================================
print("\n📋 10. CEO ACCOUNTS (can login via employee_login?)")
print("-" * 40)
cur.execute("""
    SELECT id, full_name, username, role, company_id, 
           password_hash IS NOT NULL as has_password
    FROM employees 
    WHERE role = 'ceo'
""")
for r in cur.fetchall():
    print(f"  {'✅' if r[5] else '❌'} {r[1]} (username={r[2]}, has_password={r[5]})")

# ============================================================
# SUMMARY
# ============================================================
print("\n" + "=" * 60)
print("  AUDIT COMPLETE")
print("=" * 60)

conn.close()
