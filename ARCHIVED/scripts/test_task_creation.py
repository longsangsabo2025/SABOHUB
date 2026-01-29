"""
Automated backend test for task creation
"""
import os
from dotenv import load_dotenv
import psycopg2
from datetime import datetime, timedelta
import uuid

load_dotenv()

def test_create_task():
    """Test task creation directly in database"""
    
    db_url = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not db_url:
        print("❌ Error: SUPABASE_CONNECTION_STRING not found")
        return False
    
    try:
        print("=" * 70)
        print("🧪 AUTOMATED TASK CREATION TEST")
        print("=" * 70)
        
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        # Step 1: Get a valid user ID
        print("\n📋 Step 1: Getting valid user ID...")
        cur.execute("""
            SELECT id, email FROM auth.users LIMIT 1
        """)
        user_result = cur.fetchone()
        
        if not user_result:
            print("   ❌ No users found in database")
            return False
        
        user_id, user_email = user_result
        print(f"   ✅ Found user: {user_email} ({user_id})")
        
        # Step 2: Get a valid branch ID
        print("\n📋 Step 2: Getting valid branch ID...")
        cur.execute("""
            SELECT id, name FROM branches LIMIT 1
        """)
        branch_result = cur.fetchone()
        
        if not branch_result:
            print("   ❌ No branches found in database")
            print("   Creating a test branch...")
            
            # Create a test branch
            test_branch_id = str(uuid.uuid4())
            cur.execute("""
                INSERT INTO branches (id, name, address, phone, created_at, updated_at)
                VALUES (%s, 'Test Branch', 'Test Address', '0123456789', NOW(), NOW())
                RETURNING id, name
            """, (test_branch_id,))
            branch_result = cur.fetchone()
            print(f"   ✅ Created test branch: {branch_result[1]} ({branch_result[0]})")
        
        branch_id, branch_name = branch_result
        print(f"   ✅ Using branch: {branch_name} ({branch_id})")
        
        # Step 3: Create test task
        print("\n📋 Step 3: Creating test task...")
        
        test_task = {
            'id': str(uuid.uuid4()),
            'branch_id': branch_id,
            'company_id': None,  # Nullable as we fixed
            'title': 'Test Task - ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'description': 'Automated test task created by Python script',
            'category': 'operations',
            'priority': 'medium',
            'status': 'pending',
            'assigned_to': user_id,
            'assigned_to_name': user_email.split('@')[0],
            'created_by': user_id,
            'created_by_name': user_email.split('@')[0],
            'due_date': (datetime.now() + timedelta(days=7)).isoformat(),
            'notes': 'This is an automated test task',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
        
        print(f"   Task details:")
        print(f"     - ID: {test_task['id']}")
        print(f"     - Title: {test_task['title']}")
        print(f"     - Branch: {branch_name}")
        print(f"     - Assigned to: {test_task['assigned_to_name']}")
        print(f"     - Category: {test_task['category']}")
        print(f"     - Due date: {test_task['due_date']}")
        
        # Insert task
        cur.execute("""
            INSERT INTO tasks (
                id, branch_id, company_id, title, description, 
                category, priority, status, 
                assigned_to, assigned_to_name, 
                created_by, created_by_name,
                due_date, notes, 
                created_at, updated_at
            ) VALUES (
                %s, %s, %s, %s, %s,
                %s, %s, %s,
                %s, %s,
                %s, %s,
                %s, %s,
                %s, %s
            )
            RETURNING id, title, category, status
        """, (
            test_task['id'], test_task['branch_id'], test_task['company_id'],
            test_task['title'], test_task['description'],
            test_task['category'], test_task['priority'], test_task['status'],
            test_task['assigned_to'], test_task['assigned_to_name'],
            test_task['created_by'], test_task['created_by_name'],
            test_task['due_date'], test_task['notes'],
            test_task['created_at'], test_task['updated_at']
        ))
        
        result = cur.fetchone()
        if result:
            task_id, title, category, status = result
            print(f"\n   ✅ Task created successfully!")
            print(f"     - ID: {task_id}")
            print(f"     - Title: {title}")
            print(f"     - Category: {category}")
            print(f"     - Status: {status}")
        
        # Step 4: Verify task was created
        print("\n📋 Step 4: Verifying task in database...")
        cur.execute("""
            SELECT id, title, category, status, created_by_name, notes
            FROM tasks
            WHERE id = %s
        """, (test_task['id'],))
        
        verify_result = cur.fetchone()
        if verify_result:
            print(f"   ✅ Task verified in database:")
            print(f"     - ID: {verify_result[0]}")
            print(f"     - Title: {verify_result[1]}")
            print(f"     - Category: {verify_result[2]}")
            print(f"     - Status: {verify_result[3]}")
            print(f"     - Created by: {verify_result[4]}")
            print(f"     - Notes: {verify_result[5]}")
        else:
            print("   ❌ Task not found in database")
            return False
        
        # Step 5: Count total tasks
        print("\n📋 Step 5: Counting total tasks...")
        cur.execute("SELECT COUNT(*) FROM tasks")
        total_tasks = cur.fetchone()[0]
        print(f"   ✅ Total tasks in database: {total_tasks}")
        
        cur.close()
        conn.close()
        
        print("\n" + "=" * 70)
        print("✅ ALL TESTS PASSED!")
        print("=" * 70)
        print(f"\n🎉 Successfully created task: {test_task['title']}")
        print(f"📊 Total tasks: {total_tasks}")
        
        return True
        
    except psycopg2.Error as e:
        print(f"\n❌ Database error: {e}")
        print(f"   Error code: {e.pgcode}")
        print(f"   Error details: {e.pgerror}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🚀 Starting automated task creation test...\n")
    success = test_create_task()
    
    if success:
        print("\n✅ Backend test completed successfully!")
        print("✅ Task system is working correctly!")
    else:
        print("\n❌ Backend test failed!")
        print("❌ Please check the errors above.")
