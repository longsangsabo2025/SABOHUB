"""
Sync users from auth.users to public.users
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.getenv("SUPABASE_CONNECTION_STRING")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("🔄 Syncing users from auth.users to public.users...")
    print("="*80)
    
    # First, check which auth.users are not in public.users
    cur.execute("""
        SELECT 
            au.id,
            au.email,
            au.created_at
        FROM auth.users au
        LEFT JOIN public.users pu ON au.id = pu.id
        WHERE pu.id IS NULL
        ORDER BY au.created_at;
    """)
    
    missing_users = cur.fetchall()
    
    if not missing_users:
        print("✅ All auth.users are already synced to public.users")
    else:
        print(f"📊 Found {len(missing_users)} users in auth.users that are NOT in public.users:")
        for user_id, email, created_at in missing_users:
            print(f"   - {email} (ID: {user_id})")
        
        print(f"\n🔧 Adding missing users to public.users...")
        
        # Insert missing users into public.users
        for user_id, email, created_at in missing_users:
            try:
                # Extract name from email (before @)
                full_name = email.split('@')[0].replace('.', ' ').title()
                
                # Determine role (default to 'STAFF' unless it's a known admin email)
                # Valid roles: CEO, MANAGER, SHIFT_LEADER, STAFF
                if 'longsangsabo1@gmail.com' == email:
                    role = 'CEO'
                elif 'longsangsabo' in email or 'ngocdiem' in email:
                    role = 'MANAGER'
                else:
                    role = 'STAFF'
                
                cur.execute("""
                    INSERT INTO public.users (
                        id, 
                        email, 
                        full_name, 
                        role, 
                        is_active,
                        created_at,
                        updated_at
                    ) VALUES (
                        %s, %s, %s, %s, true, %s, %s
                    )
                    ON CONFLICT (id) DO NOTHING;
                """, (user_id, email, full_name, role, created_at, created_at))
                
                print(f"   ✅ Added: {email} as {role}")
                
            except Exception as e:
                print(f"   ❌ Failed to add {email}: {str(e)}")
        
        conn.commit()
        print(f"\n✅ Successfully synced {len(missing_users)} users!")
    
    # Show final count
    cur.execute("SELECT COUNT(*) FROM public.users WHERE deleted_at IS NULL;")
    total_users = cur.fetchone()[0]
    
    cur.execute("SELECT COUNT(*) FROM auth.users;")
    total_auth_users = cur.fetchone()[0]
    
    print("\n" + "="*80)
    print("📊 FINAL COUNT:")
    print(f"   public.users (active): {total_users}")
    print(f"   auth.users: {total_auth_users}")
    
    if total_users == total_auth_users:
        print("   ✅ All users are now synced!")
    else:
        print(f"   ⚠️  Still missing {total_auth_users - total_users} users")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
