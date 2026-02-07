"""
Check database triggers for inventory_movements
"""
import psycopg2
from psycopg2.extras import RealDictCursor

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("CHECKING DATABASE TRIGGERS")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print("✓ Connected\n")

    # 1. Check triggers on inventory_movements table
    print("1. TRIGGERS ON inventory_movements:")
    cur.execute("""
        SELECT 
            t.tgname as trigger_name,
            pg_get_triggerdef(t.oid) as trigger_definition
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        WHERE c.relname = 'inventory_movements'
        AND NOT t.tgisinternal
        ORDER BY t.tgname
    """)
    
    triggers = cur.fetchall()
    if triggers:
        for trig in triggers:
            print(f"\n   Trigger: {trig['trigger_name']}")
            print(f"   Definition:\n   {trig['trigger_definition']}\n")
    else:
        print("   ⚠️  No triggers found on inventory_movements table")
    
    # 2. Check triggers on inventory table
    print("\n2. TRIGGERS ON inventory:")
    cur.execute("""
        SELECT 
            t.tgname as trigger_name,
            pg_get_triggerdef(t.oid) as trigger_definition
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        WHERE c.relname = 'inventory'
        AND NOT t.tgisinternal
        ORDER BY t.tgname
    """)
    
    inv_triggers = cur.fetchall()
    if inv_triggers:
        for trig in inv_triggers:
            print(f"\n   Trigger: {trig['trigger_name']}")
            print(f"   Definition:\n   {trig['trigger_definition']}\n")
    else:
        print("   ⚠️  No triggers found on inventory table")
    
    # 3. Check functions related to inventory
    print("\n3. FUNCTIONS RELATED TO INVENTORY:")
    cur.execute("""
        SELECT 
            p.proname as function_name,
            pg_get_functiondef(p.oid) as function_definition
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND (
            p.proname LIKE '%inventory%'
            OR p.proname LIKE '%movement%'
            OR p.proname LIKE '%stock%'
        )
        ORDER BY p.proname
    """)
    
    functions = cur.fetchall()
    if functions:
        print(f"   Found {len(functions)} function(s):")
        for func in functions:
            print(f"\n   Function: {func['function_name']}")
            # Only print first 500 chars of definition
            definition = func['function_definition']
            if len(definition) > 500:
                print(f"   {definition[:500]}...")
            else:
                print(f"   {definition}")
    else:
        print("   No inventory-related functions found")

    print("\n" + "=" * 70)
    print("ANALYSIS:")
    print("=" * 70)
    
    if not triggers and not inv_triggers:
        print("\n❌ NO TRIGGERS FOUND!")
        print("\n   This means:")
        print("   - Code comment says 'trigger will handle inventory update'")
        print("   - But NO triggers exist in database")
        print("   - Inventory updates might not be working correctly")
        print("\n   SOLUTION:")
        print("   - Either create database triggers")
        print("   - OR update code to manually handle inventory updates")
    else:
        print("\n✅ Triggers exist - check if they handle all cases correctly")

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
