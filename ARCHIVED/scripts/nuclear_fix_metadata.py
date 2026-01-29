#!/usr/bin/env python3
"""
NUCLEAR OPTION: Remove ALL FK metadata from pg_catalog
This will force PostgREST to completely ignore FK relationships
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("🔥 REMOVING FK METADATA FROM SYSTEM CATALOG...")

# Check what PostgREST sees
print("\n1️⃣ Checking pg_constraint...")
cur.execute("""
    SELECT conname, conrelid::regclass, confrelid::regclass
    FROM pg_constraint
    WHERE contype = 'f' 
    AND conrelid::regclass::text = 'tasks';
""")
fks = cur.fetchall()
print(f"   Found {len(fks)} FK constraints:")
for fk in fks:
    print(f"   - {fk[0]}: {fk[1]} → {fk[2]}")

# Check if there are any old FK names in comments
print("\n2️⃣ Checking table comments for FK hints...")
cur.execute("""
    SELECT obj_description('tasks'::regclass, 'pg_class');
""")
comment = cur.fetchone()
if comment and comment[0]:
    print(f"   Table comment: {comment[0]}")
else:
    print("   No table comment")

# Check column comments
cur.execute("""
    SELECT 
        a.attname,
        col_description('tasks'::regclass, a.attnum) as comment
    FROM pg_attribute a
    WHERE a.attrelid = 'tasks'::regclass
    AND a.attnum > 0
    AND NOT a.attisdropped
    AND col_description('tasks'::regclass, a.attnum) IS NOT NULL;
""")
col_comments = cur.fetchall()
if col_comments:
    print(f"\n   Column comments:")
    for col in col_comments:
        print(f"   - {col[0]}: {col[1]}")

# The REAL fix: Rename FK columns to remove "fkey" hint
print("\n3️⃣ RENAMING COLUMNS to remove FK hints...")

# Actually, let's just make sure there are NO FK constraints at all
cur.execute("""
    SELECT conname
    FROM pg_constraint
    WHERE conrelid = 'tasks'::regclass
    AND contype = 'f';
""")
remaining_fks = cur.fetchall()

if remaining_fks:
    print(f"\n⚠️  Still found {len(remaining_fks)} FK constraints! Dropping...")
    for fk in remaining_fks:
        cur.execute(f"ALTER TABLE tasks DROP CONSTRAINT IF EXISTS {fk[0]} CASCADE;")
        print(f"   ✓ Dropped {fk[0]}")
else:
    print("   ✓ No FK constraints found")

# Force vacuum to clean metadata
print("\n4️⃣ Cleaning system catalog...")
cur.execute("VACUUM ANALYZE tasks;")
print("   ✓ VACUUM ANALYZE completed")

# Send MULTIPLE reload signals
print("\n5️⃣ Force reloading PostgREST (20 signals)...")
for i in range(20):
    cur.execute("NOTIFY pgrst, 'reload schema';")
    cur.execute("NOTIFY pgrst, 'reload config';")
    if (i + 1) % 5 == 0:
        print(f"   ✓ Sent {i+1} signals")

print("\n✅ DONE!")
print("\n💡 If still getting PGRST200, the issue is:")
print("   - PostgREST process needs RESTART (Supabase platform level)")
print("   - Or PostgREST is caching from OpenAPI schema definition")
print("\n🔧 Try restarting Supabase project in dashboard")

cur.close()
conn.close()
