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

# 1. Check both photo tables exist and row counts
for table in ['visit_photos', 'store_visit_photos']:
    cur.execute(f'SELECT COUNT(*) FROM {table}')
    print(f'{table}: {cur.fetchone()[0]} rows')

# 2. Check product_samples stats
cur.execute('SELECT status, COUNT(*) FROM product_samples GROUP BY status ORDER BY status')
print('\nProduct Samples by status:')
for row in cur.fetchall():
    print(f'  {row[0]}: {row[1]}')

# 3. Check samples with and without order_id
cur.execute('SELECT COUNT(*) FROM product_samples WHERE order_id IS NOT NULL')
with_order = cur.fetchone()[0]
cur.execute('SELECT COUNT(*) FROM product_samples WHERE order_id IS NULL')
without_order = cur.fetchone()[0]
print(f'\nSamples with order_id: {with_order}')
print(f'Samples without order_id: {without_order}')

# 4. Check sales_orders with order_type
cur.execute("SELECT order_type, COUNT(*) FROM sales_orders GROUP BY order_type ORDER BY order_type")
print('\nSales Orders by order_type:')
for row in cur.fetchall():
    print(f'  {row[0]}: {row[1]}')

# 5. Check if linked sample orders have order_type properly set
cur.execute("""
    SELECT so.id, so.order_number, so.order_type, so.status 
    FROM sales_orders so 
    JOIN product_samples ps ON ps.order_id = so.id 
    GROUP BY so.id, so.order_number, so.order_type, so.status
    LIMIT 10
""")
print('\nLinked sample orders (first 10):')
for row in cur.fetchall():
    print(f'  {row[1]} | type={row[2]} | status={row[3]}')

# 6. Check store visits stats
cur.execute('SELECT status, COUNT(*) FROM store_visits GROUP BY status ORDER BY status')
print('\nStore Visits by status:')
for row in cur.fetchall():
    print(f'  {row[0]}: {row[1]}')

# 7. Check columns of visit_photos vs store_visit_photos
for table in ['visit_photos', 'store_visit_photos']:
    cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name='{table}' ORDER BY ordinal_position")
    cols = [row[0] for row in cur.fetchall()]
    print(f'\n{table} columns: {cols}')

# 8. Check sales_orders missing order_type that are linked to samples
cur.execute("""
    SELECT COUNT(*) FROM sales_orders so 
    JOIN product_samples ps ON ps.order_id = so.id 
    WHERE so.order_type IS NULL OR so.order_type != 'sample'
""")
print(f'\nSample-linked orders WITHOUT order_type=sample: {cur.fetchone()[0]}')

# 9. Check add_sample_sheet orders (SM- prefix)
cur.execute("SELECT COUNT(*), order_type FROM sales_orders WHERE order_number LIKE 'SM-%' GROUP BY order_type")
print('\nSM- prefix orders:')
for row in cur.fetchall():
    print(f'  type={row[1]}: {row[0]}')

conn.close()
print('\nDone.')
