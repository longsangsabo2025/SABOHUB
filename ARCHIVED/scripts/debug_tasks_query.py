import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

print("=" * 80)
print("CHECK TASKS FOR MANAGER DIEM")
print("=" * 80)

# Manager Diem's employee_id
diem_id = '61715a20-dc93-480c-9dab-f21806114887'
company_id = 'feef10d3-899d-4554-8107-b2256918213a'

# Check all tasks in company
cur.execute("""
    SELECT 
        t.id,
        t.title,
        t.status,
        t.assigned_to,
        t.assigned_to_name,
        t.assigned_to_role,
        t.created_by,
        t.created_by_name,
        t.deleted_at,
        e.full_name as assigned_employee_name,
        e.role as assigned_employee_role
    FROM tasks t
    LEFT JOIN employees e ON t.assigned_to = e.id
    WHERE t.company_id = %s
    AND t.deleted_at IS NULL
    ORDER BY t.created_at DESC
""", (company_id,))

tasks = cur.fetchall()

print(f"\nTotal tasks in company: {len(tasks)}")
print("\nAll tasks:")
for i, task in enumerate(tasks, 1):
    print(f"\n{i}. {task[1]} (ID: {task[0][:8]}...)")
    print(f"   Status: {task[2]}")
    print(f"   Assigned to ID: {task[3]}")
    print(f"   assigned_to_name (DB): {task[4] if task[4] else '❌ NULL'}")
    print(f"   assigned_to_role (DB): {task[5] if task[5] else '❌ NULL'}")
    print(f"   created_by_name (DB): {task[7] if task[7] else '❌ NULL'}")
    print(f"   assigned_employee_name (JOIN): {task[9] if task[9] else '❌ NULL'}")
    print(f"   assigned_employee_role (JOIN): {task[10] if task[10] else '❌ NULL'}")
    
    if task[3] == diem_id:
        print(f"   >>> ✅ ASSIGNED TO DIEM!")

# Check if foreign keys exist
print("\n" + "=" * 80)
print("CHECK FOREIGN KEY CONSTRAINTS")
print("=" * 80)

cur.execute("""
    SELECT
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'tasks'
    AND (kcu.column_name = 'assigned_to' OR kcu.column_name = 'created_by')
""")

fks = cur.fetchall()
print(f"\nForeign keys on tasks table:")
for fk in fks:
    print(f"  {fk[0]}")
    print(f"    {fk[1]}.{fk[2]} -> {fk[3]}.{fk[4]}")

# Check RLS status
print("\n" + "=" * 80)
print("CHECK RLS STATUS")
print("=" * 80)

cur.execute("""
    SELECT tablename, rowsecurity 
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename IN ('tasks', 'employees', 'companies')
    ORDER BY tablename
""")

rls_status = cur.fetchall()
for table, enabled in rls_status:
    status = "✅ ENABLED" if enabled else "❌ DISABLED"
    print(f"  {table}: {status}")

cur.close()
conn.close()

print("\n" + "=" * 80)
print("DIAGNOSIS COMPLETE")
print("=" * 80)
