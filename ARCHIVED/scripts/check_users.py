from supabase import create_client

SUPABASE_URL = 'https://dqddxowyikefqcdiioyh.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('='*100)
print('🔍 CHECKING USERS IN SUPABASE (ADMIN ACCESS)')
print('='*100)
print()

# Check auth.users
print('🔐 AUTH.USERS TABLE:')
print('-'*100)
response = supabase.auth.admin.list_users()

if response and len(response) > 0:
    print(f'✅ Found {len(response)} users\n')
    
    for idx, user in enumerate(response, 1):
        verified = '✅ VERIFIED' if user.email_confirmed_at else '❌ NOT VERIFIED'
        print(f'👤 User #{idx}')
        print(f'   Email: {user.email}')
        print(f'   Status: {verified}')
        print(f'   Confirmed At: {user.email_confirmed_at or 'PENDING'}')
        print(f'   Last Sign In: {user.last_sign_in_at or 'Never'}')
        print(f'   Created: {user.created_at}')
        print()
    
    verified_count = sum(1 for u in response if u.email_confirmed_at)
    print(f'📊 SUMMARY: {verified_count}/{len(response)} verified')
else:
    print('⚠️ No users found')

print('='*100)
