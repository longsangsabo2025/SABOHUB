"""
Audit current database data to plan cleanup before production launch.
"""
import psycopg2
from datetime import datetime

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

COMPANY_ID = '9f8921df-3760-44b5-9a7f-20f8484b0300'

print("=" * 70)
print("📊 SABOHUB DATA AUDIT - Trước khi vận hành thực tế")
print("=" * 70)

# 1. CUSTOMERS
print("\n🏢 KHÁCH HÀNG (customers)")
print("-" * 50)
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s", (COMPANY_ID,))
total_customers = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND status = 'active'", (COMPANY_ID,))
active_customers = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND status != 'active'", (COMPANY_ID,))
inactive_customers = cur.fetchone()[0]
print(f"  Tổng: {total_customers} | Active: {active_customers} | Inactive/Blocked: {inactive_customers}")

# Show customer list with details
cur.execute("""
    SELECT c.id, c.name, c.type, c.phone, c.address, c.status, c.created_at,
           c.total_debt,
           (SELECT COUNT(*) FROM sales_orders so WHERE so.customer_id = c.id) as order_count
    FROM customers c 
    WHERE c.company_id = %s 
    ORDER BY c.created_at
""", (COMPANY_ID,))
customers = cur.fetchall()
print(f"\n  {'Tên KH':<30} {'Loại':<12} {'SĐT':<15} {'Active':<8} {'Đơn':<5} {'Nợ':<12} {'Ngày tạo'}")
print(f"  {'-'*30} {'-'*12} {'-'*15} {'-'*8} {'-'*5} {'-'*12} {'-'*12}")
for c in customers:
    name = (c[1] or '')[:28]
    ctype = (c[2] or '')[:10]
    phone = (c[3] or '')[:13]
    active = '✅' if c[5] == 'active' else '❌'
    orders = c[8] or 0
    debt = f"{c[7]:,.0f}" if c[7] else '0'
    created = c[6].strftime('%Y-%m-%d') if c[6] else ''
    print(f"  {name:<30} {ctype:<12} {phone:<15} {active:<8} {orders:<5} {debt:<12} {created}")

# 2. SALES ORDERS
print(f"\n📦 ĐƠN HÀNG (sales_orders)")
print("-" * 50)
cur.execute("SELECT COUNT(*) FROM sales_orders WHERE company_id = %s", (COMPANY_ID,))
total_orders = cur.fetchone()[0]
print(f"  Tổng đơn hàng: {total_orders}")

cur.execute("""
    SELECT status, COUNT(*), SUM(total) 
    FROM sales_orders WHERE company_id = %s 
    GROUP BY status ORDER BY COUNT(*) DESC
""", (COMPANY_ID,))
for row in cur.fetchall():
    print(f"  - {row[0]:<20}: {row[1]} đơn | Tổng: {row[2]:,.0f}đ" if row[2] else f"  - {row[0]:<20}: {row[1]} đơn")

# Orders by date
cur.execute("""
    SELECT DATE(created_at) as d, COUNT(*), SUM(total)
    FROM sales_orders WHERE company_id = %s
    GROUP BY DATE(created_at) ORDER BY d DESC LIMIT 10
""", (COMPANY_ID,))
print(f"\n  Đơn theo ngày (10 ngày gần nhất):")
for row in cur.fetchall():
    total_str = f"{row[2]:,.0f}đ" if row[2] else '0đ'
    print(f"  - {row[0]}: {row[1]} đơn | {total_str}")

# 3. SALES ORDER ITEMS (chi tiết đơn hàng)
print(f"\n📋 CHI TIẾT ĐƠN (sales_order_items)")
print("-" * 50)
cur.execute("""
    SELECT COUNT(*) FROM sales_order_items soi
    JOIN sales_orders so ON soi.order_id = so.id
    WHERE so.company_id = %s
""", (COMPANY_ID,))
print(f"  Tổng dòng: {cur.fetchone()[0]}")

# 4. PAYMENTS
print(f"\n💰 THANH TOÁN (payments)")
print("-" * 50)
cur.execute("SELECT COUNT(*) FROM payments WHERE company_id = %s", (COMPANY_ID,))
total_payments = cur.fetchone()[0]
print(f"  Tổng: {total_payments}")
cur.execute("""
    SELECT status, COUNT(*), SUM(amount) 
    FROM payments WHERE company_id = %s 
    GROUP BY status ORDER BY COUNT(*) DESC
""", (COMPANY_ID,))
for row in cur.fetchall():
    amt = f"{row[2]:,.0f}đ" if row[2] else '0đ'
    print(f"  - {row[0]:<20}: {row[1]} | {amt}")

# 5. INVOICES - table may not exist
print(f"\n\U0001f9fe HÓA ĐƠN (invoices)")
print("-" * 50)
try:
    cur.execute("SELECT COUNT(*) FROM invoices WHERE company_id = %s", (COMPANY_ID,))
    print(f"  Tổng: {cur.fetchone()[0]}")
except:
    conn.rollback()
    print("  Table không tồn tại")

# 6. INVENTORY
print(f"\n📦 TỒN KHO (inventory)")
print("-" * 50)
cur.execute("SELECT COUNT(*) FROM inventory WHERE company_id = %s", (COMPANY_ID,))
total_inv = cur.fetchone()[0]
cur.execute("""
    SELECT p.name, i.quantity, w.name as warehouse
    FROM inventory i
    JOIN products p ON i.product_id = p.id
    LEFT JOIN warehouses w ON i.warehouse_id = w.id
    WHERE i.company_id = %s AND i.quantity > 0
    ORDER BY p.name LIMIT 20
""", (COMPANY_ID,))
inv_items = cur.fetchall()
print(f"  Tổng records: {total_inv} | Có hàng: {len(inv_items)}")
for item in inv_items:
    print(f"  - {(item[0] or '')[:35]:<36} SL: {item[1]:<8} KHO: {item[2] or 'N/A'}")

# 7. PRODUCTS
print(f"\n🏷️  SẢN PHẨM (products)")
print("-" * 50)
cur.execute("SELECT COUNT(*) FROM products WHERE company_id = %s", (COMPANY_ID,))
total_products = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM products WHERE company_id = %s AND is_active = true", (COMPANY_ID,))
active_products = cur.fetchone()[0]
print(f"  Tổng: {total_products} | Active: {active_products}")

# 8. CUSTOMER ADDRESSES (branches)
print(f"\n📍 CHI NHÁNH KH (customer_addresses)")
print("-" * 50)
cur.execute("""
    SELECT COUNT(*) FROM customer_addresses ca
    JOIN customers c ON ca.customer_id = c.id
    WHERE c.company_id = %s
""", (COMPANY_ID,))
print(f"  Tổng: {cur.fetchone()[0]}")

# 9. EMPLOYEES
print(f"\n👤 NHÂN VIÊN (employees)")
print("-" * 50)
cur.execute("SELECT COUNT(*) FROM employees WHERE company_id = %s", (COMPANY_ID,))
total_emp = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM employees WHERE company_id = %s AND is_active = true", (COMPANY_ID,))
active_emp = cur.fetchone()[0]  # employees uses is_active (boolean)
print(f"  Tổng: {total_emp} | Active: {active_emp}")

# 10. DELIVERY ROUTES
print(f"\n🚚 TUYẾN GIAO HÀNG (delivery_routes)")
print("-" * 50)
cur.execute("""
    SELECT COUNT(*) FROM delivery_routes WHERE company_id = %s
""", (COMPANY_ID,))
print(f"  Tổng: {cur.fetchone()[0]}")

# 11. PRODUCT_SAMPLES
print(f"\n🎁 HÀNG MẪU (product_samples)")
print("-" * 50)
try:
    cur.execute("SELECT COUNT(*) FROM product_samples WHERE company_id = %s", (COMPANY_ID,))
    print(f"  Tổng: {cur.fetchone()[0]}")
except:
    conn.rollback()
    print("  Table không tồn tại")

# 12. Check for orphaned data
print(f"\n🔍 DỮ LIỆU ORPHAN")
print("-" * 50)
cur.execute("""
    SELECT COUNT(*) FROM sales_order_items soi
    WHERE NOT EXISTS (SELECT 1 FROM sales_orders so WHERE so.id = soi.order_id)
""")
orphan_items = cur.fetchone()[0]
print(f"  Sales order items không có đơn: {orphan_items}")

cur.execute("""
    SELECT COUNT(*) FROM payments p
    WHERE p.company_id = %s 
    AND p.order_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM sales_orders so WHERE so.id = p.order_id)
""", (COMPANY_ID,))
orphan_payments = cur.fetchone()[0]
print(f"  Payments không có đơn: {orphan_payments}")

# 13. Check total_debt on customers
print(f"\n💳 KIỂM TRA NỢ KHÁCH HÀNG (total_debt)")
print("-" * 50)
cur.execute("""
    SELECT c.name, c.total_debt
    FROM customers c
    WHERE c.company_id = %s AND (c.total_debt IS NOT NULL AND c.total_debt != 0)
    ORDER BY c.total_debt DESC
""", (COMPANY_ID,))
debts = cur.fetchall()
if debts:
    for d in debts:
        print(f"  - {(d[0] or '')[:30]:<32} Nợ: {d[1]:,.0f}đ")
else:
    print("  Không có khách nào có nợ")

cur.close()
conn.close()
print("\n" + "=" * 70)
print("✅ Audit hoàn tất")
print("=" * 70)
