import psycopg2, os
from dotenv import load_dotenv

load_dotenv('sabohub-automation/.env')
url = os.getenv('DATABASE_URL')
print(f'Using: {url[:50]}...')

conn = psycopg2.connect(url)
cur = conn.cursor()

# 1. List all user tables
cur.execute("""
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name
""")
tables = [r[0] for r in cur.fetchall()]
print(f'\n{"="*60}')
print(f' ALL TABLES ({len(tables)})')
print(f'{"="*60}')
for t in tables:
    cur.execute(f"SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='{t}'")
    col_count = cur.fetchone()[0]
    try:
        cur.execute(f'SELECT count(*) FROM "{t}"')
        row_count = cur.fetchone()[0]
    except:
        conn.rollback()
        row_count = '?'
    print(f'  {t}: {col_count} cols, {row_count} rows')

# 2. List all views
cur.execute("""
SELECT table_name FROM information_schema.views 
WHERE table_schema = 'public'
ORDER BY table_name
""")
views = [r[0] for r in cur.fetchall()]
print(f'\n{"="*60}')
print(f' ALL VIEWS ({len(views)})')
print(f'{"="*60}')
for v in views:
    print(f'  {v}')

# 3. Finance-related tables - detailed schema
finance_tables = [
    'sales_orders', 'sales_order_items', 'customers', 
    'customer_payments', 'receivables', 'payment_allocations',
    'products', 'warehouses', 'inventory', 'companies', 'branches',
    'employees', 'visits', 'product_samples'
]

print(f'\n{"="*60}')
print(f' DETAILED SCHEMA FOR FINANCE-RELATED TABLES')
print(f'{"="*60}')

for table in finance_tables:
    if table not in tables:
        print(f'\n--- {table}: NOT FOUND ---')
        continue
    
    cur.execute(f"""
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = '{table}'
    ORDER BY ordinal_position
    """)
    cols = cur.fetchall()
    cur.execute(f'SELECT count(*) FROM "{table}"')
    row_count = cur.fetchone()[0]
    
    print(f'\n--- {table} ({len(cols)} cols, {row_count} rows) ---')
    for col_name, data_type, nullable, default in cols:
        default_str = f' DEFAULT {default[:40]}' if default else ''
        null_str = ' NULL' if nullable == 'YES' else ' NOT NULL'
        print(f'  {col_name}: {data_type}{null_str}{default_str}')

# 4. Check RPC functions
cur.execute("""
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name
""")
funcs = cur.fetchall()
print(f'\n{"="*60}')
print(f' RPC FUNCTIONS ({len(funcs)})')
print(f'{"="*60}')
for name, rtype in funcs:
    print(f'  {name} ({rtype})')

# 5. Check triggers
cur.execute("""
SELECT trigger_name, event_manipulation, event_object_table, action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name
""")
triggers = cur.fetchall()
print(f'\n{"="*60}')
print(f' TRIGGERS ({len(triggers)})')
print(f'{"="*60}')
for tname, event, obj_table, timing in triggers:
    print(f'  {tname}: {timing} {event} ON {obj_table}')

# 6. Distinct values for key enum-like columns
print(f'\n{"="*60}')
print(f' KEY COLUMN DISTINCT VALUES')
print(f'{"="*60}')

checks = [
    ('sales_orders', 'status'),
    ('sales_orders', 'payment_status'),
    ('sales_orders', 'delivery_status'),
    ('sales_orders', 'payment_method'),
    ('sales_orders', 'priority'),
    ('sales_orders', 'source'),
    ('customer_payments', 'payment_method'),
    ('receivables', 'status'),
]
for table, col in checks:
    try:
        cur.execute(f'SELECT "{col}", count(*) FROM "{table}" GROUP BY "{col}" ORDER BY count(*) DESC')
        rows = cur.fetchall()
        vals = ', '.join([f'{v}({c})' for v, c in rows])
        print(f'  {table}.{col}: {vals}')
    except Exception as e:
        conn.rollback()
        print(f'  {table}.{col}: ERROR - {e}')

conn.close()
print('\nDone!')
