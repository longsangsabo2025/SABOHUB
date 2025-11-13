from supabase import create_client
from dotenv import load_dotenv
import os

load_dotenv()

url = os.getenv("SUPABASE_URL")
anon_key = os.getenv("SUPABASE_ANON_KEY")

print("\n🧪 REAL TEST: CEO LOGIN AND DELETE TASK\n")
print("=" * 80)

# Create client
supabase = create_client(url, anon_key)

# 1. Login as CEO
print("\n1️⃣ Logging in as CEO...\n")
CEO_EMAIL = "longsangsabo1@gmail.com"
CEO_PASSWORD = "Test@123"  # You need to use real password

try:
    # Try to login
    auth_response = supabase.auth.sign_in_with_password({
        "email": CEO_EMAIL,
        "password": CEO_PASSWORD
    })
    
    print(f"✅ Logged in as: {auth_response.user.email}")
    print(f"   User ID: {auth_response.user.id}")
    
    # 2. Get an active task
    print(f"\n2️⃣ Getting active tasks...\n")
    tasks = supabase.table('tasks').select('*').eq('company_id', 'feef10d3-899d-4554-8107-b2256918213a').is_('deleted_at', 'null').limit(1).execute()
    
    if not tasks.data:
        print("❌ No active tasks found")
        exit()
    
    task = tasks.data[0]
    print(f"✅ Found task: {task['title']}")
    print(f"   ID: {task['id']}")
    
    # 3. Try to soft delete
    print(f"\n3️⃣ Attempting soft delete...\n")
    from datetime import datetime
    
    result = supabase.table('tasks').update({
        'deleted_at': datetime.now().isoformat()
    }).eq('id', task['id']).execute()
    
    if result.data:
        print(f"✅ SOFT DELETE SUCCESS!")
        print(f"   Deleted: {result.data[0]['title']}")
        print(f"   deleted_at: {result.data[0]['deleted_at']}")
        
        # 4. Verify task is still visible to CEO
        print(f"\n4️⃣ Checking if CEO can still see deleted task...\n")
        check = supabase.table('tasks').select('*').eq('id', task['id']).execute()
        
        if check.data:
            print(f"✅ CEO CAN see deleted task!")
            print(f"   Title: {check.data[0]['title']}")
            print(f"   deleted_at: {check.data[0]['deleted_at']}")
        else:
            print(f"❌ CEO CANNOT see deleted task")
        
        # 5. Restore it
        print(f"\n5️⃣ Restoring task...\n")
        restore = supabase.table('tasks').update({
            'deleted_at': None
        }).eq('id', task['id']).execute()
        
        print(f"✅ Restored: {restore.data[0]['title']}")
        
    else:
        print(f"❌ SOFT DELETE FAILED")
        print(f"   Response: {result}")
        
except Exception as e:
    print(f"❌ ERROR: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 80 + "\n")
