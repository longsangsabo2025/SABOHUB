import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

# Check CEO user
result = supabase.table('users').select('*').eq('email', 'longsangsabo1@gmail.com').execute()

if result.data:
    user = result.data[0]
    print('\n✅ Found user:')
    print(f'  Email: {user.get("email")}')
    print(f'  Full Name: {user.get("full_name")}')
    print(f'  Role: {user.get("role")}')
    print(f'  Company ID: {user.get("company_id")}')
    print(f'  Branch ID: {user.get("branch_id")}')
    print(f'  User ID: {user.get("id")}')
    
    # Check if role is correct
    if user.get('role') == 'CEO':
        print('\n✅ Role is correct: CEO')
    else:
        print(f'\n❌ PROBLEM: Role is {user.get("role")}, should be CEO')
        print('\n🔧 Fixing role to CEO...')
        
        # Update to CEO
        update_result = supabase.table('users').update({
            'role': 'CEO'
        }).eq('email', 'longsangsabo1@gmail.com').execute()
        
        print('✅ Role updated to CEO!')
else:
    print('❌ User not found')
