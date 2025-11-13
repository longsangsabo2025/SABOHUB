"""
Debug what value the app is sending for priority
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
    print("🔍 CHECKING PRIORITY CONSTRAINT")
    print("="*80)
    
    # Get the exact constraint
    cur.execute("""
        SELECT pg_get_constraintdef(con.oid) AS constraint_definition
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE rel.relname = 'tasks'
        AND nsp.nspname = 'public'
        AND con.conname = 'tasks_priority_check';
    """)
    
    result = cur.fetchone()
    if result:
        print(f"\nCurrent constraint:")
        print(f"  {result[0]}")
    
    # Test all possible variations
    print("\n" + "="*80)
    print("🧪 TESTING ALL PRIORITY VARIATIONS")
    print("="*80)
    
    test_values = [
        'LOW', 'MEDIUM', 'HIGH', 'URGENT',           # UPPERCASE
        'low', 'medium', 'high', 'urgent',           # lowercase
        'Low', 'Medium', 'High', 'Urgent',           # Capitalize
        'Trung bình', 'Trung Bình', 'TRUNG BÌNH',    # Vietnamese
        '', None, 'null', 'NULL'                      # Edge cases
    ]
    
    cur.execute("SELECT id FROM public.users LIMIT 1;")
    test_user_id = cur.fetchone()[0]
    
    for priority_val in test_values:
        try:
            # Use None for NULL test
            if priority_val == 'null':
                priority_val = None
            
            cur.execute("""
                INSERT INTO public.tasks (
                    title,
                    priority,
                    status,
                    created_by
                ) VALUES (
                    'Test',
                    %s,
                    'PENDING',
                    %s
                )
                RETURNING id;
            """, (priority_val, test_user_id))
            
            task_id = cur.fetchone()[0]
            conn.commit()
            
            print(f"  ✅ '{priority_val}' - WORKS")
            
            # Clean up
            cur.execute("DELETE FROM public.tasks WHERE id = %s;", (task_id,))
            conn.commit()
            
        except Exception as e:
            conn.rollback()
            error_msg = str(e)
            if priority_val == '' or priority_val is None:
                print(f"  ❌ {repr(priority_val)} - {error_msg[:80]}")
            else:
                print(f"  ❌ '{priority_val}' - INVALID")
    
    print("\n" + "="*80)
    print("💡 SUGGESTION:")
    print("="*80)
    print("The app might be sending Vietnamese text or a different format.")
    print("Please check the Flutter code where task is created.")
    print("\nLook for where 'priority' is set, might be something like:")
    print("  priority: 'Trung bình'  ❌ WRONG")
    print("  priority: 'MEDIUM'      ✅ CORRECT")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
