import psycopg2

TABLES = ['store_visits', 'sales_orders', 'product_samples', 'store_visit_photos', 'survey_responses']

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

for table in TABLES:
    print(f'=== {table} columns ===')
    cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = %s
    ORDER BY ordinal_position
    """, (table,))
    for row in cur.fetchall():
        print(row)
    print()

conn.close()
