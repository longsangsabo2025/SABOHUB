"""
Create retroactive movements ONLY for Kho phụ 1 (secondary warehouse)
"""
import psycopg2
from psycopg2.extras import RealDictCursor

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("FIX KHO PHỤ 1 - CREATE MISSING MOVEMENTS")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print("✓ Connected\n")

    # 1. Get Kho phụ 1 ID
    cur.execute("""
        SELECT id, name, code 
        FROM warehouses 
        WHERE code = 'KHO435257' OR name = 'Kho phụ 1'
        LIMIT 1
    """)
    kho_phu = cur.fetchone()
    
    if not kho_phu:
        print("❌ Kho phụ 1 not found!")
        exit(1)
    
    print(f"1. TARGET WAREHOUSE:")
    print(f"   - {kho_phu['name']} ({kho_phu['code']})")
    print(f"   - ID: {kho_phu['id']}")
    
    # 2. Check current stock
    print(f"\n2. CURRENT STOCK IN KHO PHỤ 1:")
    cur.execute("""
        SELECT 
            i.*,
            p.name as product_name,
            p.sku
        FROM inventory i
        JOIN products p ON i.product_id = p.id
        WHERE i.warehouse_id = %s AND i.quantity > 0
        ORDER BY p.name
    """, (kho_phu['id'],))
    
    stocks = cur.fetchall()
    
    if not stocks:
        print("   No stock found")
        exit(0)
    
    for stock in stocks:
        print(f"   - {stock['product_name']} ({stock['sku']}): {stock['quantity']} units")
    
    # 3. Check existing movements
    print(f"\n3. EXISTING MOVEMENTS:")
    cur.execute("""
        SELECT COUNT(*) as count
        FROM inventory_movements
        WHERE warehouse_id = %s
    """, (kho_phu['id'],))
    
    mov_count = cur.fetchone()['count']
    print(f"   Total movements: {mov_count}")
    
    if mov_count > 0:
        print("   ✅ Movements already exist, no need to create retroactive ones")
        exit(0)
    
    # 4. Create initial stock movements
    print(f"\n4. CREATING INITIAL STOCK MOVEMENTS...")
    
    created = 0
    for stock in stocks:
        cur.execute("""
            INSERT INTO inventory_movements (
                company_id,
                warehouse_id,
                product_id,
                type,
                reason,
                quantity,
                before_quantity,
                after_quantity,
                notes,
                created_at
            ) VALUES (
                %s, %s, %s, 'in', 'initial_stock',
                %s, 0, %s,
                'Khởi tạo tồn kho ban đầu cho kho phụ',
                NOW() - INTERVAL '1 day'
            )
        """, (
            stock['company_id'],
            kho_phu['id'],
            stock['product_id'],
            stock['quantity'],
            stock['quantity']
        ))
        created += 1
        print(f"   ✓ {stock['product_name']}: +{stock['quantity']}")
    
    print(f"\n5. VERIFICATION:")
    cur.execute("""
        SELECT COUNT(*) as count
        FROM inventory_movements
        WHERE warehouse_id = %s
    """, (kho_phu['id'],))
    
    new_count = cur.fetchone()['count']
    print(f"   Movements after: {new_count}")
    print(f"   Created: {created} movements")
    
    if new_count == created:
        conn.commit()
        print("\n" + "=" * 70)
        print(f"✅ SUCCESS - KHO PHỤ 1 NOW HAS {created} MOVEMENT RECORDS")
        print("=" * 70)
        print("\nTab 'Lịch sử' will now show data for Kho phụ 1")
    else:
        conn.rollback()
        print("\n❌ Verification failed, rolled back")

except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    if conn:
        conn.rollback()
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\n✓ Connection closed")
