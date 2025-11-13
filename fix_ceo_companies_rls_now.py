#!/usr/bin/env python3
"""
Fix CEO Companies RLS Policy - Direct execution via pooler
"""

import os
from dotenv import load_dotenv
import psycopg2

# Load environment variables
load_dotenv()

# Get connection string
conn_string = os.environ.get("SUPABASE_CONNECTION_STRING")

print("=" * 80)
print("🔧 FIXING CEO COMPANIES RLS POLICY")
print("=" * 80)

try:
    # Connect to database
    print("\n1️⃣ Connecting to database...")
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    print("   ✅ Connected successfully")

    # Drop old policies
    print("\n2️⃣ Dropping old policies...")
    drop_queries = [
        'DROP POLICY IF EXISTS "companies_select_policy" ON companies;',
        'DROP POLICY IF EXISTS "CEO can view all companies" ON companies;',
        'DROP POLICY IF EXISTS "Allow authenticated users to select companies" ON companies;',
    ]
    
    for query in drop_queries:
        try:
            cursor.execute(query)
            conn.commit()
            print(f"   ✅ Executed: {query[:50]}...")
        except Exception as e:
            print(f"   ⚠️  Warning: {e}")
            conn.rollback()

    # Create new policy
    print("\n3️⃣ Creating new SELECT policy...")
    create_policy_sql = """
    CREATE POLICY "companies_select_policy"
    ON companies
    FOR SELECT
    TO authenticated
    USING (
      -- CEO can see ALL companies
      EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = 'CEO'
      )
      OR
      -- Other users can see their own company
      EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.company_id = companies.id
      )
    );
    """
    
    cursor.execute(create_policy_sql)
    conn.commit()
    print("   ✅ Policy created successfully!")

    # Verify policy
    print("\n4️⃣ Verifying policy...")
    cursor.execute("""
        SELECT policyname, cmd, permissive
        FROM pg_policies 
        WHERE tablename = 'companies'
        ORDER BY policyname;
    """)
    
    policies = cursor.fetchall()
    print(f"   Found {len(policies)} policies on companies table:")
    for policy in policies:
        print(f"   - {policy[0]} (CMD: {policy[1]}, Permissive: {policy[2]})")

    # Test query
    print("\n5️⃣ Testing query (as service role)...")
    cursor.execute("""
        SELECT id, name, is_active, deleted_at
        FROM companies
        WHERE deleted_at IS NULL
        ORDER BY created_at DESC;
    """)
    
    companies = cursor.fetchall()
    print(f"   ✅ Found {len(companies)} companies:")
    for company in companies:
        print(f"   - {company[1]} (ID: {company[0][:8]}..., Active: {company[2]})")

    cursor.close()
    conn.close()

    print("\n" + "=" * 80)
    print("✅ SUCCESS! RLS POLICY FIXED")
    print("=" * 80)
    print("""
🎯 Next steps:
1. Refresh your app in Chrome (F5)
2. Login as CEO
3. Go to Companies tab
4. You should now see the companies list!

📝 If CEO still cannot see companies:
- Check that CEO user has role = 'CEO' in users table
- Check browser console for any errors
- Try logging out and logging in again
    """)

except Exception as e:
    print(f"\n❌ ERROR: {e}")
    print(f"\n💡 Tip: Make sure PostgreSQL connection string is correct")
    import traceback
    traceback.print_exc()
