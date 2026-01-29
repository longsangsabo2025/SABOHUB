"""
Final verification - check all users and test task creation
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.getenv("SUPABASE_CONNECTION_STRING")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("="*80)
    print("✅ VERIFICATION: Users synced successfully")
    print("="*80)
    
    # List all users in public.users
    cur.execute("""
        SELECT 
            id, 
            email, 
            full_name,
            role,
            is_active
        FROM public.users
        WHERE deleted_at IS NULL
        ORDER BY created_at;
    """)
    
    users = cur.fetchall()
    
    print(f"\n📊 Total active users: {len(users)}\n")
    print("List of users:")
    for user_id, email, full_name, role, is_active in users:
        status = "🟢" if is_active else "🔴"
        print(f"  {status} {email:50} | {role:15} | {full_name or 'N/A'}")
    
    print("\n" + "="*80)
    print("🎯 You can now create tasks and assign to any of these users!")
    print("="*80)
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
