"""
Make warehouse_id NOT NULL in sales_orders table
Uses Transaction Pooler
"""
import psycopg2

# Transaction pooler connection
DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("MAKING WAREHOUSE_ID NOT NULL")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    cur = conn.cursor()
    print("✓ Connected to Supabase via Transaction Pooler\n")

    # Step 1: Final check - ensure no NULL values
    print("1. Checking for NULL warehouse_id values...")
    cur.execute("""
        SELECT COUNT(*) 
        FROM sales_orders 
        WHERE warehouse_id IS NULL
    """)
    null_count = cur.fetchone()[0]
    
    if null_count > 0:
        print(f"   ❌ Found {null_count} orders with NULL warehouse_id!")
        print("   ⚠️  Cannot proceed. Please run add_warehouse_features.py first.")
        conn.rollback()
        exit(1)
    else:
        print("   ✓ No NULL values found")

    # Step 2: Make warehouse_id NOT NULL
    print("\n2. Setting warehouse_id column to NOT NULL...")
    cur.execute("""
        ALTER TABLE sales_orders 
        ALTER COLUMN warehouse_id SET NOT NULL
    """)
    print("   ✓ Column constraint updated")

    # Step 3: Verify constraint
    print("\n3. Verifying constraint...")
    cur.execute("""
        SELECT column_name, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'sales_orders' AND column_name = 'warehouse_id'
    """)
    result = cur.fetchone()
    
    if result and result[1] == 'NO':
        print("   ✓ Constraint verified: warehouse_id is now NOT NULL")
    else:
        print("   ⚠️  Verification failed")
        conn.rollback()
        exit(1)

    # Commit transaction
    conn.commit()
    print("\n" + "=" * 70)
    print("✅ WAREHOUSE_ID IS NOW REQUIRED FOR ALL ORDERS")
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
