import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Find and delete duplicate deliveries (keep the earliest one)
print("=== FIXING DUPLICATE DELIVERIES ===")

# Get all duplicates individually
cur.execute('''
    WITH ranked AS (
        SELECT id, order_id, created_at,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY created_at ASC) as rn
        FROM deliveries
    )
    SELECT id, order_id FROM ranked WHERE rn > 1
''')
to_delete = cur.fetchall()

for row in to_delete:
    delivery_id = row[0]
    order_id = row[1]
    print(f"Deleting duplicate: {delivery_id} (order: {order_id})")
    cur.execute('DELETE FROM deliveries WHERE id = %s', (str(delivery_id),))

conn.commit()
print("\n=== VERIFICATION ===")

# Verify no more duplicates
cur.execute('''
    SELECT order_id, COUNT(*) as cnt 
    FROM deliveries 
    GROUP BY order_id 
    HAVING COUNT(*) > 1
''')
duplicates_left = cur.fetchall()
if duplicates_left:
    print("⚠️ Still have duplicates:", duplicates_left)
else:
    print("✅ All duplicates removed!")

conn.close()
