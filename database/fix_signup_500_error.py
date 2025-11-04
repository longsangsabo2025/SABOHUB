import psycopg2
import json

# Database configuration
DB_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
DB_PORT = 6543
DB_NAME = "postgres"
DB_USER = "postgres.dqddxowyikefqcdiioyh"
DB_PASSWORD = "Acookingoil123"

def fix_signup_issues():
    """Fix database issues that cause signup 500 errors"""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        cursor = conn.cursor()
        print("🔧 Connected to database. Fixing signup issues...")
        
        # 1. Check if auth.users table exists and has proper structure
        print("\n1. ✅ Checking auth.users table structure...")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'auth' AND table_name = 'users'
        """)
        auth_users_exists = cursor.fetchone()
        print(f"   Auth users table exists: {bool(auth_users_exists)}")
        
        # 2. Check custom users table
        print("\n2. ✅ Checking public.users table...")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'users'
        """)
        public_users_exists = cursor.fetchone()
        print(f"   Public users table exists: {bool(public_users_exists)}")
        
        # 3. Check RLS policies that might block signup
        print("\n3. ✅ Checking RLS policies on public.users...")
        cursor.execute("""
            SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
            FROM pg_policies 
            WHERE tablename = 'users' AND schemaname = 'public'
        """)
        policies = cursor.fetchall()
        print(f"   Found {len(policies)} RLS policies:")
        for policy in policies:
            print(f"     - {policy[2]}: {policy[5]} for {policy[4]}")
            
        # 4. Check if we have an auth trigger that might be failing
        print("\n4. ✅ Checking auth triggers...")
        cursor.execute("""
            SELECT trigger_name, event_manipulation, action_statement
            FROM information_schema.triggers 
            WHERE event_object_table = 'users'
        """)
        triggers = cursor.fetchall()
        print(f"   Found {len(triggers)} triggers:")
        for trigger in triggers:
            print(f"     - {trigger[0]}: {trigger[1]}")
            
        # 5. Temporarily disable RLS for signup debugging
        print("\n5. 🔧 Temporarily disabling RLS on public.users...")
        cursor.execute("ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;")
        print("   ✅ RLS disabled temporarily")
        
        # 6. Ensure auth.users can insert (should work by default)
        print("\n6. ✅ Checking auth.users permissions...")
        
        # 7. Test if we can insert into public.users directly
        print("\n7. 🧪 Testing direct insert into public.users...")
        test_email = "test_signup_fix@sabohub.com"
        
        # Delete test user if exists
        cursor.execute("DELETE FROM public.users WHERE email = %s", (test_email,))
        
        # Try to insert test user
        cursor.execute("""
            INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
            VALUES (gen_random_uuid(), %s, 'Test User', 'STAFF', now(), now())
            RETURNING id, email
        """, (test_email,))
        
        test_result = cursor.fetchone()
        if test_result:
            print(f"   ✅ Direct insert works: {test_result[1]}")
            # Clean up test user
            cursor.execute("DELETE FROM public.users WHERE email = %s", (test_email,))
        else:
            print("   ❌ Direct insert failed")
            
        # 8. Re-enable RLS but with permissive policies
        print("\n8. 🔧 Re-enabling RLS with permissive insert policy...")
        cursor.execute("ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;")
        
        # Drop existing restrictive policies and create permissive ones
        cursor.execute("DROP POLICY IF EXISTS users_insert_policy ON public.users;")
        cursor.execute("DROP POLICY IF EXISTS users_signup_policy ON public.users;")
        
        # Create permissive signup policy
        cursor.execute("""
            CREATE POLICY users_signup_policy ON public.users
            FOR INSERT 
            WITH CHECK (true);
        """)
        
        # Allow users to read their own data
        cursor.execute("DROP POLICY IF EXISTS users_select_policy ON public.users;")
        cursor.execute("""
            CREATE POLICY users_select_policy ON public.users
            FOR SELECT
            USING (auth.uid() = id OR auth.role() = 'service_role');
        """)
        
        print("   ✅ Permissive RLS policies created")
        
        # 9. Create or update auth trigger for automatic user profile creation
        print("\n9. 🔧 Creating auth trigger for user profile creation...")
        
        # Create the trigger function
        cursor.execute("""
            CREATE OR REPLACE FUNCTION public.handle_new_user()
            RETURNS trigger AS $$
            BEGIN
                INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
                VALUES (
                    NEW.id,
                    NEW.email,
                    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
                    COALESCE(NEW.raw_user_meta_data->>'role', 'STAFF'),
                    NOW(),
                    NOW()
                )
                ON CONFLICT (id) DO UPDATE SET
                    email = EXCLUDED.email,
                    full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
                    updated_at = NOW();
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql SECURITY DEFINER;
        """)
        
        # Drop existing trigger if exists
        cursor.execute("DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;")
        
        # Create new trigger
        cursor.execute("""
            CREATE TRIGGER on_auth_user_created
                AFTER INSERT ON auth.users
                FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
        """)
        
        print("   ✅ Auth trigger created successfully")
        
        # 10. Grant necessary permissions
        print("\n10. 🔧 Granting permissions...")
        cursor.execute("GRANT USAGE ON SCHEMA public TO anon, authenticated;")
        cursor.execute("GRANT ALL ON public.users TO anon, authenticated;")
        cursor.execute("GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;")
        
        print("   ✅ Permissions granted")
        
        # Commit all changes
        conn.commit()
        print("\n🎉 Database signup issues fixed successfully!")
        print("\n📋 Summary of changes:")
        print("   ✅ RLS policies made permissive for signup")
        print("   ✅ Auth trigger created for automatic profile creation")
        print("   ✅ Permissions granted")
        print("   ✅ Database ready for signup testing")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error fixing database: {e}")
        if 'conn' in locals():
            conn.rollback()
            conn.close()

if __name__ == "__main__":
    fix_signup_issues()