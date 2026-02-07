"""
Create retroactive inventory movements for existing stock in warehouses
This fixes the issue where stock exists but has no movement history
"""
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("CREATING RETROACTIVE INVENTORY MOVEMENTS")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print("✓ Connected\n")

    # 1. Find stock without corresponding movements
    print("1. FINDING STOCK WITHOUT MOVEMENT HISTORY...")
    cur.execute("""
        WITH stock_summary AS (
            SELECT 
                i.warehouse_id,
                i.product_id,
                i.quantity as current_quantity,
                i.company_id,
                w.name as warehouse_name,
                p.name as product_name
            FROM inventory i
            JOIN warehouses w ON i.warehouse_id = w.id
            JOIN products p ON i.product_id = p.id
            WHERE i.quantity > 0
        ),
        movement_summary AS (
            SELECT 
                warehouse_id,
                product_id,
                SUM(CASE 
                    WHEN type IN ('in', 'transfer-in') THEN quantity
                    WHEN type IN ('out', 'transfer-out') THEN -quantity
                    ELSE 0
                END) as net_movement
            FROM inventory_movements
            GROUP BY warehouse_id, product_id
        )
        SELECT 
            ss.warehouse_id,
            ss.product_id,
            ss.current_quantity,
            ss.company_id,
            ss.warehouse_name,
            ss.product_name,
            COALESCE(ms.net_movement, 0) as recorded_movement,
            ss.current_quantity - COALESCE(ms.net_movement, 0) as discrepancy
        FROM stock_summary ss
        LEFT JOIN movement_summary ms 
            ON ss.warehouse_id = ms.warehouse_id 
            AND ss.product_id = ms.product_id
        WHERE ss.current_quantity != COALESCE(ms.net_movement, 0)
        ORDER BY ss.warehouse_name, ss.product_name
    """)
    
    discrepancies = cur.fetchall()
    
    if not discrepancies:
        print("   ✅ No discrepancies found! All stock has corresponding movements.")
        conn.rollback()
        exit(0)
    
    print(f"   Found {len(discrepancies)} stock records without proper movement history:\n")
    
    for disc in discrepancies:
        print(f"   - {disc['warehouse_name']}: {disc['product_name']}")
        print(f"     Current stock: {disc['current_quantity']}")
        print(f"     Recorded movements: {disc['recorded_movement']}")
        print(f"     Discrepancy: {disc['discrepancy']}\n")
    
    # 2. Ask for confirmation
    print("\n" + "=" * 70)
    print("PROPOSED FIX:")
    print("=" * 70)
    print("\nCreate retroactive 'in' movements to match existing stock")
    print("This will:")
    print("  ✓ Add movement history for all existing stock")
    print("  ✓ Make the 'Lịch sử' tab show data for all warehouses")
    print("  ✓ Not change current stock quantities")
    print("\nProceed? (yes/no): ", end="")
    
    # Auto-yes for script execution
    response = "yes"
    print(response)
    
    if response.lower() != 'yes':
        print("\n❌ Operation cancelled")
        conn.rollback()
        exit(0)
    
    # 3. Create retroactive movements
    print("\n3. CREATING RETROACTIVE MOVEMENTS...")
    
    created_count = 0
    for disc in discrepancies:
        if disc['discrepancy'] > 0:  # Only create 'in' movements for positive discrepancies
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
                    'Retroactive movement created to match existing stock',
                    NOW() - INTERVAL '1 day'
                )
            """, (
                disc['company_id'],
                disc['warehouse_id'],
                disc['product_id'],
                disc['discrepancy'],
                disc['discrepancy']
            ))
            created_count += 1
            print(f"   ✓ Created 'in' movement: {disc['warehouse_name']} - {disc['product_name']} x{disc['discrepancy']}")
    
    # 4. Verify
    print(f"\n4. VERIFICATION:")
    print(f"   Created {created_count} retroactive movements")
    
    # Re-check discrepancies
    cur.execute("""
        WITH stock_summary AS (
            SELECT 
                i.warehouse_id,
                i.product_id,
                i.quantity as current_quantity
            FROM inventory i
            WHERE i.quantity > 0
        ),
        movement_summary AS (
            SELECT 
                warehouse_id,
                product_id,
                SUM(CASE 
                    WHEN type IN ('in', 'transfer-in') THEN quantity
                    WHEN type IN ('out', 'transfer-out') THEN -quantity
                    ELSE 0
                END) as net_movement
            FROM inventory_movements
            GROUP BY warehouse_id, product_id
        )
        SELECT COUNT(*) as remaining_discrepancies
        FROM stock_summary ss
        LEFT JOIN movement_summary ms 
            ON ss.warehouse_id = ms.warehouse_id 
            AND ss.product_id = ms.product_id
        WHERE ss.current_quantity != COALESCE(ms.net_movement, 0)
    """)
    
    remaining = cur.fetchone()['remaining_discrepancies']
    
    if remaining == 0:
        print("   ✅ All discrepancies resolved!")
        conn.commit()
        print("\n" + "=" * 70)
        print("✅ SUCCESS - MOVEMENTS CREATED AND COMMITTED")
        print("=" * 70)
    else:
        print(f"   ⚠️  {remaining} discrepancies remaining")
        print("   Rolling back...")
        conn.rollback()
        print("   ❌ Transaction rolled back")

except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    if conn:
        conn.rollback()
        print("⚠️  Transaction rolled back")
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\n✓ Connection closed")
