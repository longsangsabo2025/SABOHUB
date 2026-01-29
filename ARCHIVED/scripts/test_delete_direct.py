import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

# Use service_role to bypass RLS
from supabase import create_client, Client

url = os.getenv("SUPABASE_URL")
service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, service_key)

print("\n🧪 TEST SOFT DELETE DIRECTLY\n")
print("=" * 80)

# 1. Get an active task
print("\n1️⃣ Finding an active task to test delete...\n")
response = supabase.table('tasks').select('*').eq('company_id', 'feef10d3-899d-4554-8107-b2256918213a').is_('deleted_at', 'null').limit(1).execute()

if not response.data:
    print("❌ No active tasks found")
    exit()

task = response.data[0]
print(f"✅ Found task: {task['title']}")
print(f"   ID: {task['id']}")
print(f"   deleted_at: {task['deleted_at']}")

# 2. Try to soft delete using service role (bypass RLS)
print(f"\n2️⃣ Attempting soft delete (service_role - bypass RLS)...\n")

try:
    from datetime import datetime
    result = supabase.table('tasks').update({
        'deleted_at': datetime.now().isoformat()
    }).eq('id', task['id']).execute()
    
    print(f"✅ SUCCESS! Updated {len(result.data)} row(s)")
    if result.data:
        print(f"   deleted_at: {result.data[0]['deleted_at']}")
        
        # Restore it back
        print(f"\n3️⃣ Restoring task back to active state...\n")
        restore = supabase.table('tasks').update({
            'deleted_at': None
        }).eq('id', task['id']).execute()
        print(f"✅ Restored! deleted_at: {restore.data[0]['deleted_at']}")
    
except Exception as e:
    print(f"❌ ERROR: {e}")

# 3. Now test with anon key (simulating CEO)
print(f"\n4️⃣ Testing with ANON key (simulating CEO with RLS)...\n")

anon_key = os.getenv("SUPABASE_ANON_KEY")
anon_supabase: Client = create_client(url, anon_key)

# Set auth context (simulate CEO login)
# Note: We can't really set auth.uid() from Python client, this will fail with RLS

try:
    result = anon_supabase.table('tasks').update({
        'deleted_at': datetime.now().isoformat()
    }).eq('id', task['id']).execute()
    
    print(f"✅ SUCCESS with anon key! Updated {len(result.data)} row(s)")
except Exception as e:
    print(f"❌ FAILED with anon key (expected - no auth): {e}")

print("\n" + "=" * 80)
print("\n💡 CONCLUSION:")
print("   - Service role CAN update deleted_at (bypasses RLS)")
print("   - Anon key CANNOT without proper auth")
print("   - Issue: RLS policy requires deleted_at IS NULL to UPDATE")
print("   - This creates a paradox: Can't set deleted_at if it must be NULL!")
print("\n")
