import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check inventory for product 'Tay co ao ben mau'
cur.execute('''
SELECT i.id, i.quantity, i.warehouse_id, w.name as warehouse_name, i.updated_at
FROM inventory i
JOIN warehouses w ON w.id = i.warehouse_id
JOIN products p ON p.id = i.product_id
WHERE p.name ILIKE '%cổ áo%' OR p.sku = 'TC'
ORDER BY i.updated_at DESC
''')
print('=== INVENTORY RECORDS ===')
for row in cur.fetchall():
    print(f'ID: {row[0][:8]}... | Qty: {row[1]} | Warehouse: {row[3]} | Updated: {row[4]}')

# Check movements - ALL for this product (no filter on warehouse)
cur.execute('''
SELECT m.quantity, m.type, m.before_quantity, m.after_quantity, m.created_at, m.reason, w.name
FROM inventory_movements m
JOIN products p ON p.id = m.product_id
LEFT JOIN warehouses w ON w.id = m.warehouse_id
WHERE p.sku = 'TC'
ORDER BY m.created_at ASC
''')
print('\n=== ALL MOVEMENTS FOR TC ===')
rows = cur.fetchall()
print(f'Total: {len(rows)} movements')
for i, row in enumerate(rows, 1):
    print(f'{i}. Type: {row[1]} | Qty: +{row[0]} | {row[2]} -> {row[3]} | {row[4]} | {row[5]} | Kho: {row[6]}')

conn.close()
