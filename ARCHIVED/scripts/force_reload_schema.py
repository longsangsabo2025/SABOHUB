#!/usr/bin/env python3
"""
Force PostgREST to completely reload schema cache
"""
import os
import time
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("🔍 Checking PostgREST schema cache...")

# Check if pgrst schema exists
cur.execute("""
    SELECT schema_name 
    FROM information_schema.schemata 
    WHERE schema_name = 'pgrst';
""")
if cur.fetchone():
    print("✓ Found pgrst schema")
    
    # Try to clear cache table if exists
    try:
        cur.execute("TRUNCATE TABLE pgrst.pre_config;")
        print("✓ Cleared pgrst.pre_config")
    except:
        pass

# Send multiple reload signals
for i in range(5):
    cur.execute("NOTIFY pgrst, 'reload schema';")
    cur.execute("NOTIFY pgrst, 'reload config';")
    print(f"✓ Sent reload signal #{i+1}")
    time.sleep(0.5)

# Check current FK constraints
print("\n📊 Current FK constraints on tasks table:")
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
if fks:
    for fk in fks:
        print(f"  - {fk[0]}: {fk[1]}")
else:
    print("  ⚠️  NO FK CONSTRAINTS FOUND (this is expected after drop)")

print("\n💡 Alternative solution: Use raw SQL insert instead of Supabase client")
print("   This bypasses PostgREST entirely!")

cur.close()
conn.close()
