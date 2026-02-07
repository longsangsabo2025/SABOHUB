"""
Check inventory transactions table and warehouse relationship
Uses Transaction Pooler
"""
import psycopg2
from psycopg2.extras import RealDictCursor

# Transaction pooler connection
DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("CHECKING INVENTORY TRANSACTIONS")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print("✓ Connected\n")

    # 1. Check if inventory_transactions table exists
    print("1. CHECKING INVENTORY TABLES:")
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name LIKE '%inventory%'
        ORDER BY table_name
    """)
    tables = cur.fetchall()
    if tables:
        print("   Found tables:")
        for t in tables:
            print(f"   - {t['table_name']}")
    else:
        print("   ⚠️  No inventory tables found!")

    # 2. Check inventory_transactions schema if exists
    cur.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'inventory_transactions'
        ORDER BY ordinal_position
    """)
    cols = cur.fetchall()
    if cols:
        print("\n2. INVENTORY_TRANSACTIONS SCHEMA:")
        has_warehouse = False
        for col in cols:
            nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
            print(f"   - {col['column_name']:25} {col['data_type']:20} {nullable}")
            if 'warehouse' in col['column_name'].lower():
                has_warehouse = True
        
        if not has_warehouse:
            print("\n   ⚠️  NO WAREHOUSE COLUMN FOUND!")
    
    # 3. Check sample transactions
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'inventory_transactions'
    """)
    if cur.fetchone():
        print("\n3. SAMPLE TRANSACTIONS:")
        cur.execute("""
            SELECT id, product_id, quantity, transaction_type, created_at
            FROM inventory_transactions
            ORDER BY created_at DESC
            LIMIT 5
        """)
        transactions = cur.fetchall()
        if transactions:
            for t in transactions:
                print(f"   - {t['transaction_type']}: Product {t['product_id']}, Qty {t['quantity']}")
        else:
            print("   No transactions found")

    # 4. Check warehouses table for inventory columns
    print("\n4. WAREHOUSES INVENTORY COLUMNS:")
    cur.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'warehouses'
        AND column_name LIKE '%inventory%'
    """)
    wh_inv_cols = cur.fetchall()
    if wh_inv_cols:
        for col in wh_inv_cols:
            print(f"   - {col['column_name']}: {col['data_type']}")
    else:
        print("   No inventory columns in warehouses table")

    # 5. Check for warehouse_inventory or similar junction table
    print("\n5. CHECKING WAREHOUSE-PRODUCT INVENTORY TABLE:")
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND (table_name LIKE '%warehouse%inventory%' 
             OR table_name LIKE '%stock%'
             OR table_name LIKE '%inventory%warehouse%')
        ORDER BY table_name
    """)
    junction_tables = cur.fetchall()
    if junction_tables:
        print("   Found tables:")
        for t in junction_tables:
            print(f"   - {t['table_name']}")
            
            # Get schema of first matching table
            cur.execute(f"""
                SELECT column_name, data_type
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = '{t['table_name']}'
                ORDER BY ordinal_position
            """)
            schema_cols = cur.fetchall()
            for col in schema_cols:
                print(f"     • {col['column_name']}: {col['data_type']}")
    else:
        print("   ⚠️  No warehouse-inventory junction table found!")

    print("\n" + "=" * 70)
    print("RECOMMENDATIONS:")
    print("=" * 70)
    
    recommendations = []
    
    if not cols:
        recommendations.append("❌ CRITICAL: Create inventory_transactions table with warehouse_id")
    elif not has_warehouse:
        recommendations.append("❌ CRITICAL: Add warehouse_id column to inventory_transactions")
    
    if not junction_tables:
        recommendations.append("⚠️  Consider creating warehouse_inventory table:")
        recommendations.append("   (warehouse_id, product_id, quantity, reserved_quantity)")
    
    if recommendations:
        for rec in recommendations:
            print(f"\n{rec}")
    else:
        print("\n✅ Schema looks good")

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
