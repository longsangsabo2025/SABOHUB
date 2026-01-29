#!/usr/bin/env python3
"""
DROP ALL FK constraints from tasks table - NUCLEAR OPTION
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("🔥 DROPPING ALL FK CONSTRAINTS FROM TASKS TABLE...")

# Get all FK constraints
cur.execute("""
    SELECT conname
    FROM pg_constraint
    WHERE conrelid = 'public.tasks'::regclass
    AND contype = 'f';
""")
fks = cur.fetchall()

print(f"\nFound {len(fks)} FK constraints:")
for fk in fks:
    print(f"  - {fk[0]}")

# Drop all FK constraints
for fk in fks:
    fk_name = fk[0]
    try:
        cur.execute(f"ALTER TABLE tasks DROP CONSTRAINT {fk_name};")
        print(f"  ✓ Dropped {fk_name}")
    except Exception as e:
        print(f"  ✗ Error: {e}")

print("\n🔄 Reloading PostgREST schema cache...")
cur.execute("NOTIFY pgrst, 'reload schema';")

print("\n✅ DONE! Tasks table now has NO FK constraints!")
print("⚠️  You can add them back later if needed")

cur.close()
conn.close()
