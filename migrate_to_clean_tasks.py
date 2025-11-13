#!/usr/bin/env python3
"""
ULTIMATE CLEAN SOLUTION: Migrate tasks to new table without FK history
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("=" * 70)
print("🎯 CLEAN SOLUTION: Create new tasks_v2 table")
print("=" * 70)

# Step 1: Create new table
print("\n📦 STEP 1: Creating tasks_v2 table...")
cur.execute("""
    DROP TABLE IF EXISTS tasks_v2 CASCADE;
    
    CREATE TABLE tasks_v2 (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        branch_id UUID,
        company_id UUID,
        store_id UUID,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT CHECK (category IN ('general', 'operations', 'sales', 'delivery', 'inventory', 'customer_service', 'maintenance', 'admin', 'other')),
        priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
        status TEXT CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
        recurrence TEXT CHECK (recurrence IN ('none', 'daily', 'weekly', 'monthly')),
        assigned_to UUID,
        assigned_to_name TEXT,
        assigned_to_role TEXT,
        assigned_by_name TEXT,
        due_date TIMESTAMPTZ,
        completed_at TIMESTAMPTZ,
        created_by UUID,
        created_by_name TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        deleted_at TIMESTAMPTZ,
        notes TEXT,
        progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100)
    );
    
    -- Create indexes (NO FOREIGN KEYS!)
    CREATE INDEX idx_tasks_v2_company ON tasks_v2(company_id) WHERE deleted_at IS NULL;
    CREATE INDEX idx_tasks_v2_branch ON tasks_v2(branch_id) WHERE deleted_at IS NULL;
    CREATE INDEX idx_tasks_v2_assigned ON tasks_v2(assigned_to) WHERE deleted_at IS NULL;
    CREATE INDEX idx_tasks_v2_status ON tasks_v2(status) WHERE deleted_at IS NULL;
    CREATE INDEX idx_tasks_v2_due_date ON tasks_v2(due_date) WHERE deleted_at IS NULL;
    
    -- Add comment
    COMMENT ON TABLE tasks_v2 IS 'Task management v2 - no FK constraints to avoid PostgREST cache issues';
""")
print("   ✓ Created tasks_v2 table (NO FOREIGN KEYS)")

# Step 2: Copy existing data
print("\n📋 STEP 2: Copying data from tasks to tasks_v2...")
cur.execute("""
    INSERT INTO tasks_v2 (
        id, branch_id, company_id, store_id, title, description,
        category, priority, status, recurrence,
        assigned_to, assigned_to_name, assigned_to_role, assigned_by_name,
        due_date, completed_at, created_by, created_by_name,
        created_at, updated_at, deleted_at, notes, progress
    )
    SELECT 
        id, branch_id, company_id, store_id, title, description,
        category, priority, status, recurrence,
        assigned_to, assigned_to_name, assigned_to_role, assigned_by_name,
        due_date, completed_at, created_by, created_by_name,
        created_at, updated_at, deleted_at, notes, progress
    FROM tasks;
""")
copied = cur.rowcount
print(f"   ✓ Copied {copied} tasks from old table")

# Step 3: Grant permissions
print("\n🔐 STEP 3: Setting up RLS and permissions...")
cur.execute("""
    -- Enable RLS
    ALTER TABLE tasks_v2 ENABLE ROW LEVEL SECURITY;
    
    -- Grant basic permissions
    GRANT SELECT, INSERT, UPDATE, DELETE ON tasks_v2 TO anon, authenticated;
    
    -- Create simple RLS policies (adjust based on your needs)
    CREATE POLICY "Anyone can view tasks_v2" ON tasks_v2 FOR SELECT USING (true);
    CREATE POLICY "Anyone can insert tasks_v2" ON tasks_v2 FOR INSERT WITH CHECK (true);
    CREATE POLICY "Anyone can update tasks_v2" ON tasks_v2 FOR UPDATE USING (true);
    CREATE POLICY "Anyone can delete tasks_v2" ON tasks_v2 FOR DELETE USING (true);
""")
print("   ✓ Enabled RLS with permissive policies")

# Step 4: Rename tables
print("\n🔄 STEP 4: Swapping tables...")
cur.execute("""
    -- Rename old table
    ALTER TABLE tasks RENAME TO tasks_old_backup;
    
    -- Rename new table to tasks
    ALTER TABLE tasks_v2 RENAME TO tasks;
""")
print("   ✓ Renamed tasks → tasks_old_backup")
print("   ✓ Renamed tasks_v2 → tasks")

# Step 5: Force reload
print("\n🔄 STEP 5: Forcing PostgREST reload...")
for i in range(20):
    cur.execute("NOTIFY pgrst, 'reload schema';")
    cur.execute("NOTIFY pgrst, 'reload config';")
print("   ✓ Sent 20 reload signals")

print("\n" + "=" * 70)
print("✅ MIGRATION COMPLETE!")
print("=" * 70)
print("\n📊 Summary:")
cur.execute("SELECT COUNT(*) FROM tasks WHERE deleted_at IS NULL;")
count = cur.fetchone()[0]
print(f"   Active tasks: {count}")

cur.execute("""
    SELECT COUNT(*) 
    FROM pg_constraint 
    WHERE conrelid = 'tasks'::regclass 
    AND contype = 'f';
""")
fk_count = cur.fetchone()[0]
print(f"   FK constraints: {fk_count} (should be 0)")

print("\n💡 Old table backed up as: tasks_old_backup")
print("   You can drop it later with: DROP TABLE tasks_old_backup CASCADE;")

cur.close()
conn.close()
