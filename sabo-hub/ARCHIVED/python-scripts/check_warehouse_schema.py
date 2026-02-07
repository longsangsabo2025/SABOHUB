"""
Check warehouse schema and sales_orders warehouse_id column
Uses Transaction Pooler for reliable connection
"""
import psycopg2
from psycopg2.extras import RealDictCursor

# Transaction pooler connection
DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("CHECKING WAREHOUSE SCHEMA")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print("✓ Connected to Supabase via Transaction Pooler\n")

    # 1. Check warehouses table structure
    print("1. WAREHOUSES TABLE SCHEMA:")
    cur.execute("""
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'warehouses' 
        ORDER BY ordinal_position
    """)
    warehouse_cols = cur.fetchall()
    if warehouse_cols:
        print("   Columns:")
        for col in warehouse_cols:
            nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
            default = f" DEFAULT {col['column_default']}" if col['column_default'] else ""
            print(f"   - {col['column_name']:20} {col['data_type']:20} {nullable}{default}")
    else:
        print("   ⚠️  Table 'warehouses' not found!")

    # 2. Check sales_orders has warehouse_id column
    print("\n2. SALES_ORDERS TABLE - warehouse_id column:")
    cur.execute("""
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales_orders' AND column_name = 'warehouse_id'
    """)
    warehouse_id_col = cur.fetchone()
    if warehouse_id_col:
        nullable = "NULL" if warehouse_id_col['is_nullable'] == 'YES' else "NOT NULL"
        default = f" DEFAULT {warehouse_id_col['column_default']}" if warehouse_id_col['column_default'] else ""
        print(f"   ✓ Column exists: {warehouse_id_col['data_type']} {nullable}{default}")
    else:
        print("   ❌ Column 'warehouse_id' does NOT exist in sales_orders!")

    # 3. Check foreign key constraint
    print("\n3. FOREIGN KEY CONSTRAINT:")
    cur.execute("""
        SELECT
            tc.constraint_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_name = 'sales_orders'
            AND kcu.column_name = 'warehouse_id'
    """)
    fk = cur.fetchone()
    if fk:
        print(f"   ✓ Foreign key exists: {fk['constraint_name']}")
        print(f"     sales_orders.{fk['column_name']} -> {fk['foreign_table_name']}.{fk['foreign_column_name']}")
    else:
        print("   ⚠️  No foreign key constraint found for warehouse_id")

    # 4. Check if warehouse_id has any NULL values
    print("\n4. CHECKING WAREHOUSE_ID DATA:")
    cur.execute("""
        SELECT 
            COUNT(*) as total_orders,
            COUNT(warehouse_id) as orders_with_warehouse,
            COUNT(*) - COUNT(warehouse_id) as orders_without_warehouse
        FROM sales_orders
    """)
    stats = cur.fetchone()
    if stats:
        print(f"   Total orders: {stats['total_orders']}")
        print(f"   Orders with warehouse: {stats['orders_with_warehouse']}")
        print(f"   Orders without warehouse: {stats['orders_without_warehouse']}")
        if stats['orders_without_warehouse'] > 0:
            print(f"   ⚠️  {stats['orders_without_warehouse']} orders have NULL warehouse_id!")
        else:
            print("   ✓ All orders have warehouse assigned")

    # 5. Check primary warehouse
    print("\n5. PRIMARY WAREHOUSE:")
    cur.execute("""
        SELECT id, name, is_primary, address, company_id
        FROM warehouses
        WHERE is_primary = true
    """)
    primary_warehouses = cur.fetchall()
    if primary_warehouses:
        print(f"   ✓ Found {len(primary_warehouses)} primary warehouse(s):")
        for w in primary_warehouses:
            print(f"   - ID: {w['id']}")
            print(f"     Name: {w['name']}")
            print(f"     Address: {w['address']}")
            print(f"     Company ID: {w['company_id']}")
    else:
        print("   ⚠️  No primary warehouse found!")

    # 6. List all warehouses
    print("\n6. ALL WAREHOUSES:")
    cur.execute("""
        SELECT id, name, is_primary, address, company_id,
               (SELECT COUNT(*) FROM sales_orders WHERE warehouse_id = warehouses.id) as order_count
        FROM warehouses
        ORDER BY is_primary DESC, name
    """)
    all_warehouses = cur.fetchall()
    if all_warehouses:
        print(f"   Total: {len(all_warehouses)} warehouse(s)")
        for w in all_warehouses:
            primary_badge = " [PRIMARY]" if w['is_primary'] else ""
            print(f"\n   - {w['name']}{primary_badge}")
            print(f"     ID: {w['id']}")
            print(f"     Address: {w['address'] or 'N/A'}")
            print(f"     Company: {w['company_id']}")
            print(f"     Orders: {w['order_count']}")
    else:
        print("   ⚠️  No warehouses found!")

    # 7. Check indexes
    print("\n7. INDEXES ON WAREHOUSE_ID:")
    cur.execute("""
        SELECT 
            i.relname as index_name,
            a.attname as column_name,
            am.amname as index_type
        FROM pg_class t
        JOIN pg_index ix ON t.oid = ix.indrelid
        JOIN pg_class i ON i.oid = ix.indexrelid
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
        JOIN pg_am am ON i.relam = am.oid
        WHERE t.relname = 'sales_orders' 
        AND a.attname = 'warehouse_id'
    """)
    indexes = cur.fetchall()
    if indexes:
        print(f"   ✓ Found {len(indexes)} index(es):")
        for idx in indexes:
            print(f"   - {idx['index_name']} ({idx['index_type']})")
    else:
        print("   ⚠️  No indexes found on warehouse_id")

    # 8. Sample orders with warehouse info
    print("\n8. SAMPLE ORDERS WITH WAREHOUSE:")
    cur.execute("""
        SELECT 
            so.id,
            so.order_number,
            so.warehouse_id,
            w.name as warehouse_name,
            so.status,
            so.created_at
        FROM sales_orders so
        LEFT JOIN warehouses w ON so.warehouse_id = w.id
        ORDER BY so.created_at DESC
        LIMIT 5
    """)
    sample_orders = cur.fetchall()
    if sample_orders:
        for order in sample_orders:
            wh_name = order['warehouse_name'] or 'NULL'
            print(f"   - Order #{order['order_number'] or order['id'][:8]}: {wh_name} ({order['status']})")
    else:
        print("   No orders found")

    print("\n" + "=" * 70)
    print("RECOMMENDATIONS:")
    print("=" * 70)

    recommendations = []

    # Check if warehouse_id column exists
    if not warehouse_id_col:
        recommendations.append("❌ CRITICAL: Add warehouse_id column to sales_orders")
        recommendations.append("   SQL: ALTER TABLE sales_orders ADD COLUMN warehouse_id UUID;")
    
    # Check if FK exists
    if warehouse_id_col and not fk:
        recommendations.append("⚠️  Add foreign key constraint:")
        recommendations.append("   SQL: ALTER TABLE sales_orders ADD CONSTRAINT fk_sales_orders_warehouse")
        recommendations.append("        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id);")
    
    # Check for primary warehouse
    if not primary_warehouses:
        recommendations.append("⚠️  Set one warehouse as primary:")
        recommendations.append("   SQL: UPDATE warehouses SET is_primary = true WHERE id = '<warehouse_id>';")
    elif len(primary_warehouses) > 1:
        recommendations.append("⚠️  Multiple primary warehouses found! Should only have one.")
        recommendations.append("   SQL: UPDATE warehouses SET is_primary = false WHERE id != '<keep_this_id>';")
    
    # Check for NULL warehouse_id values
    if stats and stats['orders_without_warehouse'] > 0:
        recommendations.append(f"⚠️  {stats['orders_without_warehouse']} orders have NULL warehouse_id")
        recommendations.append("   SQL: UPDATE sales_orders SET warehouse_id = (SELECT id FROM warehouses WHERE is_primary = true LIMIT 1)")
        recommendations.append("        WHERE warehouse_id IS NULL;")
    
    # Check for indexes
    if not indexes and warehouse_id_col:
        recommendations.append("💡 Consider adding index for better query performance:")
        recommendations.append("   SQL: CREATE INDEX idx_sales_orders_warehouse_id ON sales_orders(warehouse_id);")
    
    # Recommend making it NOT NULL after fixing data
    if warehouse_id_col and warehouse_id_col['is_nullable'] == 'YES' and stats and stats['orders_without_warehouse'] == 0:
        recommendations.append("💡 Consider making warehouse_id NOT NULL (after ensuring all orders have warehouse):")
        recommendations.append("   SQL: ALTER TABLE sales_orders ALTER COLUMN warehouse_id SET NOT NULL;")

    if recommendations:
        for i, rec in enumerate(recommendations, 1):
            print(f"\n{rec}")
    else:
        print("\n✅ All checks passed! Schema looks good.")

    print("\n" + "=" * 70)

except psycopg2.Error as e:
    print(f"❌ Database error: {e}")
except Exception as e:
    print(f"❌ Error: {e}")
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\n✓ Connection closed")
