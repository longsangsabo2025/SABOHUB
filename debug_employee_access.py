import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

url = os.getenv('SUPABASE_URL')
service_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase: Client = create_client(url, service_key)

print("=" * 60)
print("🔍 DEBUGGING EMPLOYEE DIỄM ACCESS ISSUES")
print("=" * 60)

# 1. Check Diễm's employee record
print("\n1️⃣ Checking Diễm's employee record...")
diem_response = supabase.table('employees').select('*').eq('email', 'diem@sabohub.com').execute()
if diem_response.data:
    diem = diem_response.data[0]
    print(f"✅ Found: {diem['full_name']}")
    print(f"   ID: {diem['id']}")
    print(f"   Role: {diem['role']}")
    print(f"   Company ID: {diem['company_id']}")
    print(f"   User ID: {diem.get('user_id')}")
    diem_id = diem['id']
    company_id = diem['company_id']
else:
    print("❌ Employee not found!")
    exit()

# 2. Check company record
print(f"\n2️⃣ Checking company record (ID: {company_id})...")
company_response = supabase.table('companies').select('*').eq('id', company_id).execute()
if company_response.data:
    company = company_response.data[0]
    print(f"✅ Company: {company['name']}")
    print(f"   Is Active: {company['is_active']}")
    print(f"   CEO ID: {company.get('ceo_id')}")
else:
    print("❌ Company not found!")

# 3. Check RLS policies on companies table
print("\n3️⃣ Checking RLS policies on companies table...")
rls_query = """
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'companies'
ORDER BY policyname;
"""
try:
    import psycopg2
    conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    cur.execute(rls_query)
    policies = cur.fetchall()
    
    if policies:
        print(f"📋 Found {len(policies)} RLS policies:")
        for policy in policies:
            print(f"\n   Policy: {policy[2]}")
            print(f"   Command: {policy[5]}")
            print(f"   Roles: {policy[4]}")
            print(f"   Using: {policy[6]}")
    else:
        print("⚠️ No RLS policies found on companies table")
    
    cur.close()
    conn.close()
except Exception as e:
    print(f"❌ Error checking RLS: {e}")

# 4. Check tasks with assigned_to = Diễm
print(f"\n4️⃣ Checking tasks assigned to Diễm...")
try:
    tasks_response = supabase.table('tasks').select('id, title, assigned_to').eq('assigned_to', diem_id).limit(5).execute()
    print(f"✅ Found {len(tasks_response.data)} tasks assigned to Diễm")
    for task in tasks_response.data[:3]:
        print(f"   - {task['title']}")
except Exception as e:
    print(f"❌ Error fetching tasks: {e}")

# 5. Test the exact query that's failing
print("\n5️⃣ Testing the failing tasks query...")
try:
    tasks_query = supabase.table('tasks').select('id, title, status, created_at, assigned_to, employees(full_name)').order('created_at', desc=True).limit(10)
    tasks_result = tasks_query.execute()
    print(f"✅ Query successful! Got {len(tasks_result.data)} tasks")
except Exception as e:
    print(f"❌ Query failed: {e}")
    print("\n   Trying simpler query without join...")
    try:
        simple_query = supabase.table('tasks').select('id, title, status, created_at, assigned_to').order('created_at', desc=True).limit(10)
        simple_result = simple_query.execute()
        print(f"   ✅ Simple query works! Got {len(simple_result.data)} tasks")
    except Exception as e2:
        print(f"   ❌ Even simple query failed: {e2}")

# 6. Check foreign key relationship
print("\n6️⃣ Checking tasks table structure...")
try:
    import psycopg2
    conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # Check if foreign key exists
    fk_query = """
    SELECT
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'tasks'
        AND kcu.column_name = 'assigned_to';
    """
    cur.execute(fk_query)
    fk_result = cur.fetchall()
    
    if fk_result:
        print("✅ Foreign key exists:")
        for fk in fk_result:
            print(f"   {fk[2]} → {fk[3]}.{fk[4]}")
    else:
        print("⚠️ No foreign key found for assigned_to column")
    
    cur.close()
    conn.close()
except Exception as e:
    print(f"❌ Error checking FK: {e}")

print("\n" + "=" * 60)
print("🏁 DIAGNOSIS COMPLETE")
print("=" * 60)
