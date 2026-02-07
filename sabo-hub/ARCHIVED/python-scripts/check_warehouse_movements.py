"""
Check inventory movements per warehouse and create test data if needed
"""
import psycopg2
from psycopg2.extras import RealDictCursor

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("CHECKING INVENTORY MOVEMENTS PER WAREHOUSE")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print("✓ Connected\n")

    # 1. Get all warehouses
    print("1. WAREHOUSES:")
    cur.execute("""
        SELECT id, name, code, is_primary, type
        FROM warehouses
        ORDER BY is_primary DESC, name
    """)
    warehouses = cur.fetchall()
    for wh in warehouses:
        primary = " [PRIMARY]" if wh['is_primary'] else ""
        print(f"   - {wh['name']}{primary} ({wh['code']})")
        print(f"     ID: {wh['id']}")
    
    # 2. Count movements per warehouse
    print("\n2. MOVEMENTS BY WAREHOUSE:")
    for wh in warehouses:
        cur.execute("""
            SELECT COUNT(*) as count
            FROM inventory_movements
            WHERE warehouse_id = %s
        """, (wh['id'],))
        count = cur.fetchone()['count']
        
        primary = " [PRIMARY]" if wh['is_primary'] else ""
        print(f"   - {wh['name']}{primary}: {count} movements")
        
        if count > 0:
            # Show recent movements
            cur.execute("""
                SELECT im.id, im.type, im.quantity, p.name as product_name, im.created_at
                FROM inventory_movements im
                LEFT JOIN products p ON im.product_id = p.id
                WHERE im.warehouse_id = %s
                ORDER BY im.created_at DESC
                LIMIT 3
            """, (wh['id'],))
            recent = cur.fetchall()
            for mov in recent:
                print(f"     • {mov['type']}: {mov['product_name']} x{mov['quantity']}")
    
    # 3. Check warehouse_inventory (current stock)
    print("\n3. CURRENT STOCK BY WAREHOUSE:")
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND (table_name = 'warehouse_inventory' OR table_name = 'inventory')
    """)
    inv_table = cur.fetchone()
    
    if inv_table:
        table_name = inv_table['table_name']
        print(f"   Using table: {table_name}")
        
        for wh in warehouses:
            cur.execute(f"""
                SELECT COUNT(*) as product_count,
                       COALESCE(SUM(quantity), 0) as total_quantity
                FROM {table_name}
                WHERE warehouse_id = %s
            """, (wh['id'],))
            stock = cur.fetchone()
            
            primary = " [PRIMARY]" if wh['is_primary'] else ""
            print(f"   - {wh['name']}{primary}:")
            print(f"     Products: {stock['product_count']}")
            print(f"     Total qty: {stock['total_quantity']}")
    else:
        print("   ⚠️  No warehouse_inventory or inventory table found")
    
    print("\n" + "=" * 70)
    print("DIAGNOSIS:")
    print("=" * 70)
    
    # Find warehouses with no data
    empty_warehouses = [wh for wh in warehouses if not any([
        cur.execute("SELECT COUNT(*) FROM inventory_movements WHERE warehouse_id = %s", (wh['id'],)),
        cur.fetchone()['count'] > 0
    ])]
    
    if empty_warehouses:
        print("\n❌ WAREHOUSES WITH NO MOVEMENT HISTORY:")
        for wh in empty_warehouses:
            print(f"   - {wh['name']} ({wh['code']})")
        
        print("\n   REASON:")
        print("   → These warehouses were created but never had any inventory movements")
        print("   → The 'Lịch sử' tab shows empty because there's no data to display")
        
        print("\n   SOLUTION:")
        print("   1. When creating a new warehouse, ensure it gets initial stock")
        print("   2. Use 'Nhập kho' or 'Chuyển kho' to add products to secondary warehouses")
        print("   3. For testing, can manually create stock-in movements")
    else:
        print("\n✅ All warehouses have movement history")

    print("\n" + "=" * 70)

except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\n✓ Connection closed")
