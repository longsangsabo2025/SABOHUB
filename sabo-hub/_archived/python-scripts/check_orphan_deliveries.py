import psycopg2

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    database="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

print("=== Checking orphan deliveries (order_id not in sales_orders) ===")
cur.execute("""
    SELECT d.id, d.delivery_number, d.order_id, d.status
    FROM deliveries d
    LEFT JOIN sales_orders so ON d.order_id = so.id
    WHERE so.id IS NULL
    ORDER BY d.updated_at DESC
    LIMIT 20
""")
orphans = cur.fetchall()
print(f"Found {len(orphans)} orphan deliveries:")
for row in orphans:
    print(f"  {row[1]} | order_id: {row[2]} | status: {row[3]}")

if orphans:
    print("\n=== Fixing: Setting is_active=false for orphan deliveries ===")
    cur.execute("""
        UPDATE deliveries d
        SET is_active = false
        FROM (
            SELECT d.id
            FROM deliveries d
            LEFT JOIN sales_orders so ON d.order_id = so.id
            WHERE so.id IS NULL
        ) orphan
        WHERE d.id = orphan.id
    """)
    print(f"Updated {cur.rowcount} rows")
    conn.commit()

cur.close()
conn.close()
print("Done!")
