"""
Tạo RPC function để hash password khi CEO tạo employee
"""
import psycopg2

# Transaction pooler connection
CONN_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 80)
print("📦 CREATING RPC FUNCTION: create_employee_with_password")
print("=" * 80)

# Read SQL file
with open('create_employee_with_password_rpc.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

conn = psycopg2.connect(CONN_STRING)
cur = conn.cursor()

try:
    print("\n🔧 Executing SQL...")
    cur.execute(sql)
    conn.commit()
    print("✅ RPC function created successfully!")
    
    print("\n📋 Verifying function exists...")
    cur.execute("""
        SELECT 
            proname as function_name,
            pg_get_function_arguments(oid) as arguments
        FROM pg_proc
        WHERE proname = 'create_employee_with_password';
    """)
    
    result = cur.fetchone()
    if result:
        func_name, args = result
        print(f"✅ Function found: {func_name}")
        print(f"   Arguments: {args}")
    else:
        print("❌ Function not found!")
        
except Exception as e:
    conn.rollback()
    print(f"❌ Error: {e}")
    
finally:
    cur.close()
    conn.close()

print("\n" + "=" * 80)
print("✅ DONE")
print("=" * 80)
print("""
📝 HOW TO USE IN FLUTTER:

final result = await supabase.rpc('create_employee_with_password', params: {
  'p_email': 'staff@company.com',
  'p_password': 'temp123',
  'p_full_name': 'Nguyễn Văn A',
  'p_role': 'STAFF',
  'p_company_id': companyId,
  'p_is_active': true,
}).select();
""")
