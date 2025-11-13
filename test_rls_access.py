import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_ANON_KEY")
supabase = create_client(url, key)

print("=" * 80)
print("TESTING RLS ACCESS WITH AUTHENTICATED USER")
print("=" * 80)

# Login as CEO
email = "longsangsabo1@gmail.com"
password = "123456789"  # Default test password

try:
    print(f"\n🔐 Logging in as: {email}")
    auth_response = supabase.auth.sign_in_with_password({
        "email": email,
        "password": password
    })
    
    if auth_response.user:
        print(f"✅ Login successful!")
        print(f"   User ID: {auth_response.user.id}")
        print(f"   Email: {auth_response.user.email}")
        
        # Try to read user data
        print(f"\n📋 Testing SELECT query on users table...")
        response = supabase.table('users').select('*').eq('id', auth_response.user.id).execute()
        
        if response.data and len(response.data) > 0:
            user = response.data[0]
            print(f"\n✅ RLS WORKING! User data retrieved:")
            print(f"   Name: {user.get('full_name')}")
            print(f"   Role: {user.get('role')}")
            print(f"   Company ID: {user.get('company_id')}")
            print(f"   Branch ID: {user.get('branch_id')}")
            
            # Try to read other users in same company
            print(f"\n📋 Testing company-wide SELECT query...")
            company_response = supabase.table('users').select('id, full_name, role').eq('company_id', user.get('company_id')).is_('deleted_at', 'null').execute()
            
            if company_response.data:
                print(f"\n✅ Company query working! Found {len(company_response.data)} users:")
                for u in company_response.data:
                    print(f"   • {u.get('full_name')} ({u.get('role')})")
            else:
                print(f"\n❌ Company query failed - no data returned")
        else:
            print(f"\n❌ RLS BLOCKING! Could not retrieve user data")
            print(f"   Response: {response}")
    else:
        print(f"❌ Login failed")
        
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    
print("\n" + "=" * 80)
