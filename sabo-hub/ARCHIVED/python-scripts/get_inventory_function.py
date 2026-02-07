"""
Get full definition of process_inventory_movement function
"""
import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    print("=" * 70)
    print("PROCESS_INVENTORY_MOVEMENT FUNCTION")
    print("=" * 70)
    
    cur.execute("""
        SELECT pg_get_functiondef(oid)
        FROM pg_proc
        WHERE proname = 'process_inventory_movement'
    """)
    
    result = cur.fetchone()
    if result:
        print(result[0])
    else:
        print("Function not found")
    
    print("\n" + "=" * 70)

except Exception as e:
    print(f"Error: {e}")
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
