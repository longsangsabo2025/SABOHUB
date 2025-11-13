import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

conn = psycopg2.connect(os.getenv("SUPABASE_CONNECTION_STRING"))
cur = conn.cursor()

print("\n🔍 CHECKING TASK 'aaaaa'\n")
print("="*80)

# Find the task
cur.execute("""
    SELECT id, title, deleted_at, company_id, created_by
    FROM tasks
    WHERE title LIKE '%aaaaa%' OR title LIKE '%aaaa%'
    ORDER BY created_at DESC
    LIMIT 5
""")

tasks = cur.fetchall()

if not tasks:
    print("❌ Task 'aaaaa' not found")
else:
    print(f"Found {len(tasks)} matching tasks:\n")
    for task in tasks:
        status = "✅ ACTIVE" if not task[2] else "❌ DELETED"
        print(f"{status}")
        print(f"  ID: {task[0]}")
        print(f"  Title: {task[1]}")
        print(f"  deleted_at: {task[2]}")
        print(f"  company_id: {task[3]}")
        print(f"  created_by: {task[4]}")
        print()

print("="*80)

# Check if RLS allows CEO to update
ceo_id = '944f7536-6c9a-4bea-99fc-f1c984fef2ef'

print("\n🧪 TESTING CEO CAN DELETE THIS TASK\n")

if tasks:
    task_id = tasks[0][0]
    
    # Try to update directly with service role (bypass RLS to test)
    try:
        from supabase import create_client
        from datetime import datetime
        
        url = os.getenv("SUPABASE_URL")
        service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
        supabase = create_client(url, service_key)
        
        # Delete with service role
        result = supabase.table('tasks').update({
            'deleted_at': datetime.now().isoformat()
        }).eq('id', task_id).execute()
        
        if result.data:
            print(f"✅ SERVICE ROLE can delete: {result.data[0]['title']}")
            print(f"   deleted_at: {result.data[0]['deleted_at']}")
            print("\n⚠️  RLS might be blocking Flutter client!")
        else:
            print(f"❌ Even SERVICE ROLE cannot delete")
            
    except Exception as e:
        print(f"❌ Error: {e}")

print("\n" + "="*80 + "\n")

cur.close()
conn.close()
