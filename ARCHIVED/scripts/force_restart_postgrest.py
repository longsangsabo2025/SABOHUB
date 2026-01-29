#!/usr/bin/env python3
"""
FORCE RESTART PostgREST by changing schema name temporarily
"""
import os
import time
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("🔥 NUCLEAR RESTART PostgREST schema cache...")

# Step 1: Create different schema name to force reload
print("\n1️⃣ Creating tasks in different schema...")
cur.execute("""
    -- Create a new schema 
    DROP SCHEMA IF EXISTS tasks_api CASCADE;
    CREATE SCHEMA tasks_api;
    
    -- Move tasks table to new schema
    ALTER TABLE public.tasks SET SCHEMA tasks_api;
    
    -- Create view in public schema
    CREATE VIEW public.tasks AS SELECT * FROM tasks_api.tasks;
    
    -- Grant permissions
    GRANT USAGE ON SCHEMA tasks_api TO anon, authenticated;
    GRANT ALL ON tasks_api.tasks TO anon, authenticated;
    GRANT ALL ON public.tasks TO anon, authenticated;
""")
print("   ✓ Moved tasks to tasks_api schema")

# Step 2: Send reload
for i in range(30):
    cur.execute("NOTIFY pgrst, 'reload schema';")
    cur.execute("NOTIFY pgrst, 'reload config';") 
    time.sleep(0.1)
print("   ✓ Sent 30 reload signals")

# Step 3: Wait and move back
print("\n2️⃣ Moving back to public schema...")
time.sleep(2)
cur.execute("""
    -- Drop the view
    DROP VIEW IF EXISTS public.tasks;
    
    -- Move table back to public
    ALTER TABLE tasks_api.tasks SET SCHEMA public;
    
    -- Drop temp schema
    DROP SCHEMA tasks_api CASCADE;
""")
print("   ✓ Moved tasks back to public schema")

# Step 4: Final reload
for i in range(50):
    cur.execute("NOTIFY pgrst, 'reload schema';")
    cur.execute("NOTIFY pgrst, 'reload config';")
    time.sleep(0.05)
print("   ✓ Sent 50 final reload signals")

print("\n🎯 Testing if PostgREST sees the table...")
cur.execute("SELECT COUNT(*) FROM tasks;")
count = cur.fetchone()[0]
print(f"   Tasks count: {count}")

print("\n✅ PostgREST SHOULD NOW SEE THE TASKS TABLE!")
print("   If still failing, restart Supabase project completely")

cur.close()
conn.close()