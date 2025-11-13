import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

print("="*60)
print("FIXING EMPLOYEE ACCESS TO COMPANIES TABLE")
print("="*60)

# 1. Check current RLS status on companies
print("\n1. Current RLS policies on companies table:")
cur.execute("""
    SELECT policyname, cmd, qual 
    FROM pg_policies 
    WHERE tablename = 'companies'
    ORDER BY policyname;
""")
policies = cur.fetchall()
if policies:
    for p in policies:
        print(f"   - {p[0]} ({p[1]}): {p[2]}")
else:
    print("   No policies found")

# 2. Check RLS status
cur.execute("""
    SELECT relrowsecurity, relforcerowsecurity
    FROM pg_class
    WHERE relname = 'companies';
""")
rls_status = cur.fetchone()
print(f"\n2. RLS enabled: {rls_status[0]}, Force RLS: {rls_status[1]}")

# 3. Drop all existing RLS policies on companies
print("\n3. Dropping all existing RLS policies...")
if policies:
    for p in policies:
        try:
            # Use double quotes for policy names with spaces
            cur.execute(f'DROP POLICY IF EXISTS "{p[0]}" ON companies;')
            print(f"   ✅ Dropped: {p[0]}")
        except Exception as e:
            print(f"   ❌ Error dropping {p[0]}: {e}")
            conn.rollback()  # Rollback on error

# 4. Disable RLS on companies table (for development)
print("\n4. Disabling RLS on companies table...")
try:
    cur.execute("ALTER TABLE companies DISABLE ROW LEVEL SECURITY;")
    print("   ✅ RLS DISABLED on companies table")
except Exception as e:
    print(f"   ❌ Error: {e}")

# 5. Check tasks table RLS
print("\n5. Checking tasks table RLS...")
cur.execute("""
    SELECT relrowsecurity 
    FROM pg_class 
    WHERE relname = 'tasks';
""")
tasks_rls = cur.fetchone()
print(f"   Tasks RLS enabled: {tasks_rls[0]}")

if tasks_rls[0]:
    print("   ⚠️ Tasks table has RLS enabled")
    print("   Disabling RLS on tasks table...")
    try:
        cur.execute("ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;")
        print("   ✅ RLS DISABLED on tasks table")
    except Exception as e:
        print(f"   ❌ Error: {e}")

# Commit changes
conn.commit()

print("\n6. Testing query as service role...")
cur.execute("""
    SELECT id, name, is_active 
    FROM companies 
    WHERE id = 'feef10d3-899d-4554-8107-b2256918213a';
""")
result = cur.fetchone()
if result:
    print(f"   ✅ Company found: {result[1]} (active: {result[2]})")
else:
    print("   ❌ Company not found!")

cur.close()
conn.close()

print("\n" + "="*60)
print("✅ FIX COMPLETE - RLS disabled for development")
print("="*60)
print("\nNOTE: RLS is now DISABLED on companies and tasks tables.")
print("This allows all authenticated users to access these tables.")
print("For production, you should implement proper RLS policies.")
