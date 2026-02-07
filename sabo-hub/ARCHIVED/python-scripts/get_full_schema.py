import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-app/SABOHUB/.env')
conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_str)
cur = conn.cursor()

# Get ALL table columns
tables_to_check = [
    'sales_orders', 'sales_order_items', 'customers', 'customer_payments', 
    'deliveries', 'delivery_items', 'employees', 'companies', 'branches',
    'warehouses', 'inventory', 'inventory_movements', 'stock_movements',
    'products', 'product_categories', 'product_samples',
    'commissions', 'referrers', 'receivables', 'payment_allocations',
    'notifications', 'gps_locations', 'journey_plans', 'journey_plan_stops',
    'journey_checkins', 'tasks', 'documents', 'attendance', 'stores',
    'support_tickets', 'customer_visits', 'daily_reports',
    'ai_prompts', 'ai_projects', 'ai_models', 'ai_assistants',
    'company_settings', 'role_permissions', 'employee_documents',
    'customer_addresses', 'user_settings'
]

for table in tables_to_check:
    cur.execute("""
        SELECT column_name FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = %s
        ORDER BY ordinal_position
    """, (table,))
    cols = cur.fetchall()
    if cols:
        col_names = [c[0] for c in cols]
        print(f"{table} ({len(cols)} cols): {', '.join(col_names)}")
    # Don't print "not found" - will check missing tables below

# Check ALL tables in public schema
print("\n" + "=" * 60)
print("ALL PUBLIC TABLES")
print("=" * 60)
cur.execute("""
    SELECT table_name FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ORDER BY table_name
""")
all_tables = [r[0] for r in cur.fetchall()]
print(f"Total: {len(all_tables)}")
for t in all_tables:
    print(f"  {t}")

# Check all CHECK constraints
print("\n" + "=" * 60)
print("ALL CHECK CONSTRAINTS")
print("=" * 60)
cur.execute("""
    SELECT rel.relname, con.conname, pg_get_constraintdef(con.oid)
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public' AND con.contype = 'c'
    ORDER BY rel.relname, con.conname
""")
for r in cur.fetchall():
    print(f"  {r[0]}.{r[1]}: {r[2]}")

# Check all RPC functions
print("\n" + "=" * 60)
print("ALL RPC FUNCTIONS")
print("=" * 60)
cur.execute("""
    SELECT routine_name FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_type = 'FUNCTION'
    ORDER BY routine_name
""")
for r in cur.fetchall():
    print(f"  {r[0]}")

# Key distinct values
print("\n" + "=" * 60)
print("KEY DISTINCT VALUES")
print("=" * 60)

distinct_checks = [
    ("employees", "role"),
    ("deliveries", "status"),
    ("tasks", "status"),
    ("tasks", "priority"),
    ("support_tickets", "status"),
    ("support_tickets", "priority"),
    ("notifications", "type"),
    ("daily_reports", "status"),
]

for table, col in distinct_checks:
    try:
        cur.execute(f"SELECT {col}, COUNT(*) FROM {table} GROUP BY {col} ORDER BY count DESC")
        rows = cur.fetchall()
        print(f"\n{table}.{col}:")
        for r in rows:
            print(f"  {r[0]}: {r[1]}")
    except Exception as e:
        conn.rollback()
        print(f"\n{table}.{col}: ERROR - {e}")

cur.close()
conn.close()
print("\nDone.")
