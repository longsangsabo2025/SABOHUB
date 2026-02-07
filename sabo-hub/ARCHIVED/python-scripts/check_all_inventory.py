import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Count all inventory records
cur.execute('SELECT COUNT(*) FROM inventory')
print(f'Total inventory records: {cur.fetchone()[0]}')

# Count all movements
cur.execute('SELECT COUNT(*) FROM inventory_movements')
print(f'Total movements: {cur.fetchone()[0]}')

# Check all inventory with movements
cur.execute("""
SELECT p.name, p.sku, w.name as warehouse, i.quantity
FROM inventory i
JOIN products p ON p.id = i.product_id
JOIN warehouses w ON w.id = i.warehouse_id
ORDER BY p.name
""")
print('\n=== ALL INVENTORY ===')
for row in cur.fetchall():
    print(f'{row[0]} ({row[1]}) @ {row[2]}: {row[3]}')

# Check all movements
cur.execute("""
SELECT p.name, m.type, m.quantity, m.before_quantity, m.after_quantity, m.created_at, m.reason
FROM inventory_movements m
JOIN products p ON p.id = m.product_id
ORDER BY m.created_at DESC
""")
print('\n=== ALL MOVEMENTS (RECENT) ===')
for row in cur.fetchall():
    print(f'{row[0]}: {row[1]} +{row[2]} ({row[3]}->{row[4]}) @ {row[5]} | {row[6]}')

conn.close()
