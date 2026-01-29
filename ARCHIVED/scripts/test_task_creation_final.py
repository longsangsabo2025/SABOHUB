"""
Final test - Create a task with UPPERCASE values
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
    print("🧪 FINAL TEST - Creating task with UPPERCASE values")
    print("="*80)
    
    # Get a test user
    cur.execute("SELECT id, email, full_name FROM public.users WHERE role = 'CEO' LIMIT 1;")
    user = cur.fetchone()
    
    if not user:
        print("❌ No user found!")
        exit(1)
    
    user_id, user_email, user_name = user
    print(f"\nTest user: {user_name} ({user_email})")
    print(f"User ID: {user_id}")
    
    # Create test task with all required fields
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
            RETURNING id, title, priority, status, category, recurrence, progress;
        """, (
            'Test Task - SABOHUB Integration',
            'This is a test task created after fixing all constraints',
            'MEDIUM',           # UPPERCASE
            'PENDING',          # UPPERCASE
            user_id,            # Valid user ID
            user_id,            # Valid user ID
            due_date,           # Future date
            'operations',       # Category (lowercase is OK)
            'NONE',             # UPPERCASE
            0                   # Progress 0-100
        ))
        
        result = cur.fetchone()
        conn.commit()
        
        if result:
            task_id, title, priority, status, category, recurrence, progress = result
            
            print("\n✅ SUCCESS! Task created:")
            print(f"   ID: {task_id}")
            print(f"   Title: {title}")
            print(f"   Priority: {priority}")
            print(f"   Status: {status}")
            print(f"   Category: {category}")
            print(f"   Recurrence: {recurrence}")
            print(f"   Progress: {progress}%")
            
            # Verify the task
            cur.execute("""
                SELECT 
                    t.id,
                    t.title,
                    t.priority,
                    t.status,
                    u.email as assigned_to_email,
                    t.due_date
                FROM public.tasks t
                LEFT JOIN public.users u ON t.assigned_to = u.id
                WHERE t.id = %s;
            """, (task_id,))
            
            task_data = cur.fetchone()
            if task_data:
                print("\n📊 Task verification:")
                print(f"   Assigned to: {task_data[4]}")
                print(f"   Due date: {task_data[5]}")
            
            # Clean up
            print("\n🧹 Cleaning up test task...")
            cur.execute("DELETE FROM public.tasks WHERE id = %s;", (task_id,))
            conn.commit()
            print("   ✅ Test task deleted")
            
            print("\n" + "="*80)
            print("✅ ALL TESTS PASSED!")
            print("="*80)
            print("\n🎉 Your Flutter app can now create tasks successfully!")
            print("\n📝 Make sure your app sends these values:")
            print("   - priority: LOW, MEDIUM, HIGH, or URGENT")
            print("   - status: PENDING, IN_PROGRESS, COMPLETED, or CANCELLED")
            print("   - recurrence: NONE, DAILY, WEEKLY, MONTHLY, ADHOC, or PROJECT")
            print("   - assigned_to: Valid user ID from public.users table")
            print("   - progress: Integer between 0-100")
            
        else:
            print("\n❌ Task created but no data returned")
            
    except Exception as e:
        conn.rollback()
        print(f"\n❌ FAILED to create task!")
        print(f"   Error: {str(e)}")
        
        # Show detailed error
        import traceback
        print("\nDetailed error:")
        traceback.print_exc()
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Database error: {str(e)}")
    import traceback
    traceback.print_exc()
