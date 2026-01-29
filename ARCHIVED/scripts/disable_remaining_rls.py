"""
Disable RLS cho các bảng còn lại: companies, users, branches, ai_messages, ai_uploaded_files
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

if not conn_string:
    print("❌ ERROR: SUPABASE_CONNECTION_STRING not found in .env")
    exit(1)

def disable_remaining_tables():
    """Disable RLS for remaining tables"""
    print("\n" + "="*70)
    print("🔧 DISABLING RLS FOR REMAINING TABLES")
    print("="*70)
    
    # Tables that still have RLS enabled
    remaining_tables = [
        'companies',        # ← QUAN TRỌNG NHẤT!
        'users',
        'branches',
        'ai_messages',
        'ai_uploaded_files',
        'management_tasks',  # Thêm vào để chắc chắn
    ]
    
    try:
        conn = psycopg2.connect(conn_string, connect_timeout=10)
        cur = conn.cursor()
        print("✅ Connected to database\n")
        
        print("1️⃣ Disabling RLS...")
        success_count = 0
        for table in remaining_tables:
            try:
                cur.execute(f"ALTER TABLE {table} DISABLE ROW LEVEL SECURITY;")
                conn.commit()
                print(f"   ✅ {table}")
                success_count += 1
            except Exception as e:
                conn.rollback()
                error_msg = str(e)[:100]
                if "does not exist" in error_msg:
                    print(f"   ⚠️  {table}: Table không tồn tại")
                else:
                    print(f"   ⚠️  {table}: {error_msg}")
        
        print(f"\n   Disabled {success_count}/{len(remaining_tables)} tables")
        
        # Verify final status
        print("\n2️⃣ Verifying final RLS status...")
        cur.execute("""
            SELECT 
                tablename,
                CASE WHEN rowsecurity THEN '🔒 ENABLED' ELSE '✅ DISABLED' END as status
            FROM pg_tables 
            WHERE schemaname = 'public' 
              AND tablename IN ('companies', 'users', 'branches', 'ai_messages', 
                                'ai_uploaded_files', 'management_tasks')
            ORDER BY tablename;
        """)
        
        results = cur.fetchall()
        all_disabled = True
        for table, status in results:
            print(f"   {status} {table}")
            if '🔒' in status:
                all_disabled = False
        
        cur.close()
        conn.close()
        
        print("\n" + "="*70)
        if all_disabled:
            print("✅ SUCCESS! ALL TABLES NOW HAVE RLS DISABLED!")
            print("="*70)
            print("\n📱 NEXT STEPS:")
            print("   1. Press 'R' in Flutter terminal to hot reload")
            print("   2. Open dialog 'Tạo nhiệm vụ mới'")
            print("   3. Dropdown 'Công ty' should show 'SABO Billiards' ✅")
        else:
            print("⚠️  SOME TABLES STILL HAVE RLS ENABLED")
            print("="*70)
            print("\nBạn có thể cần chạy SQL trực tiếp trên Supabase Dashboard:")
            print("https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/sql/new")
        
        print("\n⚠️  REMEMBER: This is DEVELOPMENT ONLY! Re-enable RLS before production!")
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        print("\nTry running this SQL directly in Supabase Dashboard:")
        print("\nALTER TABLE companies DISABLE ROW LEVEL SECURITY;")
        print("ALTER TABLE users DISABLE ROW LEVEL SECURITY;")
        print("ALTER TABLE branches DISABLE ROW LEVEL SECURITY;")
        print("ALTER TABLE ai_messages DISABLE ROW LEVEL SECURITY;")
        print("ALTER TABLE ai_uploaded_files DISABLE ROW LEVEL SECURITY;")
        print("ALTER TABLE management_tasks DISABLE ROW LEVEL SECURITY;")

if __name__ == '__main__':
    disable_remaining_tables()
