import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

print("=== ADDING UNIQUE CONSTRAINT ON deliveries.order_id ===")

# Check if constraint already exists
cur.execute('''
    SELECT constraint_name FROM information_schema.table_constraints 
    WHERE table_name = 'deliveries' AND constraint_type = 'UNIQUE'
''')
existing = cur.fetchall()
print(f"Existing unique constraints: {existing}")

try:
    cur.execute('''
        ALTER TABLE deliveries 
        ADD CONSTRAINT deliveries_order_id_unique UNIQUE (order_id)
    ''')
    conn.commit()
    print("✅ Added unique constraint on deliveries.order_id")
except Exception as e:
    print(f"⚠️ Could not add constraint: {e}")
    conn.rollback()

conn.close()
