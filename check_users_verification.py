#!/usr/bin/env python3#!/usr/bin/env python3

""""""

Script to check user verification status in Supabase using Service Role KeyScript to check user verification status in Supabase

""""""

from supabase import create_client, Clientimport os

from datetime import datetimefrom supabase import create_client, Client

from datetime import datetime

# Supabase credentials with SERVICE ROLE KEY (full admin access)

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"# Supabase credentials

SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"

SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y"

def check_users():

    """Check users verification status with full admin access"""def check_users():

    try:    """Check users verification status"""

        # Initialize Supabase client with SERVICE ROLE KEY    try:

        supabase: Client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)        # Initialize Supabase client

                supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

        print("=" * 100)        

        print("🔍 CHECKING USERS TABLE IN SUPABASE (ADMIN ACCESS)")        print("=" * 80)

        print("=" * 100)        print("🔍 CHECKING USERS TABLE IN SUPABASE")

        print()        print("=" * 80)

                print()

        # Check public.users table        

        print("📋 1. CHECKING PUBLIC.USERS TABLE")        # Query users from auth.users (using RPC or direct query)

        print("-" * 100)        # Note: We need to check both 'users' table and 'auth.users'

        try:        

            response = supabase.table('users').select('*').order('created_at', desc=True).execute()        # First, try to get from public.users table

            users = response.data        print("📋 Checking public.users table...")

                    try:

            if users:            response = supabase.table('users').select('*').execute()

                print(f"✅ Found {len(users)} users in public.users table\n")            users = response.data

                            

                for idx, user in enumerate(users, 1):            if users:

                    print(f"👤 User #{idx}")                print(f"✅ Found {len(users)} users in public.users table\n")

                    print(f"   ├─ ID: {user.get('id', 'N/A')}")                

                    print(f"   ├─ Email: {user.get('email', 'N/A')}")                for idx, user in enumerate(users, 1):

                    print(f"   ├─ Role: {user.get('role', 'N/A')}")                    print(f"👤 User #{idx}")

                    print(f"   ├─ Full Name: {user.get('full_name', 'N/A')}")                    print(f"   ID: {user.get('id', 'N/A')}")

                    print(f"   ├─ Email Verified: {'✅ YES' if user.get('email_verified') else '❌ NO'}")                    print(f"   Email: {user.get('email', 'N/A')}")

                    print(f"   ├─ Created At: {user.get('created_at', 'N/A')}")                    print(f"   Role: {user.get('role', 'N/A')}")

                    print(f"   └─ Updated At: {user.get('updated_at', 'N/A')}")                    print(f"   Full Name: {user.get('full_name', 'N/A')}")

                    print()                    print(f"   Email Verified: {user.get('email_verified', 'N/A')}")

            else:                    print(f"   Created At: {user.get('created_at', 'N/A')}")

                print("⚠️  No users found in public.users table")                    print(f"   Updated At: {user.get('updated_at', 'N/A')}")

                print()                    print()

        except Exception as e:            else:

            print(f"❌ Error querying public.users: {str(e)}")                print("⚠️  No users found in public.users table")

            print()                print()

                except Exception as e:

        # Check auth.users table with ADMIN ACCESS            print(f"❌ Error querying public.users: {str(e)}")

        print("🔐 2. CHECKING AUTH.USERS TABLE (AUTHENTICATION)")            print()

        print("-" * 100)        

        try:        # Try to get auth users count (if we have access)

            # Use admin API to list all users        print("🔐 Checking auth.users (authentication table)...")

            response = supabase.auth.admin.list_users()        try:

                        # Use Supabase Admin API to list users

            if response and len(response) > 0:            # Note: This requires service_role key for full access

                auth_users = response            auth_response = supabase.auth.admin.list_users()

                print(f"✅ Found {len(auth_users)} users in auth.users\n")            

                            if hasattr(auth_response, 'users') and auth_response.users:

                for idx, user in enumerate(auth_users, 1):                print(f"✅ Found {len(auth_response.users)} users in auth.users\n")

                    email_verified = user.email_confirmed_at is not None                

                                    for idx, user in enumerate(auth_response.users, 1):

                    print(f"👤 Auth User #{idx}")                    print(f"👤 Auth User #{idx}")

                    print(f"   ├─ ID: {user.id}")                    print(f"   ID: {user.id}")

                    print(f"   ├─ Email: {user.email}")                    print(f"   Email: {user.email}")

                    print(f"   ├─ Email Confirmed: {'✅ YES' if email_verified else '❌ NO (PENDING)'}")                    print(f"   Email Confirmed: {user.email_confirmed_at is not None}")

                    print(f"   ├─ Confirmed At: {user.email_confirmed_at or '❌ NOT VERIFIED YET'}")                    print(f"   Email Confirmed At: {user.email_confirmed_at or 'NOT VERIFIED'}")

                    print(f"   ├─ Last Sign In: {user.last_sign_in_at or '⚠️  Never signed in'}")                    print(f"   Last Sign In: {user.last_sign_in_at or 'Never'}")

                    print(f"   ├─ Phone: {user.phone or 'N/A'}")                    print(f"   Created At: {user.created_at}")

                    print(f"   ├─ Created At: {user.created_at}")                    print()

                    print(f"   └─ Updated At: {user.updated_at}")            else:

                                    print("⚠️  No users found in auth.users or insufficient permissions")

                    # Show metadata if exists                print("   (This is expected with anon key - need service_role key)")

                    if hasattr(user, 'user_metadata') and user.user_metadata:                print()

                        print(f"   └─ Metadata: {user.user_metadata}")        except Exception as e:

                                print(f"⚠️  Cannot access auth.users with anon key: {str(e)}")

                    print()            print("   This is expected - anon key has limited permissions")

                            print()

                # Summary        

                verified_count = sum(1 for u in auth_users if u.email_confirmed_at is not None)        print("=" * 80)

                unverified_count = len(auth_users) - verified_count        print("✅ CHECK COMPLETE")

                        print("=" * 80)

                print("📊 SUMMARY:")        

                print(f"   ├─ Total Users: {len(auth_users)}")    except Exception as e:

                print(f"   ├─ ✅ Verified: {verified_count}")        print(f"❌ Error: {str(e)}")

                print(f"   └─ ❌ Unverified: {unverified_count}")        import traceback

                print()        traceback.print_exc()

                

            else:if __name__ == "__main__":

                print("⚠️  No users found in auth.users")    check_users()

                print()
        except Exception as e:
            print(f"❌ Error querying auth.users: {str(e)}")
            import traceback
            traceback.print_exc()
            print()
        
        print("=" * 100)
        print("✅ CHECK COMPLETE")
        print("=" * 100)
        
    except Exception as e:
        print(f"❌ Fatal Error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # Check if supabase library is installed
    try:
        import supabase
        check_users()
    except ImportError:
        print("❌ Error: 'supabase' library not installed")
        print("📦 Install it with: pip install supabase")
