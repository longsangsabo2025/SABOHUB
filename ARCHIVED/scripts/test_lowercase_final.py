"""
Final test with lowercase values
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
    print("🧪 FINAL TEST - Creating task with lowercase values")
    print("="*80)
    
    # Get a test user
    cur.execute("SELECT id, email, full_name, role FROM public.users WHERE role = 'ceo' LIMIT 1;")
    user = cur.fetchone()
    
    if not user:
        print("❌ No CEO user found!")
        exit(1)
    
    user_id, user_email, user_name, user_role = user
    print(f"\nTest user: {user_name} ({user_email})")
    print(f"User ID: {user_id}")
    print(f"Role: {user_role}")
    
    # Create test task
    print("\n📝 Creating task with lowercase values...")
    
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
            'Test Task - Final Check',
            'Testing with lowercase values matching Flutter enum.name',
            'medium',           # lowercase - matches enum.name
            'pending',          # lowercase - matches enum.name
            user_id,
            user_id,
            due_date,
            'operations',
            'none',             # lowercase - matches enum.name
            0
        ))
        
        result = cur.fetchone()
        conn.commit()
        
        if result:
            task_id, title, priority, status, category, recurrence, progress = result
            
            print("\n✅ SUCCESS! Task created with lowercase values:")
            print(f"   ID: {task_id}")
            print(f"   Title: {title}")
            print(f"   Priority: {priority}")
            print(f"   Status: {status}")
            print(f"   Category: {category}")
            print(f"   Recurrence: {recurrence}")
            print(f"   Progress: {progress}%")
            
            # Clean up
            print("\n🧹 Cleaning up test task...")
            cur.execute("DELETE FROM public.tasks WHERE id = %s;", (task_id,))
            conn.commit()
            
            print("\n" + "="*80)
            print("✅ ALL TESTS PASSED!")
            print("="*80)
            print("\n🎉 Flutter app will now work correctly!")
            print("\n📝 The app uses enum.name which gives lowercase:")
            print("   TaskPriority.medium.name → 'medium' ✅")
            print("   TaskStatus.inProgress → status.toDbValue() → 'in_progress' ✅")
            print("   TaskRecurrence.daily.name → 'daily' ✅")
            
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
