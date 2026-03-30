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

# Fix 5 stuck orders: delivery_status='delivering', assigned to asm.nam (MANAGER role)
stuck_order_ids = [
    'e6bdadef-12a3-4b40-99ff-8ad9b5e3eef5',
    '10d44bdc-7129-47bb-83d8-e0e0c6ea068f',
    'aaa9a4d8-cbc1-438f-8419-91a46da5bf09',
    '2dcfa792-a278-4fe5-b9fd-84204ee7c75c',
    '4dd979a2-3932-42b2-83a7-3d2f145cfa48',
]

# Show current state
cur.execute("""
    SELECT id, order_number, status, delivery_status, payment_status
    FROM sales_orders WHERE id = ANY(%s::uuid[])
""", (stuck_order_ids,))
print("=== BEFORE ===")
for row in cur.fetchall():
    print(f"  {row[1]}: status={row[2]}, delivery={row[3]}, payment={row[4]}")

# Fix deliveries: mark as completed
cur.execute("""
    UPDATE deliveries SET status = 'completed', completed_at = NOW(), updated_at = NOW()
    WHERE order_id = ANY(%s::uuid[]) AND status = 'in_progress'
    RETURNING id, order_id
""", (stuck_order_ids,))
fixed_deliveries = cur.fetchall()
print(f"\nFixed {len(fixed_deliveries)} deliveries")

# Fix sales_orders: mark delivery_status as delivered
cur.execute("""
    UPDATE sales_orders SET delivery_status = 'delivered', updated_at = NOW()
    WHERE id = ANY(%s::uuid[]) AND delivery_status = 'delivering'
    RETURNING id, order_number
""", (stuck_order_ids,))
fixed_orders = cur.fetchall()
print(f"Fixed {len(fixed_orders)} orders")

# Add history entries for audit trail
for order_id in stuck_order_ids:
    cur.execute("""
        INSERT INTO sales_order_history (order_id, from_status, to_status, action, notes, created_by)
        VALUES (%s::uuid, 'delivering', 'delivered', 'delivery_status', 'Auto-fix: stuck order assigned to MANAGER role', NULL)
    """, (order_id,))

conn.commit()

# Verify
cur.execute("""
    SELECT id, order_number, status, delivery_status, payment_status
    FROM sales_orders WHERE id = ANY(%s::uuid[])
""", (stuck_order_ids,))
print("\n=== AFTER ===")
for row in cur.fetchall():
    print(f"  {row[1]}: status={row[2]}, delivery={row[3]}, payment={row[4]}")

cur.close()
conn.close()
print("\nDone! All stuck orders fixed.")
