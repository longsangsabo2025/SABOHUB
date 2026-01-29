#!/usr/bin/env python3
"""
Check CEO companies issue - why CEO doesn't see companies in UI
"""

import os
from dotenv import load_dotenv
from supabase import create_client

# Load environment variables
load_dotenv()

# Initialize Supabase client
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

print("=" * 80)
print("🔍 CHECKING CEO COMPANIES ISSUE")
print("=" * 80)

# 1. Check companies in database
print("\n1️⃣ Companies in database:")
companies = supabase.table('companies').select('*').execute()
print(f"   Total companies: {len(companies.data)}")
for company in companies.data[:5]:
    print(f"   - {company.get('name')} (ID: {company['id']})")
    print(f"     Active: {company.get('is_active')}, Deleted: {company.get('deleted_at')}")

# 2. Check CEO users
print("\n2️⃣ CEO users in database:")
ceos = supabase.table('users').select('*').eq('role', 'CEO').execute()
print(f"   Total CEOs: {len(ceos.data)}")
for ceo in ceos.data:
    print(f"   - {ceo.get('full_name')} ({ceo.get('email')})")
    print(f"     Company ID: {ceo.get('company_id')}")
    print(f"     User ID: {ceo.get('id')}")

# 3. Check RLS policies on companies table
print("\n3️⃣ RLS Policies on companies table:")
policies_query = """
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'companies'
ORDER BY policyname;
"""
try:
    policies = supabase.rpc('exec_sql', {'query': policies_query}).execute()
    print(f"   Policies: {policies}")
except Exception as e:
    print(f"   Cannot query policies directly: {e}")
    print("   Need to check in Supabase dashboard")

# 4. Test CEO login and query companies
print("\n4️⃣ Testing CEO authentication:")
ceo_email = "longsangsabo@gmail.com"
ceo_password = "Acookingoil123"

try:
    # Try to sign in as CEO
    auth_response = supabase.auth.sign_in_with_password({
        "email": ceo_email,
        "password": ceo_password
    })
    
    if auth_response.user:
        print(f"   ✅ CEO logged in: {auth_response.user.email}")
        print(f"   User ID: {auth_response.user.id}")
        
        # Try to query companies as CEO
        print("\n5️⃣ Querying companies as CEO:")
        try:
            companies_as_ceo = supabase.table('companies').select('*').execute()
            print(f"   Companies visible to CEO: {len(companies_as_ceo.data)}")
            for company in companies_as_ceo.data[:3]:
                print(f"   - {company.get('name')}")
        except Exception as e:
            print(f"   ❌ ERROR querying companies: {e}")
            print(f"   This is the problem! RLS is blocking CEO from seeing companies")
    else:
        print(f"   ❌ CEO login failed")
        
except Exception as e:
    print(f"   ❌ Authentication error: {e}")

print("\n" + "=" * 80)
print("🎯 DIAGNOSIS:")
print("=" * 80)
print("""
If CEO can login but cannot see companies, the issue is likely:

1. RLS Policy Problem: 
   - companies table has RLS enabled
   - But no policy allows CEO to SELECT companies
   - Need to add policy: "Allow CEO to select all companies"

2. Possible Fix:
   Run this SQL in Supabase SQL Editor:
   
   CREATE POLICY "CEO can view all companies"
   ON companies
   FOR SELECT
   TO authenticated
   USING (
     EXISTS (
       SELECT 1 FROM users 
       WHERE users.id = auth.uid() 
       AND users.role = 'CEO'
     )
   );
""")
