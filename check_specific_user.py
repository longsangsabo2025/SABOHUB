from supabase import create_client

SUPABASE_URL = 'https://dqddxowyikefqcdiioyh.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('='*100)
print('🔍 CHECKING USER: longsangsabo1@gmail.com')
print('='*100)
print()

# Check in public.users table
print('📋 1. PUBLIC.USERS TABLE:')
print('-'*100)
response = supabase.table('users').select('*').eq('email', 'longsangsabo1@gmail.com').execute()

if response.data:
    user = response.data[0]
    print('✅ User found in public.users table')
    print(f'   ID: {user.get(\"id\")}')
    print(f'   Email: {user.get(\"email\")}')
    print(f'   Role: {user.get(\"role\")}')
    print(f'   Full Name: {user.get(\"full_name\")}')
    print(f'   Email Verified: {user.get(\"email_verified\")}')
    print(f'   Created: {user.get(\"created_at\")}')
else:
    print('❌ User NOT found in public.users table')
    print('   This is the problem! User exists in auth.users but not in public.users')
    print('   The signup process may not have completed properly.')

print()
print('🔐 2. AUTH.USERS TABLE:')
print('-'*100)
auth_response = supabase.auth.admin.list_users()
target_user = next((u for u in auth_response if u.email == 'longsangsabo1@gmail.com'), None)

if target_user:
    print('✅ User found in auth.users')
    print(f'   ID: {target_user.id}')
    print(f'   Email: {target_user.email}')
    print(f'   Email Confirmed: {\"✅ YES\" if target_user.email_confirmed_at else \"❌ NO\"}')
    print(f'   Confirmed At: {target_user.email_confirmed_at}')
    print(f'   Last Sign In: {target_user.last_sign_in_at}')
    print(f'   Created: {target_user.created_at}')
else:
    print('❌ User NOT found in auth.users')

print()
print('='*100)
print('📊 DIAGNOSIS:')
print('='*100)

if response.data and target_user:
    print('✅ User exists in BOTH tables - should be able to login')
    print('💡 Try logging in with correct password')
elif not response.data and target_user:
    print('❌ PROBLEM: User exists in auth.users but NOT in public.users')
    print('💡 SOLUTION: Need to create user record in public.users table')
    print('   This usually happens automatically via database trigger')
    print('   Check if trigger \"on_auth_user_created\" exists and is working')
elif response.data and not target_user:
    print('❌ PROBLEM: User exists in public.users but NOT in auth.users')
    print('   This should not happen normally')
else:
    print('❌ PROBLEM: User does not exist in either table')

print('='*100)
