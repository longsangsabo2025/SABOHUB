import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Check columns
cur.execute("""
    SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns 
    WHERE table_name = 'customer_visits' AND table_schema = 'public' 
    ORDER BY ordinal_position
""")
print('=== customer_visits columns ===')
for r in cur.fetchall():
    print(r)

# Check foreign keys
cur.execute("""
    SELECT tc.constraint_name, kcu.column_name, ccu.table_name AS foreign_table, ccu.column_name AS foreign_column 
    FROM information_schema.table_constraints tc 
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
    WHERE tc.table_name = 'customer_visits' AND tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
""")
print('\n=== customer_visits foreign keys ===')
for r in cur.fetchall():
    print(r)

# Check orders tables
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE '%order%'")
print('\n=== order tables ===')
for r in cur.fetchall():
    print(r)

# Check sales_orders columns
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'sales_orders' AND table_schema = 'public' AND column_name IN ('id','order_number','total','total_amount')
""")
print('\n=== sales_orders relevant columns ===')
for r in cur.fetchall():
    print(r)

# Add FK constraint
try:
    cur.execute("""
        ALTER TABLE customer_visits 
        ADD CONSTRAINT customer_visits_order_id_fkey 
        FOREIGN KEY (order_id) REFERENCES sales_orders(id) ON DELETE SET NULL
    """)
    conn.commit()
    print('\n✅ FK constraint customer_visits_order_id_fkey added successfully!')
except Exception as e:
    conn.rollback()
    print(f'\n❌ FK error: {e}')

conn.close()
