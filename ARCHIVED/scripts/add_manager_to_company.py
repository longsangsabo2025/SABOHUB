import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv('SUPABASE_URL')
SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SERVICE_ROLE_KEY:
    print("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env file")
    exit(1)

# Create Supabase client with SERVICE_ROLE_KEY (bypasses RLS)
supabase: Client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

def add_manager_to_company():
    """
    Add a new manager to SABO Billiards company
    Email: ngocdiem1112@gmail.com
    Role: BRANCH_MANAGER
    """
    
    print("🔍 Step 1: Getting SABO Billiards company ID...")
    
    # Get SABO Billiards company
    company_response = supabase.table('companies').select('id, name').eq('name', 'SABO Billiards').execute()
    
    if not company_response.data or len(company_response.data) == 0:
        print("❌ SABO Billiards company not found!")
        return
    
    company = company_response.data[0]
    company_id = company['id']
    company_name = company['name']
    
    print(f"✅ Found company: {company_name} (ID: {company_id})")
    
    print("\n🔍 Step 2: Checking if user exists...")
    
    # Check if user with this email already exists
    email = "ngocdiem1112@gmail.com"
    user_response = supabase.table('users').select('*').eq('email', email).execute()
    
    if user_response.data and len(user_response.data) > 0:
        # User exists, update their role and company
        user = user_response.data[0]
        user_id = user['id']
        print(f"✅ User already exists: {user.get('full_name', 'N/A')} ({email})")
        print(f"   Current role: {user.get('role', 'N/A')}")
        print(f"   Current company_id: {user.get('company_id', 'N/A')}")
        
        print("\n🔄 Step 3: Updating user to BRANCH_MANAGER role and assigning to company...")
        
        update_data = {
            'role': 'BRANCH_MANAGER',
            'company_id': company_id
        }
        
        update_response = supabase.table('users').update(update_data).eq('id', user_id).execute()
        
        if update_response.data:
            print(f"✅ User updated successfully!")
            print(f"   New role: BRANCH_MANAGER")
            print(f"   Assigned to company: {company_name}")
        else:
            print(f"❌ Failed to update user")
            
    else:
        print(f"⚠️ User with email {email} does not exist in the database")
        print("\n💡 The user needs to:")
        print("   1. Sign up in the app first")
        print("   2. Verify their email")
        print("   3. Then run this script to assign them as manager")
        print("\nℹ️ Or we can create a Supabase Auth user directly. Would you like that?")
        
        # For now, let's try to insert a basic user record
        # Note: This won't create a Supabase Auth user, just a database record
        print("\n⚠️ Creating user record without Supabase Auth (they'll need to sign up to login)")
        
        insert_data = {
            'email': email,
            'full_name': 'Ngọc Diễm',  # You can customize this
            'role': 'BRANCH_MANAGER',
            'company_id': company_id,
            'email_verified': False
        }
        
        try:
            insert_response = supabase.table('users').insert(insert_data).execute()
            
            if insert_response.data:
                print(f"✅ User record created!")
                print(f"   Email: {email}")
                print(f"   Role: BRANCH_MANAGER")
                print(f"   Company: {company_name}")
                print("\n⚠️ Note: User still needs to sign up in the app to create Supabase Auth account")
            else:
                print(f"❌ Failed to create user record")
        except Exception as e:
            print(f"❌ Error creating user: {e}")
    
    print("\n" + "="*50)
    print("📋 Final Summary:")
    print("="*50)
    
    # Get final user state
    final_user = supabase.table('users').select('*').eq('email', email).execute()
    
    if final_user.data and len(final_user.data) > 0:
        user = final_user.data[0]
        print(f"✅ User: {user.get('full_name', 'N/A')}")
        print(f"   Email: {user.get('email')}")
        print(f"   Role: {user.get('role')}")
        print(f"   Company ID: {user.get('company_id')}")
        print(f"   Email Verified: {user.get('email_verified', False)}")
    else:
        print("❌ User not found in database")

if __name__ == "__main__":
    print("🚀 Adding Manager to SABO Billiards Company")
    print("="*50)
    add_manager_to_company()
