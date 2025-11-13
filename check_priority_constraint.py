"""
Check priority constraint in tasks table
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
    
    # Get check constraints on tasks table
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
        AND con.conname LIKE '%priority%'
        ORDER BY con.conname;
    """)
    
    constraints = cur.fetchall()
    
    if constraints:
        print("\nPriority constraints found:")
        for name, definition in constraints:
            print(f"\n  {name}:")
            print(f"    {definition}")
    else:
        print("\nNo priority constraints found")
    
    # Also check the column definition
    cur.execute("""
        SELECT 
            column_name,
            data_type,
            column_default,
            is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'tasks'
        AND column_name = 'priority';
    """)
    
    col_info = cur.fetchone()
    if col_info:
        print("\n" + "="*80)
        print("📊 Priority column info:")
        print("="*80)
        col_name, data_type, default, nullable = col_info
        print(f"  Name: {col_name}")
        print(f"  Type: {data_type}")
        print(f"  Default: {default}")
        print(f"  Nullable: {nullable}")
    
    # Test different priority values
    print("\n" + "="*80)
    print("🧪 TESTING PRIORITY VALUES")
    print("="*80)
    
    test_values = ['LOW', 'MEDIUM', 'HIGH', 'URGENT', 'low', 'medium', 'high', 'urgent']
    
    cur.execute("SELECT id FROM public.users LIMIT 1;")
    test_user_id = cur.fetchone()[0]
    
    for priority_val in test_values:
        try:
            cur.execute("""
                INSERT INTO public.tasks (
                    title,
                    priority,
                    status,
                    assigned_to,
                    created_by
                ) VALUES (
                    'Test Task',
                    %s,
                    'pending',
                    %s,
                    %s
                )
                RETURNING id;
            """, (priority_val, test_user_id, test_user_id))
            
            task_id = cur.fetchone()[0]
            conn.commit()
            
            print(f"  ✅ '{priority_val}' - WORKS")
            
            # Clean up
            cur.execute("DELETE FROM public.tasks WHERE id = %s;", (task_id,))
            conn.commit()
            
        except Exception as e:
            conn.rollback()
            error_msg = str(e)
            if 'priority_check' in error_msg:
                print(f"  ❌ '{priority_val}' - INVALID")
            else:
                print(f"  ❌ '{priority_val}' - ERROR: {error_msg[:100]}")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
