import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Get trigger function definition
cur.execute("SELECT pg_get_functiondef(p.oid) FROM pg_proc p WHERE p.proname = 'process_inventory_movement'")
row = cur.fetchone()
print('=== process_inventory_movement FUNCTION ===')
print(row[0] if row else 'Not found')

conn.close()
