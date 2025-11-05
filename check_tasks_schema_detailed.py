"""
Kiểm tra schema của bảng tasks để xem company_id
"""
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get Supabase credentials from .env
SUPABASE_URL = os.getenv('SUPABASE_URL')
CONNECTION_STRING = os.getenv('SUPABASE_CONNECTION_STRING')

if not CONNECTION_STRING:
    print("❌ Không tìm thấy SUPABASE_CONNECTION_STRING trong .env")
    sys.exit(1)

try:
    import psycopg2
    from psycopg2 import sql
except ImportError:
    print("❌ Chưa cài psycopg2. Đang cài...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    import psycopg2
    from psycopg2 import sql

print("🔍 Kiểm tra schema bảng tasks...")
print("=" * 70)

try:
    # Connect to database
    conn = psycopg2.connect(CONNECTION_STRING)
    cur = conn.cursor()
    
    # Get column info for tasks table
    cur.execute("""
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_name = 'tasks'
        ORDER BY ordinal_position;
    """)
    
    print("\n📋 Cấu trúc bảng 'tasks':")
    print("-" * 70)
    print(f"{'Column':<25} {'Type':<15} {'Nullable':<10} {'Default':<20}")
    print("-" * 70)
    
    for row in cur.fetchall():
        column_name, data_type, is_nullable, column_default = row
        nullable = "YES" if is_nullable == "YES" else "NO"
        default = column_default if column_default else ""
        print(f"{column_name:<25} {data_type:<15} {nullable:<10} {default:<20}")
    
    # Check triggers on tasks table
    print("\n\n🔧 Triggers trên bảng 'tasks':")
    print("-" * 70)
    cur.execute("""
        SELECT 
            trigger_name,
            event_manipulation,
            action_statement
        FROM information_schema.triggers
        WHERE event_object_table = 'tasks';
    """)
    
    triggers = cur.fetchall()
    if triggers:
        for trigger in triggers:
            print(f"\nTrigger: {trigger[0]}")
            print(f"Event: {trigger[1]}")
            print(f"Action: {trigger[2][:100]}...")
    else:
        print("Không có trigger nào")
    
    # Check RLS policies
    print("\n\n🔐 RLS Policies trên bảng 'tasks':")
    print("-" * 70)
    cur.execute("""
        SELECT 
            polname as policy_name,
            polcmd as command,
            polpermissive as permissive,
            polroles::regrole[] as roles,
            qual as using_expression,
            with_check as with_check_expression
        FROM pg_policy
        WHERE polrelid = 'tasks'::regclass;
    """)
    
    policies = cur.fetchall()
    if policies:
        for policy in policies:
            print(f"\nPolicy: {policy[0]}")
            print(f"Command: {policy[1]}")
            print(f"Permissive: {policy[2]}")
    else:
        print("Không có policy nào (RLS có thể đã disabled)")
    
    cur.close()
    conn.close()
    
    print("\n" + "=" * 70)
    print("✅ Kiểm tra hoàn tất!")
    
except Exception as e:
    print(f"❌ Lỗi: {e}")
    import traceback
    traceback.print_exc()
