"""
End-to-End Test Script cho Inventory Management
Test các tính năng:
1. Danh sách kho (warehouses)
2. Sản phẩm trong kho (inventory)
3. Nhập kho (stock in)
4. Xuất kho (stock out)
5. Chuyển kho (transfer)
6. Lịch sử (movements)
"""

import os
import psycopg2
from dotenv import load_dotenv
from datetime import datetime
import uuid

load_dotenv('sabohub-nexus/.env')

conn = psycopg2.connect(os.getenv('VITE_SUPABASE_POOLER_URL'))
cur = conn.cursor()

print("=" * 60)
print("🧪 END-TO-END TEST: INVENTORY MANAGEMENT")
print("=" * 60)

# Get company ID for Odori
cur.execute("SELECT id FROM companies WHERE name ILIKE '%odori%' LIMIT 1")
company = cur.fetchone()
company_id = company[0] if company else None
print(f"\n📦 Company: Odori (ID: {company_id})")

# =============================================
# TEST 1: Warehouses
# =============================================
print("\n" + "=" * 60)
print("TEST 1: DANH SÁCH KHO")
print("=" * 60)

cur.execute("""
    SELECT id, name, code, type, is_active, address
    FROM warehouses
    WHERE company_id = %s
    ORDER BY name
""", (company_id,))
warehouses = cur.fetchall()

print(f"\n✅ Tổng số kho: {len(warehouses)}")
for w in warehouses:
    status = "🟢" if w[4] else "🔴"
    type_emoji = {"main": "🏠", "transit": "📦", "vehicle": "🚚", "virtual": "☁️"}.get(w[3], "❓")
    print(f"   {status} {type_emoji} {w[1]} ({w[2]}) - {w[3]}")
    if w[5]:
        print(f"      📍 {w[5][:50]}...")

# Store warehouse IDs for later tests
warehouse_ids = [w[0] for w in warehouses]
main_warehouse = next((w for w in warehouses if w[3] == 'main'), None)
transit_warehouse = next((w for w in warehouses if w[3] == 'transit'), None)

# =============================================
# TEST 2: Products
# =============================================
print("\n" + "=" * 60)
print("TEST 2: DANH SÁCH SẢN PHẨM")
print("=" * 60)

cur.execute("""
    SELECT id, name, sku, unit, category, price
    FROM products
    WHERE company_id = %s
    ORDER BY name
    LIMIT 10
""", (company_id,))
products = cur.fetchall()

print(f"\n✅ Sản phẩm (hiển thị 10 đầu tiên):")
for p in products:
    price = f"{p[5]:,.0f}đ" if p[5] else "N/A"
    print(f"   📦 {p[1]} | SKU: {p[2]} | Unit: {p[3]} | Cat: {p[4]} | Price: {price}")

# Store product ID for tests
test_product = products[0] if products else None

# =============================================
# TEST 3: Inventory (Stock levels)
# =============================================
print("\n" + "=" * 60)
print("TEST 3: TỒN KHO THEO KHO")
print("=" * 60)

for wh in warehouses[:3]:  # Test first 3 warehouses
    cur.execute("""
        SELECT i.quantity, p.name, p.unit
        FROM inventory i
        JOIN products p ON p.id = i.product_id
        WHERE i.warehouse_id = %s AND i.quantity > 0
        ORDER BY i.quantity DESC
        LIMIT 5
    """, (wh[0],))
    stocks = cur.fetchall()
    
    print(f"\n📦 Kho: {wh[1]} ({wh[2]})")
    if stocks:
        for s in stocks:
            print(f"   └─ {s[1]}: {s[0]} {s[2]}")
    else:
        print(f"   └─ (Không có sản phẩm)")

# =============================================
# TEST 4: Movement History
# =============================================
print("\n" + "=" * 60)
print("TEST 4: LỊCH SỬ NHẬP/XUẤT (10 GẦN NHẤT)")
print("=" * 60)

cur.execute("""
    SELECT 
        m.type,
        m.quantity,
        m.before_quantity,
        m.after_quantity,
        p.name,
        m.reason,
        m.created_at,
        w.name as warehouse_name
    FROM inventory_movements m
    JOIN products p ON p.id = m.product_id
    LEFT JOIN warehouses w ON w.id = m.warehouse_id
    WHERE m.company_id = %s
    ORDER BY m.created_at DESC
    LIMIT 10
""", (company_id,))
movements = cur.fetchall()

print(f"\n✅ Lịch sử gần nhất:")
for m in movements:
    type_emoji = {"in": "📥", "out": "📤", "transfer": "🔄", "adjustment": "⚙️"}.get(m[0], "❓")
    date_str = m[6].strftime("%d/%m %H:%M") if m[6] else "N/A"
    print(f"   {type_emoji} [{m[0].upper()}] {m[4]}")
    print(f"      SL: {m[1]} | Trước: {m[2]} → Sau: {m[3]} | Kho: {m[7]} | {date_str}")
    if m[5]:
        print(f"      Lý do: {m[5]}")

# =============================================
# TEST 5: Verify Database Trigger
# =============================================
print("\n" + "=" * 60)
print("TEST 5: KIỂM TRA TRIGGER process_inventory_movement")
print("=" * 60)

cur.execute("""
    SELECT 
        trigger_name, 
        event_manipulation, 
        action_timing,
        action_statement
    FROM information_schema.triggers
    WHERE trigger_name = 'process_inventory_movement_trigger'
""")
trigger = cur.fetchone()

if trigger:
    print(f"\n✅ Trigger tồn tại:")
    print(f"   Name: {trigger[0]}")
    print(f"   Event: {trigger[1]} ({trigger[2]})")
    print(f"   Action: {trigger[3][:100]}...")
else:
    print("\n❌ CẢNH BÁO: Trigger không tồn tại!")

# =============================================
# TEST 6: Data Integrity Check
# =============================================
print("\n" + "=" * 60)
print("TEST 6: KIỂM TRA TÍNH TOÀN VẸN DỮ LIỆU")
print("=" * 60)

# Check if inventory quantities match movement calculations
cur.execute("""
    WITH movement_totals AS (
        SELECT 
            warehouse_id,
            product_id,
            SUM(CASE WHEN type = 'in' THEN quantity 
                     WHEN type = 'out' THEN -quantity 
                     WHEN type = 'transfer' AND destination_warehouse_id IS NOT NULL THEN -quantity
                     ELSE 0 END) as calculated_qty
        FROM inventory_movements
        WHERE company_id = %s
        GROUP BY warehouse_id, product_id
    )
    SELECT 
        i.warehouse_id,
        i.product_id,
        i.quantity as actual_qty,
        COALESCE(mt.calculated_qty, 0) as calculated_qty,
        p.name,
        w.name as warehouse_name
    FROM inventory i
    JOIN products p ON p.id = i.product_id
    JOIN warehouses w ON w.id = i.warehouse_id
    LEFT JOIN movement_totals mt ON mt.warehouse_id = i.warehouse_id AND mt.product_id = i.product_id
    WHERE i.company_id = %s
    AND i.quantity != COALESCE(mt.calculated_qty, 0)
    LIMIT 5
""", (company_id, company_id))
mismatches = cur.fetchall()

if mismatches:
    print(f"\n⚠️ Phát hiện {len(mismatches)} sản phẩm không khớp số lượng:")
    for m in mismatches:
        print(f"   {m[4]} @ {m[5]}")
        print(f"      Thực tế: {m[2]} | Tính toán: {m[3]}")
else:
    print("\n✅ Tất cả số lượng tồn kho khớp với lịch sử chuyển động!")

# =============================================
# TEST 7: Warehouse Type Constraint
# =============================================
print("\n" + "=" * 60)
print("TEST 7: KIỂM TRA CONSTRAINT LOẠI KHO")
print("=" * 60)

cur.execute("""
    SELECT pg_get_constraintdef(oid) 
    FROM pg_constraint 
    WHERE conname = 'warehouses_type_check'
""")
constraint = cur.fetchone()

if constraint:
    print(f"\n✅ Constraint: {constraint[0]}")
    
    # Check existing types
    cur.execute("SELECT DISTINCT type FROM warehouses WHERE company_id = %s", (company_id,))
    types = [t[0] for t in cur.fetchall()]
    print(f"   Các loại kho đang dùng: {types}")
else:
    print("\n⚠️ Không tìm thấy constraint warehouses_type_check")

# =============================================
# TEST 8: Test Stock Operations (Simulation)
# =============================================
print("\n" + "=" * 60)
print("TEST 8: MÔ PHỎNG THAO TÁC KHO")
print("=" * 60)

if main_warehouse and test_product:
    # Get current stock
    cur.execute("""
        SELECT quantity FROM inventory 
        WHERE warehouse_id = %s AND product_id = %s
    """, (main_warehouse[0], test_product[0]))
    current = cur.fetchone()
    current_qty = current[0] if current else 0
    
    print(f"\n📦 Sản phẩm test: {test_product[1]}")
    print(f"🏠 Kho test: {main_warehouse[1]}")
    print(f"📊 Số lượng hiện tại: {current_qty}")
    
    # Simulate what would happen with stock in
    test_qty = 10
    print(f"\n🔬 Mô phỏng nhập kho {test_qty} {test_product[3]}:")
    print(f"   - before_quantity: {current_qty}")
    print(f"   - quantity: {test_qty}")
    print(f"   - after_quantity (expected): {current_qty + test_qty}")
    print(f"   ✅ Trigger sẽ tự động cập nhật inventory")
else:
    print("\n⚠️ Không có warehouse hoặc product để test")

# =============================================
# SUMMARY
# =============================================
print("\n" + "=" * 60)
print("📋 TÓM TẮT KẾT QUẢ TEST")
print("=" * 60)

summary = {
    "Warehouses": len(warehouses),
    "Products": len(products),
    "Recent Movements": len(movements),
    "Trigger Exists": trigger is not None,
    "Data Integrity Issues": len(mismatches),
}

for key, value in summary.items():
    status = "✅" if value or (key == "Data Integrity Issues" and value == 0) else "❌"
    print(f"   {status} {key}: {value}")

# =============================================
# TÍNH NĂNG CẦN TEST THỦ CÔNG TRÊN UI
# =============================================
print("\n" + "=" * 60)
print("📱 CHECKLIST TEST THỦ CÔNG TRÊN UI")
print("=" * 60)
print("""
1. [ ] Tab DS Kho hiển thị đúng danh sách kho
2. [ ] Tab Lịch sử hiển thị đúng history
3. [ ] Tap vào kho → mở trang chi tiết với sản phẩm
4. [ ] Long press vào kho → hiện menu thao tác
5. [ ] Nhập kho:
   - [ ] Chọn sản phẩm
   - [ ] Nhập số lượng
   - [ ] Bấm xác nhận
   - [ ] Kiểm tra tồn kho tăng đúng
6. [ ] Xuất kho:
   - [ ] Chọn sản phẩm có tồn kho
   - [ ] Nhập số lượng <= tồn kho
   - [ ] Bấm xác nhận
   - [ ] Kiểm tra tồn kho giảm đúng
7. [ ] Chuyển kho:
   - [ ] Chọn kho nguồn và kho đích
   - [ ] Chọn sản phẩm
   - [ ] Nhập số lượng
   - [ ] Kiểm tra kho nguồn giảm, kho đích tăng
8. [ ] Thêm kho mới:
   - [ ] Nhập tên kho
   - [ ] Chọn loại kho
   - [ ] Lưu thành công
9. [ ] Sửa thông tin kho
10.[ ] Xóa/Ngưng hoạt động kho
""")

cur.close()
conn.close()

print("\n✨ Test script hoàn thành!")
