"""
Fix Inventory Data - Consolidate all stock to Main Warehouse (Tổng kho Q12)

Logic nghiệp vụ:
- Tổng kho Q12 (type='main') = Kho chính, chứa tất cả hàng
- Các kho phụ (type='branch'/'transit') = Nhận hàng từ Tổng kho qua chuyển kho, hiện tại = 0
"""

import os
from dotenv import load_dotenv
from supabase import create_client

# Load from .env.local
load_dotenv('.env.local')

SUPABASE_URL = os.getenv("VITE_SUPABASE_URL")
SUPABASE_KEY = os.getenv("VITE_SUPABASE_SERVICE_ROLE_KEY") or os.getenv("VITE_SUPABASE_ANON_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def fix_inventory():
    print("=" * 70)
    print("🔧 FIX INVENTORY - GOM TỒN KHO VỀ TỔNG KHO Q12")
    print("=" * 70)
    
    # 1. Find main warehouse (Tổng kho Q12)
    print("\n📦 Tìm kho chính (type='main')...")
    warehouses = supabase.from_("warehouses").select("*").execute()
    
    main_warehouse = None
    other_warehouses = []
    
    for wh in warehouses.data:
        print(f"  - {wh['name']} (Type: {wh.get('type', 'N/A')}, ID: {wh['id'][:8]}...)")
        if wh.get('type') == 'main':
            main_warehouse = wh
        else:
            other_warehouses.append(wh)
    
    if not main_warehouse:
        print("❌ Không tìm thấy kho chính (type='main')!")
        return
    
    print(f"\n✅ Kho chính: {main_warehouse['name']} (ID: {main_warehouse['id']})")
    print(f"📋 Số kho phụ cần xử lý: {len(other_warehouses)}")
    
    # 2. Get all inventory records
    print("\n📊 Đang phân tích tồn kho...")
    inventory = supabase.from_("inventory").select(
        "*, products(id, name, sku)"
    ).execute()
    
    # Group by product
    product_totals = {}  # product_id -> total quantity
    main_warehouse_inventory = {}  # product_id -> inventory record id in main warehouse
    records_to_delete = []  # inventory IDs to delete (from other warehouses)
    
    for item in inventory.data:
        product_id = item.get('product_id')
        warehouse_id = item.get('warehouse_id')
        quantity = item.get('quantity', 0)
        product = item.get('products') or {}
        product_name = product.get('name', 'Unknown')
        
        # Track total per product
        if product_id not in product_totals:
            product_totals[product_id] = {
                'name': product_name,
                'total': 0,
                'by_warehouse': []
            }
        
        product_totals[product_id]['total'] += quantity
        product_totals[product_id]['by_warehouse'].append({
            'warehouse_id': warehouse_id,
            'quantity': quantity,
            'inventory_id': item['id']
        })
        
        # Track main warehouse records
        if warehouse_id == main_warehouse['id']:
            main_warehouse_inventory[product_id] = item['id']
        else:
            # Record from other warehouse - mark for deletion
            if quantity > 0:
                records_to_delete.append({
                    'id': item['id'],
                    'product_name': product_name,
                    'quantity': quantity,
                    'warehouse_id': warehouse_id
                })
    
    # 3. Show analysis
    print("\n" + "=" * 70)
    print("📊 PHÂN TÍCH TỒN KHO THEO SẢN PHẨM:")
    print("=" * 70)
    
    for product_id, data in product_totals.items():
        if len(data['by_warehouse']) > 1:
            print(f"\n⚠️  {data['name']}")
            for wh_data in data['by_warehouse']:
                wh_name = "Tổng kho Q12" if wh_data['warehouse_id'] == main_warehouse['id'] else "Kho phụ"
                print(f"    → {wh_name}: {wh_data['quantity']} units")
            print(f"    📊 TỔNG: {data['total']} units → Gom về Tổng kho Q12")
    
    # 4. Confirm and fix
    print("\n" + "=" * 70)
    print("🔧 HÀNH ĐỘNG SẼ THỰC HIỆN:")
    print("=" * 70)
    print(f"  1. Cập nhật tồn kho tại Tổng kho Q12 = TỔNG tất cả kho")
    print(f"  2. Xóa {len(records_to_delete)} records ở các kho phụ")
    
    if not records_to_delete and all(len(d['by_warehouse']) == 1 for d in product_totals.values()):
        print("\n✅ Dữ liệu đã đúng! Không cần sửa.")
        return
    
    # Auto confirm for script execution
    confirm = 'y'  # Auto confirm
    print("\n🚀 Tự động xác nhận thực hiện...")
    if confirm != 'y':
        print("❌ Đã hủy.")
        return
    
    # 5. Execute fixes
    print("\n🔄 Đang thực hiện...")
    
    # Update main warehouse inventory with totals
    for product_id, data in product_totals.items():
        total_qty = data['total']
        
        if product_id in main_warehouse_inventory:
            # Update existing record in main warehouse
            supabase.from_("inventory").update({
                'quantity': total_qty
            }).eq('id', main_warehouse_inventory[product_id]).execute()
            print(f"  ✅ Cập nhật {data['name']}: {total_qty} units → Tổng kho Q12")
        else:
            # Create new record in main warehouse
            # Get company_id from any existing record
            company_id = inventory.data[0].get('company_id') if inventory.data else None
            if company_id:
                supabase.from_("inventory").insert({
                    'company_id': company_id,
                    'warehouse_id': main_warehouse['id'],
                    'product_id': product_id,
                    'quantity': total_qty
                }).execute()
                print(f"  ✅ Tạo mới {data['name']}: {total_qty} units → Tổng kho Q12")
    
    # Delete records from other warehouses
    for record in records_to_delete:
        supabase.from_("inventory").delete().eq('id', record['id']).execute()
        print(f"  🗑️  Xóa {record['product_name']} ({record['quantity']} units) khỏi kho phụ")
    
    print("\n" + "=" * 70)
    print("✅ HOÀN THÀNH!")
    print("=" * 70)
    print("Tất cả tồn kho đã được gom về Tổng kho Q12.")
    print("Các kho phụ hiện có tồn kho = 0, sẵn sàng nhận hàng từ Tổng kho.")

if __name__ == "__main__":
    fix_inventory()
