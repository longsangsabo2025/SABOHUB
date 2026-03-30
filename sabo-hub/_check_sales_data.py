"""Check sales-related data consistency."""
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

print("=" * 60)
print("SALES ROLE DATA CONSISTENCY CHECK")
print("=" * 60)

# 1. Check for duplicate order numbers
cur.execute("""
    SELECT order_number, COUNT(*) as cnt
    FROM sales_orders
    GROUP BY order_number
    HAVING COUNT(*) > 1
""")
dupes = cur.fetchall()
print(f"\n1. Duplicate order numbers: {len(dupes)}")
for r in dupes:
    print(f"   {r[0]}: {r[1]} copies")

# 2. Check orders missing created_by
cur.execute("""
    SELECT COUNT(*) FROM sales_orders WHERE created_by IS NULL
""")
print(f"\n2. Orders missing created_by: {cur.fetchone()[0]}")

# 3. Check orders missing customer_name
cur.execute("""
    SELECT COUNT(*) FROM sales_orders WHERE customer_name IS NULL OR customer_name = ''
""")
print(f"\n3. Orders missing customer_name: {cur.fetchone()[0]}")

# 4. Check orders missing payment_status
cur.execute("""
    SELECT COUNT(*) FROM sales_orders WHERE payment_status IS NULL OR payment_status = ''
""")
print(f"\n4. Orders missing payment_status: {cur.fetchone()[0]}")

# 5. Order number format distribution
cur.execute("""
    SELECT 
        CASE 
            WHEN order_number LIKE 'SO-2%' THEN 'SO-timestamp (13 digits)'
            WHEN order_number LIKE 'SO2%' THEN 'SO+substring (8 digits)'
            WHEN order_number LIKE 'SO-%' THEN 'SO-YYMMDD format'
            ELSE 'other: ' || LEFT(order_number, 15)
        END as format,
        COUNT(*), MIN(order_number), MAX(order_number)
    FROM sales_orders
    GROUP BY 1
    ORDER BY 2 DESC
""")
print(f"\n5. Order number formats:")
for r in cur.fetchall():
    print(f"   {r[0]}: {r[1]} orders (min={r[2]}, max={r[3]})")

# 6. Orders with sale_id set
cur.execute("""
    SELECT 
        COUNT(*) as total,
        COUNT(sale_id) as with_sale_id,
        COUNT(*) - COUNT(sale_id) as missing_sale_id
    FROM sales_orders
""")
r = cur.fetchone()
print(f"\n6. sale_id: {r[0]} total, {r[1]} with sale_id, {r[2]} missing")

# 7. Check if customer_name column even exists
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'sales_orders' AND column_name = 'customer_name'
""")
print(f"\n7. customer_name column exists: {len(cur.fetchall()) > 0}")

# 8. Check if order_number has UNIQUE constraint
cur.execute("""
    SELECT tc.constraint_name, tc.constraint_type
    FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu 
        ON tc.constraint_name = ccu.constraint_name
    WHERE tc.table_name = 'sales_orders' 
    AND ccu.column_name = 'order_number'
""")
constraints = cur.fetchall()
print(f"\n8. order_number constraints: {constraints if constraints else 'NONE'}")

# 9. Verify sale_id references correct employee
cur.execute("""
    SELECT so.id, so.order_number, so.sale_id, e.full_name, e.role
    FROM sales_orders so
    JOIN employees e ON e.id = so.sale_id
    WHERE e.role != 'staff'
    LIMIT 10
""")
non_staff = cur.fetchall()
print(f"\n9. Orders where sale_id is NOT 'staff' role: {len(non_staff)}")
for r in non_staff:
    print(f"   {r[1]}: sale={r[3]} (role={r[4]})")

cur.close()
conn.close()
print("\n" + "=" * 60)
print("CHECK COMPLETE")
