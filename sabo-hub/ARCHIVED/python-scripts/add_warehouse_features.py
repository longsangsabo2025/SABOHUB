"""
Add warehouse features: is_primary column and set default primary warehouse
Uses Transaction Pooler
"""
import psycopg2

# Transaction pooler connection
DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("ADDING WAREHOUSE FEATURES")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False  # Use transaction
    cur = conn.cursor()
    print("✓ Connected to Supabase via Transaction Pooler\n")

    # Step 1: Add is_primary column
    print("1. Adding is_primary column to warehouses table...")
    cur.execute("""
        DO $$ 
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'warehouses' AND column_name = 'is_primary'
            ) THEN
                ALTER TABLE warehouses ADD COLUMN is_primary BOOLEAN DEFAULT false;
                RAISE NOTICE 'Column is_primary added successfully';
            ELSE
                RAISE NOTICE 'Column is_primary already exists';
            END IF;
        END $$;
    """)
    print("   ✓ is_primary column ready")

    # Step 2: Check current warehouses
    print("\n2. Checking existing warehouses...")
    cur.execute("SELECT id, name, code, type FROM warehouses ORDER BY created_at")
    warehouses = cur.fetchall()
    
    if warehouses:
        print(f"   Found {len(warehouses)} warehouse(s):")
        for i, (wh_id, name, code, wh_type) in enumerate(warehouses, 1):
            type_str = f" (type: {wh_type})" if wh_type else ""
            print(f"   {i}. {name} [{code}]{type_str}")
            print(f"      ID: {wh_id}")
    else:
        print("   ⚠️  No warehouses found!")
        conn.rollback()
        exit(1)

    # Step 3: Set first warehouse as primary
    print("\n3. Setting primary warehouse...")
    
    # Check if any warehouse already marked as primary
    cur.execute("SELECT id, name FROM warehouses WHERE is_primary = true")
    primary = cur.fetchone()
    
    if primary:
        print(f"   ✓ Primary warehouse already set: {primary[1]}")
    else:
        # Set the first warehouse (usually the main one) as primary
        first_warehouse_id = warehouses[0][0]
        first_warehouse_name = warehouses[0][1]
        
        cur.execute("""
            UPDATE warehouses 
            SET is_primary = true 
            WHERE id = %s
        """, (first_warehouse_id,))
        
        print(f"   ✓ Set '{first_warehouse_name}' as primary warehouse")

    # Step 4: Update existing orders to use primary warehouse
    print("\n4. Updating existing orders with NULL warehouse_id...")
    
    cur.execute("""
        SELECT COUNT(*) 
        FROM sales_orders 
        WHERE warehouse_id IS NULL
    """)
    null_count = cur.fetchone()[0]
    
    if null_count > 0:
        cur.execute("""
            UPDATE sales_orders 
            SET warehouse_id = (SELECT id FROM warehouses WHERE is_primary = true LIMIT 1)
            WHERE warehouse_id IS NULL
        """)
        print(f"   ✓ Updated {null_count} order(s) to use primary warehouse")
    else:
        print("   ✓ All orders already have warehouse assigned")

    # Step 5: Add index on warehouse_id
    print("\n5. Adding index on sales_orders.warehouse_id...")
    cur.execute("""
        DO $$ 
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes 
                WHERE tablename = 'sales_orders' AND indexname = 'idx_sales_orders_warehouse_id'
            ) THEN
                CREATE INDEX idx_sales_orders_warehouse_id ON sales_orders(warehouse_id);
                RAISE NOTICE 'Index created successfully';
            ELSE
                RAISE NOTICE 'Index already exists';
            END IF;
        END $$;
    """)
    print("   ✓ Index ready")

    # Step 6: Verify changes
    print("\n6. Verifying changes...")
    cur.execute("""
        SELECT 
            w.id,
            w.name,
            w.is_primary,
            COUNT(so.id) as order_count
        FROM warehouses w
        LEFT JOIN sales_orders so ON w.id = so.warehouse_id
        GROUP BY w.id, w.name, w.is_primary
        ORDER BY w.is_primary DESC, w.name
    """)
    
    print("\n   Warehouse Status:")
    for wh_id, name, is_primary, order_count in cur.fetchall():
        primary_badge = " [PRIMARY]" if is_primary else ""
        print(f"   - {name}{primary_badge}")
        print(f"     Orders: {order_count}")

    # Commit transaction
    conn.commit()
    print("\n" + "=" * 70)
    print("✅ ALL CHANGES COMMITTED SUCCESSFULLY")
    print("=" * 70)

except psycopg2.Error as e:
    print(f"\n❌ Database error: {e}")
    if conn:
        conn.rollback()
        print("⚠️  All changes rolled back")
except Exception as e:
    print(f"\n❌ Error: {e}")
    if conn:
        conn.rollback()
        print("⚠️  All changes rolled back")
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\n✓ Connection closed")
