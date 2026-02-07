#!/usr/bin/env python3
"""
Check inventory triggers and deduction logic
"""

import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def check_triggers():
    print("🔍 Checking inventory triggers...")
    
    conn = psycopg2.connect(POOLER_URL)
    cur = conn.cursor()
    
    # Check triggers on relevant tables
    cur.execute("""
        SELECT 
            trigger_name,
            event_object_table,
            event_manipulation,
            action_timing
        FROM information_schema.triggers 
        WHERE event_object_table IN ('sales_orders', 'sales_order_items', 'deliveries', 'inventory', 'inventory_movements')
        ORDER BY event_object_table, trigger_name
    """)
    
    triggers = cur.fetchall()
    
    print("\n📋 Current triggers:")
    if not triggers:
        print("   ⚠️ No triggers found on these tables!")
    else:
        for t in triggers:
            print(f"   - {t[0]} on {t[1]} ({t[3]} {t[2]})")
    
    # Check functions related to inventory
    cur.execute("""
        SELECT routine_name, routine_type
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND (routine_name LIKE '%inventory%' OR routine_name LIKE '%stock%' OR routine_name LIKE '%picking%')
    """)
    
    functions = cur.fetchall()
    print("\n📋 Inventory-related functions:")
    if not functions:
        print("   ⚠️ No inventory functions found!")
    else:
        for f in functions:
            print(f"   - {f[0]} ({f[1]})")
    
    # Check if process_inventory_movement trigger exists
    cur.execute("""
        SELECT pg_get_functiondef(oid) 
        FROM pg_proc 
        WHERE proname = 'process_inventory_movement'
    """)
    
    result = cur.fetchone()
    if result:
        print("\n📋 process_inventory_movement function:")
        print(result[0][:500] + "..." if len(result[0]) > 500 else result[0])
    else:
        print("\n⚠️ process_inventory_movement function NOT FOUND!")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    check_triggers()
