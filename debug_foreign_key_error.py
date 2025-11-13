"""
Debug the foreign key constraint error for tasks
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
    print("🔍 DEBUGGING: tasks_assigned_to_fkey constraint")
    print("="*80)
    
    # Check the exact foreign key constraint definition
    cur.execute("""
        SELECT
            tc.constraint_name,
            tc.table_name,
            kcu.column_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            rc.delete_rule,
            rc.update_rule
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        JOIN information_schema.referential_constraints AS rc
            ON rc.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'tasks'
        AND kcu.column_name = 'assigned_to';
    """)
    
    result = cur.fetchone()
    if result:
        print("\n✅ Found constraint:")
        const_name, table, column, fk_schema, fk_table, fk_column, del_rule, upd_rule = result
        print(f"   Name: {const_name}")
        print(f"   Column: {table}.{column}")
        print(f"   References: {fk_schema}.{fk_table}.{fk_column}")
        print(f"   On Delete: {del_rule}")
        print(f"   On Update: {upd_rule}")
        
        ref_table_full = f"{fk_schema}.{fk_table}"
    else:
        print("\n❌ No foreign key constraint found on assigned_to column")
        cur.close()
        conn.close()
        exit(1)
    
    # Check if the referenced table exists
    print(f"\n" + "="*80)
    print(f"📊 Checking referenced table: {ref_table_full}")
    print("="*80)
    
    cur.execute(f"""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = '{fk_schema}' 
            AND table_name = '{fk_table}'
        );
    """)
    
    table_exists = cur.fetchone()[0]
    
    if table_exists:
        print(f"\n✅ Table {ref_table_full} EXISTS")
        
        # Count users in the referenced table
        cur.execute(f"SELECT COUNT(*) FROM {ref_table_full};")
        user_count = cur.fetchone()[0]
        print(f"📊 Total users: {user_count}")
        
        if user_count > 0:
            # Show all user IDs
            cur.execute(f"SELECT id, email FROM {ref_table_full} LIMIT 20;")
            print(f"\nUser IDs in {ref_table_full}:")
            for user_id, email in cur.fetchall():
                print(f"   - {user_id} | {email}")
    else:
        print(f"\n❌ Table {ref_table_full} DOES NOT EXIST!")
    
    # Now let's try to create a test task to see what happens
    print(f"\n" + "="*80)
    print("🧪 TEST: Creating a test task")
    print("="*80)
    
    # Get the first user ID
    cur.execute(f"SELECT id, email FROM {ref_table_full} LIMIT 1;")
    test_user = cur.fetchone()
    
    if test_user:
        test_user_id, test_email = test_user
        print(f"\nUsing test user: {test_email} (ID: {test_user_id})")
        
        # Try to create a task
        try:
            cur.execute("""
                INSERT INTO public.tasks (
                    title,
                    description,
                    priority,
                    status,
                    assigned_to,
                    created_by
                ) VALUES (
                    'Test Task from Debug Script',
                    'This is a test task to debug foreign key constraint',
                    'MEDIUM',
                    'PENDING',
                    %s,
                    %s
                )
                RETURNING id, title;
            """, (test_user_id, test_user_id))
            
            task_id, task_title = cur.fetchone()
            conn.commit()
            
            print(f"\n✅ SUCCESS! Task created:")
            print(f"   ID: {task_id}")
            print(f"   Title: {task_title}")
            
            # Clean up - delete the test task
            cur.execute("DELETE FROM public.tasks WHERE id = %s;", (task_id,))
            conn.commit()
            print(f"\n🧹 Cleaned up test task")
            
        except Exception as e:
            conn.rollback()
            print(f"\n❌ FAILED to create task!")
            print(f"   Error: {str(e)}")
            
            # Let's check what value is being used for assigned_to in the app
            print(f"\n🔍 Possible issues:")
            print(f"   1. The app might be sending NULL or empty string for assigned_to")
            print(f"   2. The app might be sending a user ID that doesn't exist")
            print(f"   3. The app might be using auth.users IDs instead of public.users IDs")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
