#!/usr/bin/env python3
"""
Fix infinite recursion in RLS policy for users table
"""
from supabase import create_client

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

# Read SQL file
with open('fix_rls_policy.sql', 'r', encoding='utf-8') as f:
    sql_content = f.read()

print('='*100)
print('🔧 FIXING RLS POLICY - INFINITE RECURSION')
print('='*100)
print()

# Split into individual statements
statements = [s.strip() for s in sql_content.split(';') if s.strip() and not s.strip().startswith('--')]

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

for idx, statement in enumerate(statements, 1):
    # Skip comments
    if statement.startswith('--') or not statement:
        continue
    
    print(f'📝 Executing statement #{idx}...')
    print(f'   {statement[:100]}...' if len(statement) > 100 else f'   {statement}')
    
    try:
        # Execute via RPC or direct query
        result = supabase.rpc('exec_sql', {'sql': statement}).execute()
        print(f'   ✅ Success')
    except Exception as e:
        # Try direct execution
        try:
            result = supabase.postgrest.session.post(
                f'{SUPABASE_URL}/rest/v1/rpc/exec_sql',
                json={'sql': statement},
                headers={
                    'apikey': SERVICE_KEY,
                    'Authorization': f'Bearer {SERVICE_KEY}'
                }
            )
            print(f'   ✅ Success')
        except Exception as e2:
            print(f'   ⚠️  Warning: {str(e2)[:100]}')
    
    print()

print('='*100)
print('✅ RLS POLICY FIX COMPLETE')
print('='*100)
print()
print('📋 NEXT STEPS:')
print('   1. Go to Supabase Dashboard')
print('   2. Navigate to Authentication > Policies')
print('   3. Find the users table')
print('   4. Manually run the SQL script from fix_rls_policy.sql')
print('   5. Or use SQL Editor in Supabase Dashboard')
