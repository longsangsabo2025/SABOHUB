"""
Check inventory_movements table schema and warehouse relationship
"""
import psycopg2
from psycopg2.extras import RealDictCursor

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("CHECKING INVENTORY_MOVEMENTS TABLE")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print("✓ Connected\n")

    # 1. Check schema
    print("1. INVENTORY_MOVEMENTS SCHEMA:")
    cur.execute("""
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'inventory_movements'
        ORDER BY ordinal_position
    """)
    cols = cur.fetchall()
    has_warehouse = False
    for col in cols:
        nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
        default = f" DEFAULT {col['column_default']}" if col['column_default'] else ""
        print(f"   - {col['column_name']:25} {col['data_type']:20} {nullable}{default}")
        if 'warehouse' in col['column_name'].lower():
            has_warehouse = True
    
    if not has_warehouse:
        print("\n   ❌ NO WAREHOUSE_ID COLUMN!")
    
    # 2. Check sample data
    print("\n2. SAMPLE MOVEMENTS:")
    cur.execute("""
        SELECT id, product_id, quantity, movement_type, created_at
        FROM inventory_movements
        ORDER BY created_at DESC
        LIMIT 5
    """)
    movements = cur.fetchall()
    print(f"   Total movements: ", end="")
    cur.execute("SELECT COUNT(*) FROM inventory_movements")
    total = cur.fetchone()['count']
    print(total)
    
    if movements:
        for m in movements:
            print(f"   - {m['movement_type']}: Product {m['product_id']}, Qty {m['quantity']}")
    else:
        print("   No movements found")
    
    # 3. Count by warehouse (if column exists)
    if has_warehouse:
        print("\n3. MOVEMENTS BY WAREHOUSE:")
        cur.execute("""
            SELECT 
                w.id,
                w.name,
                COUNT(im.id) as movement_count
            FROM warehouses w
            LEFT JOIN inventory_movements im ON w.id = im.warehouse_id
            GROUP BY w.id, w.name
            ORDER BY w.name
        """)
        by_warehouse = cur.fetchall()
        for wh in by_warehouse:
            print(f"   - {wh['name']}: {wh['movement_count']} movements")

    print("\n" + "=" * 70)
    print("ISSUE IDENTIFIED:")
    print("=" * 70)
    
    if not has_warehouse:
        print("\n❌ inventory_movements table is MISSING warehouse_id column!")
        print("\n   This means:")
        print("   1. All movements are global (not per-warehouse)")
        print("   2. Cannot filter history by warehouse")
        print("   3. Cannot track which warehouse has which stock")
        print("\n   SOLUTION:")
        print("   1. Add warehouse_id UUID column to inventory_movements")
        print("   2. Add foreign key to warehouses table")
        print("   3. Update existing movements to assign to primary warehouse")
        print("   4. Make warehouse_id NOT NULL")
    else:
        print("\n✅ warehouse_id column exists")

    print("\n" + "=" * 70)

except Exception as e:
    print(f"❌ Error: {e}")
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\n✓ Connection closed")
