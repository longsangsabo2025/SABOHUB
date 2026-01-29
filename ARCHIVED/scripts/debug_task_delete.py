import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

conn = psycopg2.connect(os.getenv("SUPABASE_CONNECTION_STRING"))
cur = conn.cursor()

print("\n🔍 CHECKING TASKS AND RLS POLICIES\n")
print("=" * 80)

# 1. Check all tasks
print("\n1️⃣ ALL TASKS (including soft-deleted):\n")
cur.execute("""
    SELECT id, title, company_id, created_by, deleted_at, created_at
    FROM tasks
    ORDER BY created_at DESC
    LIMIT 5
""")

tasks = cur.fetchall()
for task in tasks:
    deleted_status = "❌ DELETED" if task[4] else "✅ ACTIVE"
    print(f"{deleted_status} | {task[1][:40]} | deleted_at: {task[4]}")

# 2. Check RLS policies on tasks
print("\n\n2️⃣ RLS POLICIES ON TASKS TABLE:\n")
cur.execute("""
    SELECT schemaname, tablename, policyname, cmd, qual, with_check
    FROM pg_policies
    WHERE tablename = 'tasks'
    ORDER BY policyname
""")

policies = cur.fetchall()
for policy in policies:
    print(f"\nPolicy: {policy[2]}")
    print(f"  Command: {policy[3]}")
    print(f"  Using: {policy[4]}")
    print(f"  Check: {policy[5]}")

# 3. Test UPDATE permission for CEO
print("\n\n3️⃣ TEST CEO UPDATE PERMISSION:\n")
ceo_id = '944f7536-6c9a-4bea-99fc-f1c984fef2ef'

# Get a task to test
cur.execute("""
    SELECT id, title, deleted_at
    FROM tasks
    WHERE created_by = %s AND deleted_at IS NULL
    LIMIT 1
""", (ceo_id,))

test_task = cur.fetchone()
if test_task:
    print(f"Test task: {test_task[1]}")
    print(f"Task ID: {test_task[0]}")
    
    # Try to soft delete (simulate what Flutter does)
    try:
        # Set role to CEO
        cur.execute("SET LOCAL role TO authenticated;")
        cur.execute(f"SET LOCAL request.jwt.claims TO '{{'sub': '{ceo_id}', 'role': 'authenticated'}}';")
        
        # Try update
        cur.execute("""
            UPDATE tasks
            SET deleted_at = NOW()
            WHERE id = %s
            RETURNING id, deleted_at
        """, (test_task[0],))
        
        result = cur.fetchone()
        if result:
            print(f"✅ UPDATE SUCCESS! deleted_at = {result[1]}")
            # Rollback to not actually delete
            conn.rollback()
            print("(Rolled back - test only)")
        else:
            print("❌ UPDATE FAILED - No rows affected (RLS blocked?)")
            conn.rollback()
    except Exception as e:
        print(f"❌ UPDATE ERROR: {e}")
        conn.rollback()
else:
    print("❌ No active tasks found for CEO")

# 4. Check how many deleted vs active
print("\n\n4️⃣ TASK STATISTICS:\n")
cur.execute("""
    SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN deleted_at IS NULL THEN 1 END) as active,
        COUNT(CASE WHEN deleted_at IS NOT NULL THEN 1 END) as deleted
    FROM tasks
    WHERE company_id = 'feef10d3-899d-4554-8107-b2256918213a'
""")

stats = cur.fetchone()
print(f"Total tasks: {stats[0]}")
print(f"✅ Active: {stats[1]}")
print(f"❌ Deleted: {stats[2]}")

print("\n" + "=" * 80 + "\n")

cur.close()
conn.close()
