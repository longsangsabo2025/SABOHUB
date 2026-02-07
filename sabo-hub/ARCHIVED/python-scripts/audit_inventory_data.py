"""
Audit Inventory Data - Check for duplicate products in inventory
"""

import os
from dotenv import load_dotenv
from supabase import create_client

# Load from .env.local
load_dotenv('.env.local')

SUPABASE_URL = os.getenv("VITE_SUPABASE_URL")
SUPABASE_KEY = os.getenv("VITE_SUPABASE_SERVICE_ROLE_KEY") or os.getenv("VITE_SUPABASE_ANON_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def audit_inventory():
    print("=" * 70)
    print("🔍 INVENTORY DATA AUDIT")
    print("=" * 70)
    
    # 1. Get all inventory records with product and warehouse info
    print("\n📦 Loading all inventory records...")
    inventory = supabase.from_("inventory").select(
        "*, products(id, name, sku), warehouses(id, name, type)"
    ).execute()
    
    print(f"Total inventory records: {len(inventory.data)}")
    
    # 2. Check for products that appear in multiple warehouses
    product_warehouse_map = {}
    for item in inventory.data:
        product = item.get("products") or {}
        warehouse = item.get("warehouses") or {}
        
        product_id = item.get("product_id")
        product_name = product.get("name", "Unknown")
        product_sku = product.get("sku", "N/A")
        warehouse_id = item.get("warehouse_id")
        warehouse_name = warehouse.get("name", "Unknown warehouse")
        quantity = item.get("quantity", 0)
        
        key = f"{product_id}"
        if key not in product_warehouse_map:
            product_warehouse_map[key] = {
                "product_name": product_name,
                "product_sku": product_sku,
                "warehouses": []
            }
        product_warehouse_map[key]["warehouses"].append({
            "warehouse_id": warehouse_id,
            "warehouse_name": warehouse_name,
            "quantity": quantity
        })
    
    # 3. Find products in multiple warehouses
    print("\n" + "=" * 70)
    print("⚠️ PRODUCTS IN MULTIPLE WAREHOUSES (showing as duplicates in UI):")
    print("=" * 70)
    
    multi_warehouse_products = []
    for product_id, data in product_warehouse_map.items():
        if len(data["warehouses"]) > 1:
            multi_warehouse_products.append({
                "product_id": product_id,
                **data
            })
    
    if not multi_warehouse_products:
        print("✅ No products found in multiple warehouses")
    else:
        for product in multi_warehouse_products:
            print(f"\n📦 {product['product_name']} (SKU: {product['product_sku']})")
            print(f"   Product ID: {product['product_id']}")
            total_qty = 0
            for wh in product["warehouses"]:
                print(f"   → {wh['warehouse_name']}: {wh['quantity']} units")
                total_qty += wh['quantity']
            print(f"   📊 TOTAL ACROSS ALL WAREHOUSES: {total_qty}")
    
    # 4. Show all warehouses
    print("\n" + "=" * 70)
    print("🏭 ALL WAREHOUSES:")
    print("=" * 70)
    
    warehouses = supabase.from_("warehouses").select("*").execute()
    for wh in warehouses.data:
        print(f"  - {wh['name']} (Code: {wh.get('code', 'N/A')}, Type: {wh.get('type', 'N/A')})")
        print(f"    ID: {wh['id']}")
    
    # 5. Recent movements
    print("\n" + "=" * 70)
    print("📜 RECENT 10 INVENTORY MOVEMENTS:")
    print("=" * 70)
    
    movements = supabase.from_("inventory_movements").select(
        "*, products(name, sku), warehouses(name)"
    ).order("created_at", desc=True).limit(10).execute()
    
    for m in movements.data:
        product = m.get("products") or {}
        warehouse = m.get("warehouses") or {}
        m_type = m.get("type", "unknown")
        reason = m.get("reason", "")
        
        type_icon = "➕" if m_type == "in" else "➖" if m_type == "out" else "🔄"
        print(f"\n{type_icon} {m_type.upper()}: {product.get('name', 'Unknown')} ({product.get('sku', 'N/A')})")
        print(f"   Warehouse: {warehouse.get('name', 'Unknown')}")
        print(f"   Quantity: {m.get('quantity', 0)}")
        print(f"   Before: {m.get('before_quantity', '?')} → After: {m.get('after_quantity', '?')}")
        if reason:
            print(f"   Reason: {reason}")
        print(f"   Time: {m.get('created_at', 'N/A')}")
    
    print("\n" + "=" * 70)
    print("✅ AUDIT COMPLETE")
    print("=" * 70)

if __name__ == "__main__":
    audit_inventory()
