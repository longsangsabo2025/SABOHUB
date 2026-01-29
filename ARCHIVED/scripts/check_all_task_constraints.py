"""
Check ALL constraints on tasks table and show valid values
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.getenv("SUPABASE_CONNECTION_STRING")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("="*80)
    print("🔍 ALL CHECK CONSTRAINTS ON TASKS TABLE")
    print("="*80)
    
    # Get all check constraints on tasks table
    cur.execute("""
        SELECT 
            con.conname AS constraint_name,
            pg_get_constraintdef(con.oid) AS constraint_definition
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE rel.relname = 'tasks'
        AND nsp.nspname = 'public'
        AND con.contype = 'c'
        ORDER BY con.conname;
    """)
    
    constraints = cur.fetchall()
    
    if constraints:
        for name, definition in constraints:
            print(f"\n📋 {name}:")
            print(f"   {definition}")
            
            # Extract valid values if it's an ARRAY check
            if 'ARRAY[' in definition:
                import re
                values = re.findall(r"'([^']+)'::text", definition)
                if values:
                    print(f"   ✅ Valid values: {', '.join(values)}")
    
    print("\n" + "="*80)
    print("📝 SUMMARY - Valid values for each field:")
    print("="*80)
    print("\n  priority: low, medium, high, urgent")
    print("  status: pending, in_progress, completed, cancelled")
    print("  category: operations, cleaning, maintenance, inventory, customer_service, admin")
    print("  recurrence: none, daily, weekly, biweekly, monthly")
    print("  role (users table): CEO, MANAGER, SHIFT_LEADER, STAFF")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
