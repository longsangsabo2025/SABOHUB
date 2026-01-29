import psycopg2
from dotenv import load_dotenv
import os
from datetime import datetime

load_dotenv()

conn = psycopg2.connect(os.getenv("SUPABASE_CONNECTION_STRING"))
cur = conn.cursor()

print("\n🧪 TESTING CEO DELETE TASK WITH NEW RLS\n")
print("=" * 80)

ceo_id = '944f7536-6c9a-4bea-99fc-f1c984fef2ef'

# 1. Get an active task
print("\n1️⃣ Finding an active task...\n")
cur.execute("""
    SELECT id, title, deleted_at, created_by
    FROM tasks
    WHERE company_id = 'feef10d3-899d-4554-8107-b2256918213a'
    AND deleted_at IS NULL
    AND created_by = %s
    LIMIT 1
""", (ceo_id,))

task = cur.fetchone()
if not task:
    print("❌ No active tasks found")
    cur.close()
    conn.close()
    exit()

task_id, title, deleted_at, created_by = task
print(f"✅ Found task: {title}")
print(f"   ID: {task_id}")
print(f"   Status: {'ACTIVE' if not deleted_at else 'DELETED'}")

# 2. Simulate CEO soft delete (with RLS context)
print(f"\n2️⃣ Testing soft delete AS CEO...\n")

try:
    # Simulate authenticated user context
    cur.execute("SET LOCAL role TO authenticated;")
    
    # Try to update deleted_at
    cur.execute("""
        UPDATE tasks
        SET deleted_at = %s
        WHERE id = %s
        AND company_id IN (
            SELECT id FROM companies WHERE created_by = %s
        )
        RETURNING id, title, deleted_at
    """, (datetime.now(), task_id, ceo_id))
    
    result = cur.fetchone()
    
    if result:
        print(f"✅ SOFT DELETE SUCCESS!")
        print(f"   Task: {result[1]}")
        print(f"   deleted_at: {result[2]}")
        
        # Test: Can CEO still SELECT deleted task?
        print(f"\n3️⃣ Testing CEO can SELECT deleted task...\n")
        cur.execute("""
            SELECT id, title, deleted_at
            FROM tasks
            WHERE id = %s
            AND company_id IN (
                SELECT id FROM companies WHERE created_by = %s
            )
        """, (task_id, ceo_id))
        
        deleted_task = cur.fetchone()
        if deleted_task:
            print(f"✅ CEO CAN SEE deleted task!")
            print(f"   Title: {deleted_task[1]}")
            print(f"   deleted_at: {deleted_task[2]}")
        else:
            print(f"❌ CEO CANNOT see deleted task (RLS still blocking SELECT)")
        
        # Restore task
        print(f"\n4️⃣ Restoring task...\n")
        cur.execute("""
            UPDATE tasks
            SET deleted_at = NULL
            WHERE id = %s
            RETURNING id, title, deleted_at
        """, (task_id,))
        
        restored = cur.fetchone()
        print(f"✅ Restored: {restored[1]}")
        print(f"   deleted_at: {restored[2]}")
        
        conn.commit()
    else:
        print(f"❌ DELETE FAILED - RLS still blocking?")
        conn.rollback()
        
except Exception as e:
    print(f"❌ ERROR: {e}")
    conn.rollback()

# Reset role
cur.execute("RESET role;")

print("\n" + "=" * 80)
print("\n✅ TEST COMPLETE!\n")

cur.close()
conn.close()
