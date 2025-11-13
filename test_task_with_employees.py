"""
Test creating task with employee reference
"""
import os
from dotenv import load_dotenv
import psycopg2
from datetime import datetime, timedelta

load_dotenv()

conn_string = os.getenv("SUPABASE_CONNECTION_STRING")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("="*80)
    print("🧪 FINAL TEST - Creating task with employee reference")
    print("="*80)
    
    # Get a test employee
    cur.execute("SELECT id, full_name, email FROM employees WHERE deleted_at IS NULL LIMIT 1;")
    employee = cur.fetchone()
    
    if not employee:
        print("❌ No employee found!")
        exit(1)
    
    emp_id, emp_name, emp_email = employee
    print(f"\nTest employee: {emp_name} ({emp_email})")
    print(f"Employee ID: {emp_id}")
    
    # Create test task
    print("\n📝 Creating task...")
    
    due_date = datetime.now() + timedelta(days=7)
    
    try:
        cur.execute("""
            INSERT INTO public.tasks (
                title,
                description,
                priority,
                status,
                assigned_to,
                created_by,
                due_date,
                category,
                recurrence,
                progress
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
            RETURNING id, title, priority, status;
        """, (
            'Test Task - Employee Reference',
            'Testing with employees table foreign key',
            'medium',
            'pending',
            emp_id,            # Employee ID
            emp_id,            # Employee ID
            due_date,
            'operations',
            'none',
            0
        ))
        
        result = cur.fetchone()
        conn.commit()
        
        if result:
            task_id, title, priority, status = result
            
            print("\n✅ SUCCESS! Task created:")
            print(f"   ID: {task_id}")
            print(f"   Title: {title}")
            print(f"   Priority: {priority}")
            print(f"   Status: {status}")
            print(f"   Assigned to: {emp_name}")
            
            # Clean up
            print("\n🧹 Cleaning up test task...")
            cur.execute("DELETE FROM public.tasks WHERE id = %s;", (task_id,))
            conn.commit()
            
            print("\n" + "="*80)
            print("✅ ALL TESTS PASSED!")
            print("="*80)
            print("\n🎉 Your Flutter app can now create tasks!")
            print("\n📝 Make sure the app:")
            print("   1. Uses employee IDs (from employees table)")
            print("   2. NOT user IDs (from users table)")
            print("   3. Sends lowercase values: priority='medium', status='pending'")
            
        else:
            print("\n❌ Task created but no data returned")
            
    except Exception as e:
        conn.rollback()
        print(f"\n❌ FAILED to create task!")
        print(f"   Error: {str(e)}")
        import traceback
        traceback.print_exc()
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Database error: {str(e)}")
    import traceback
    traceback.print_exc()
