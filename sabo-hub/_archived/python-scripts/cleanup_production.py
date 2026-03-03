"""
SABOHUB DATA CLEANUP - Trước khi vận hành thực tế
===================================================
A: Xoá 128 khách "No Name" (0 đơn)
B: Xoá khách test "teét123" + đơn test liên quan
D: Xoá TẤT CẢ đơn trước 24/02/2026 (giữ đơn hôm nay)
E: Reset total_debt = 0 cho tất cả KH
F: Reset inventory về 0
"""
import psycopg2
from datetime import date

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

COMPANY_ID = '9f8921df-3760-44b5-9a7f-20f8484b0300'
TODAY = '2026-02-24'

print("=" * 60)
print("🧹 SABOHUB DATA CLEANUP")
print("=" * 60)

# ============================================================
# STEP D: Xoá đơn hàng trước 24/02 (phải xoá trước vì có FK)
# ============================================================
print("\n📦 [D] Xoá đơn hàng trước 24/02/2026...")

# D.1: Xoá order_items của đơn cũ
cur.execute("""
    DELETE FROM sales_order_items 
    WHERE order_id IN (
        SELECT id FROM sales_orders 
        WHERE company_id = %s AND DATE(created_at) < %s
    )
""", (COMPANY_ID, TODAY))
items_deleted = cur.rowcount
print(f"  - Xoá {items_deleted} dòng sales_order_items")

# D.2: Xoá đơn hàng cũ
cur.execute("""
    DELETE FROM sales_orders 
    WHERE company_id = %s AND DATE(created_at) < %s
""", (COMPANY_ID, TODAY))
orders_deleted = cur.rowcount
print(f"  - Xoá {orders_deleted} đơn hàng cũ")

# ============================================================
# STEP B: Xoá khách test "teét123" + đơn test còn lại
# ============================================================
print("\n🧪 [B] Xoá khách test 'teét123'...")

# B.1: Tìm customer test
cur.execute("SELECT id FROM customers WHERE company_id = %s AND name ILIKE '%%teét%%'", (COMPANY_ID,))
test_customers = [row[0] for row in cur.fetchall()]
print(f"  - Tìm thấy {len(test_customers)} khách test")

for cid in test_customers:
    # Xoá order items
    cur.execute("DELETE FROM sales_order_items WHERE order_id IN (SELECT id FROM sales_orders WHERE customer_id = %s)", (cid,))
    print(f"    - Xoá {cur.rowcount} order items")
    # Xoá orders
    cur.execute("DELETE FROM sales_orders WHERE customer_id = %s", (cid,))
    print(f"    - Xoá {cur.rowcount} orders")
    # Xoá customer addresses
    cur.execute("DELETE FROM customer_addresses WHERE customer_id = %s", (cid,))
    print(f"    - Xoá {cur.rowcount} addresses")
    # Xoá receivables (if exists)
    try:
        cur.execute("SAVEPOINT before_receivables")
        cur.execute("DELETE FROM receivables WHERE customer_id = %s", (cid,))
        print(f"    - Xoá {cur.rowcount} receivables")
        cur.execute("RELEASE SAVEPOINT before_receivables")
    except:
        cur.execute("ROLLBACK TO SAVEPOINT before_receivables")
    # Xoá customer
    cur.execute("DELETE FROM customers WHERE id = %s", (cid,))
    print(f"    - Xoá khách: {cid[:8]}...")

# ============================================================
# STEP A: Xoá 128 khách "No Name" (0 đơn)
# ============================================================
print("\n👤 [A] Xoá khách 'No Name' (0 đơn)...")

# Only delete No Name customers that have 0 orders
# First, clean up receivables for No Name customers
try:
    cur.execute("SAVEPOINT before_noname_receivables")
    cur.execute("""
        DELETE FROM receivables 
        WHERE customer_id IN (
            SELECT c.id FROM customers c
            WHERE c.company_id = %s AND c.name = 'No Name'
            AND NOT EXISTS (SELECT 1 FROM sales_orders so WHERE so.customer_id = c.id)
        )
    """, (COMPANY_ID,))
    print(f"  - Xoá {cur.rowcount} receivables của No Name")
    cur.execute("RELEASE SAVEPOINT before_noname_receivables")
except:
    cur.execute("ROLLBACK TO SAVEPOINT before_noname_receivables")

cur.execute("""
    DELETE FROM customer_addresses 
    WHERE customer_id IN (
        SELECT c.id FROM customers c
        WHERE c.company_id = %s AND c.name = 'No Name'
        AND NOT EXISTS (SELECT 1 FROM sales_orders so WHERE so.customer_id = c.id)
    )
""", (COMPANY_ID,))
print(f"  - Xoá {cur.rowcount} addresses của No Name")

cur.execute("""
    DELETE FROM customers 
    WHERE company_id = %s AND name = 'No Name'
    AND NOT EXISTS (SELECT 1 FROM sales_orders so WHERE so.customer_id = id)
""", (COMPANY_ID,))
noname_deleted = cur.rowcount
print(f"  - Xoá {noname_deleted} khách No Name")

# ============================================================
# STEP E: Reset total_debt = 0 cho tất cả KH
# ============================================================
print("\n💳 [E] Reset total_debt = 0 cho tất cả KH...")

cur.execute("""
    UPDATE customers SET total_debt = 0 
    WHERE company_id = %s AND (total_debt IS NOT NULL AND total_debt != 0)
""", (COMPANY_ID,))
debt_reset = cur.rowcount
print(f"  - Reset nợ cho {debt_reset} khách hàng")

# ============================================================
# STEP F: Reset inventory về 0
# ============================================================
print("\n📦 [F] Reset inventory về 0...")

cur.execute("""
    UPDATE inventory SET quantity = 0 
    WHERE company_id = %s AND quantity != 0
""", (COMPANY_ID,))
inv_reset = cur.rowcount
print(f"  - Reset {inv_reset} records inventory về 0")

# ============================================================
# VERIFY
# ============================================================
print("\n" + "=" * 60)
print("📊 KẾT QUẢ SAU DỌN DẸP")
print("=" * 60)

cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s", (COMPANY_ID,))
print(f"  Khách hàng còn lại: {cur.fetchone()[0]}")

cur.execute("SELECT COUNT(*) FROM sales_orders WHERE company_id = %s", (COMPANY_ID,))
print(f"  Đơn hàng còn lại: {cur.fetchone()[0]}")

cur.execute("SELECT COUNT(*) FROM sales_order_items soi JOIN sales_orders so ON soi.order_id = so.id WHERE so.company_id = %s", (COMPANY_ID,))
print(f"  Order items còn lại: {cur.fetchone()[0]}")

cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND total_debt != 0", (COMPANY_ID,))
print(f"  KH có nợ != 0: {cur.fetchone()[0]}")

cur.execute("SELECT COUNT(*) FROM inventory WHERE company_id = %s AND quantity != 0", (COMPANY_ID,))
print(f"  Inventory quantity != 0: {cur.fetchone()[0]}")

cur.execute("SELECT status, COUNT(*) FROM sales_orders WHERE company_id = %s GROUP BY status", (COMPANY_ID,))
remaining = cur.fetchall()
if remaining:
    for r in remaining:
        print(f"  Đơn {r[0]}: {r[1]}")
else:
    print("  Không còn đơn hàng nào")

# COMMIT
conn.commit()
print("\n✅ ĐÃ COMMIT - Dọn dẹp hoàn tất!")
print("=" * 60)

cur.close()
conn.close()
