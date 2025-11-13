"""
Check and fix RLS policies for users table
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print("\n" + "="*80)
print("CHECKING RLS POLICIES ON USERS TABLE")
print("="*80)

# Check current RLS policies
cursor.execute("""
    SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
    FROM pg_policies 
    WHERE tablename = 'users'
    ORDER BY policyname;
""")

policies = cursor.fetchall()

if policies:
    print(f"\n📋 Found {len(policies)} RLS policies on users table:")
    for policy in policies:
        print(f"\n  Policy: {policy[2]}")
        print(f"    Command: {policy[5]}")
        print(f"    Roles: {policy[4]}")
        print(f"    Using: {policy[6]}")
else:
    print("\n⚠️  No RLS policies found on users table")

# Check if RLS is enabled
cursor.execute("""
    SELECT relname, relrowsecurity 
    FROM pg_class 
    WHERE relname = 'users' AND relnamespace = 'public'::regnamespace;
""")

rls_status = cursor.fetchone()
if rls_status:
    print(f"\n🔐 RLS Status: {'ENABLED' if rls_status[1] else 'DISABLED'}")

# Create policy to allow authenticated users to read their own data
print("\n" + "="*80)
print("FIXING RLS POLICIES")
print("="*80)

try:
    # Drop existing problematic policies
    print("\n🗑️  Dropping old policies...")
    cursor.execute("DROP POLICY IF EXISTS users_select_own ON users;")
    cursor.execute("DROP POLICY IF EXISTS users_select_policy ON users;")
    cursor.execute("DROP POLICY IF EXISTS company_users_select ON users;")
    
    # Create new policy: Users can read users from same company
    print("✅ Creating new policy: company_users_select...")
    cursor.execute("""
        CREATE POLICY company_users_select ON users
        FOR SELECT
        USING (
            company_id IN (
                SELECT company_id FROM users WHERE id = auth.uid()
            )
            OR id = auth.uid()
        );
    """)
    
    # Create policy: Users can update their own data
    print("✅ Creating policy: users_update_own...")
    cursor.execute("""
        CREATE POLICY users_update_own ON users
        FOR UPDATE
        USING (id = auth.uid())
        WITH CHECK (id = auth.uid());
    """)
    
    conn.commit()
    print("\n✅ RLS policies updated successfully!")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    conn.rollback()

# Verify new policies
cursor.execute("""
    SELECT policyname, cmd 
    FROM pg_policies 
    WHERE tablename = 'users'
    ORDER BY policyname;
""")

new_policies = cursor.fetchall()
print(f"\n📋 Current policies ({len(new_policies)}):")
for policy in new_policies:
    print(f"  ✅ {policy[0]} ({policy[1]})")

cursor.close()
conn.close()

print("\n" + "="*80)
print("✅ RLS FIX COMPLETE!")
print("="*80 + "\n")
