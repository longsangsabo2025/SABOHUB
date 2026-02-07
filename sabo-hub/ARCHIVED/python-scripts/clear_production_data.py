#!/usr/bin/env python3
"""
Clear all test data for production launch
WARNING: This will DELETE all data in inventory, orders, and related tables!
"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-nexus/.env')

POOLER_URL = os.getenv('VITE_SUPABASE_POOLER_URL')

if not POOLER_URL:
    print("❌ Error: VITE_SUPABASE_POOLER_URL not found in .env")
    exit(1)

# Tables to clear in order (respecting foreign key constraints)
TABLES_TO_CLEAR = [
    # Order-related (delete children first)
    'order_items',
    'sales_order_items', 
    'orders',
    'sales_orders',
    
    # Inventory movements first (before inventory)
    'inventory_movements',
    
    # Inventory
    'inventory',
    
    # Product samples
    'product_samples',
    
    # Manufacturing orders (if exists)
    'manufacturing_purchase_order_items',
    'manufacturing_purchase_orders',
    'manufacturing_production_materials',
    'manufacturing_production_order_items',
    'manufacturing_production_orders',
    'manufacturing_payable_items',
    'manufacturing_payables',
]

# Tables to keep data (master data)
KEEP_TABLES = [
    'products',           # Keep products catalog
    'product_categories', # Keep categories
    'warehouses',         # Keep warehouse definitions
    'customers',          # Keep customer data
    'employees',          # Keep staff
    'companies',          # Keep company info
    'branches',           # Keep branches
    'users',              # Keep users
]

def main():
    print("=" * 60)
    print("🚨 PRODUCTION DATA CLEAR SCRIPT")
    print("=" * 60)
    print("\n⚠️  WARNING: This will DELETE all data in:")
    for table in TABLES_TO_CLEAR:
        print(f"    - {table}")
    
    print(f"\n✅ These tables will be KEPT:")
    for table in KEEP_TABLES:
        print(f"    - {table}")
    
    # Auto-confirm for scripted execution
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == '--confirm':
        confirm = 'DELETE ALL'
        print("\n🔴 Auto-confirmed via --confirm flag")
    else:
        confirm = input("\n🔴 Type 'DELETE ALL' to confirm: ")
    
    if confirm != 'DELETE ALL':
        print("❌ Aborted. No data was deleted.")
        return
    
    conn = psycopg2.connect(POOLER_URL)
    conn.autocommit = False
    cur = conn.cursor()
    
    try:
        print("\n" + "=" * 60)
        print("🗑️  CLEARING DATA...")
        print("=" * 60)
        
        for table in TABLES_TO_CLEAR:
            # Check if table exists
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' AND table_name = %s
                );
            """, (table,))
            exists = cur.fetchone()[0]
            
            if exists:
                # Get count before
                cur.execute(f"SELECT COUNT(*) FROM {table}")
                count = cur.fetchone()[0]
                
                if count > 0:
                    # Truncate with cascade
                    cur.execute(f"TRUNCATE TABLE {table} CASCADE")
                    print(f"✅ {table}: Deleted {count} rows")
                else:
                    print(f"⏭️  {table}: Already empty")
            else:
                print(f"⚠️  {table}: Table does not exist (skipped)")
        
        # Commit transaction
        conn.commit()
        
        print("\n" + "=" * 60)
        print("✅ ALL DATA CLEARED SUCCESSFULLY!")
        print("=" * 60)
        print("\n📋 Summary of kept tables:")
        
        for table in KEEP_TABLES:
            cur.execute(f"""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' AND table_name = %s
                );
            """, (table,))
            exists = cur.fetchone()[0]
            if exists:
                cur.execute(f"SELECT COUNT(*) FROM {table}")
                count = cur.fetchone()[0]
                print(f"   {table}: {count} records")
        
    except Exception as e:
        conn.rollback()
        print(f"\n❌ ERROR: {e}")
        print("🔄 All changes have been rolled back.")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    main()
