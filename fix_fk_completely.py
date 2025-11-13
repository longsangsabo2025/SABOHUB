#!/usr/bin/env python3
"""
Fix FK completely: Drop old FK, create new FK with CLEAR names
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("🔍 Checking current FK constraints...")
cur.execute("""
    SELECT 
        conname,
        pg_get_constraintdef(oid) as definition
    FROM pg_constraint
    WHERE conrelid = 'public.tasks'::regclass
    AND contype = 'f'
    ORDER BY conname;
""")
fks = cur.fetchall()
print("\nCurrent FK constraints:")
for fk in fks:
    print(f"  - {fk[0]}: {fk[1]}")

print("\n🗑️ Dropping ALL old FK constraints...")
# Drop tất cả FK cũ
for fk_name, _ in fks:
    try:
        cur.execute(f"ALTER TABLE tasks DROP CONSTRAINT IF EXISTS {fk_name};")
        print(f"  ✓ Dropped {fk_name}")
    except Exception as e:
        print(f"  ✗ Error dropping {fk_name}: {e}")

print("\n✨ Creating NEW FK with EXPLICIT names...")
# Tạo FK mới với tên rõ ràng: tasks_employee_assigned_fkey, tasks_employee_creator_fkey
cur.execute("""
    ALTER TABLE tasks
    ADD CONSTRAINT tasks_employee_assigned_fkey
    FOREIGN KEY (assigned_to) REFERENCES employees(id) ON DELETE SET NULL;
""")
print("  ✓ Created tasks_employee_assigned_fkey → employees(id)")

cur.execute("""
    ALTER TABLE tasks
    ADD CONSTRAINT tasks_employee_creator_fkey
    FOREIGN KEY (created_by) REFERENCES employees(id) ON DELETE SET NULL;
""")
print("  ✓ Created tasks_employee_creator_fkey → employees(id)")

print("\n🔄 RELOAD PostgREST schema cache...")
cur.execute("NOTIFY pgrst, 'reload schema';")
print("  ✓ Sent NOTIFY pgrst reload")

print("\n✅ Verifying new FK constraints...")
cur.execute("""
    SELECT 
        conname,
        pg_get_constraintdef(oid) as definition
    FROM pg_constraint
    WHERE conrelid = 'public.tasks'::regclass
    AND contype = 'f'
    ORDER BY conname;
""")
new_fks = cur.fetchall()
print("\nNew FK constraints:")
for fk in new_fks:
    print(f"  - {fk[0]}: {fk[1]}")

cur.close()
conn.close()
print("\n🎯 DONE! FK constraints renamed and schema cache reloaded!")
