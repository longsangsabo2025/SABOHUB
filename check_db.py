from dotenv import load_dotenv
import os
load_dotenv()

from supabase import create_client

print("="*60)
print("TESTING WITH SERVICE_ROLE_KEY")
print("="*60)

# Use SERVICE_ROLE_KEY for admin access
supabase = create_client(
    os.getenv('SUPABASE_URL'), 
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("\n1. Check employees table:")
try:
    r = supabase.table('employees').select('*').limit(1).execute()
    if r.data:
        print(f"   ✅ Has {len(r.data)} record(s)")
        print(f"   Columns: {list(r.data[0].keys())}")
        print(f"   Sample: {r.data[0]}")
    else:
        print("   ⚠️  Table is EMPTY")
except Exception as e:
    print(f"   ❌ Error: {e}")

print("\n2. Check attendance table:")
try:
    r = supabase.table('attendance').select('*').limit(1).execute()
    if r.data:
        print(f"   ✅ Has {len(r.data)} record(s)")
        print(f"   Columns: {list(r.data[0].keys())}")
    else:
        print("   ⚠️  Table is EMPTY")
except Exception as e:
    print(f"   ❌ Error: {e}")

print("\n3. Check tasks table:")
try:
    r = supabase.table('tasks').select('*').limit(1).execute()
    if r.data:
        print(f"   ✅ Has {len(r.data)} record(s)")
        print(f"   Columns: {list(r.data[0].keys())}")
    else:
        print("   ⚠️  Table is EMPTY")
except Exception as e:
    print(f"   ❌ Error: {e}")

print("\n" + "="*60)
print("TEST COMPLETE")
print("="*60)
