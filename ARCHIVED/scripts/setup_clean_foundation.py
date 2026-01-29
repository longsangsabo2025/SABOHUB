#!/usr/bin/env python3
"""
RESET FOUNDATION: Setup clean database schema from scratch
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("🔧 FOUNDATION RESET: Clean setup from scratch")
print("=" * 60)

# Step 1: Drop everything
print("\n1️⃣ Cleaning slate...")
cur.execute("""
    -- Drop old tables
    DROP TABLE IF EXISTS tasks_old_backup CASCADE;
    DROP TABLE IF EXISTS tasks CASCADE;
    
    -- Drop any cached functions
    DROP FUNCTION IF EXISTS create_task CASCADE;
    DROP FUNCTION IF EXISTS create_task_bypass CASCADE;
""")
print("   ✓ Dropped all task-related objects")

# Step 2: Create fresh tasks table with correct design
print("\n2️⃣ Creating fresh tasks table...")
cur.execute("""
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID,
    company_id UUID, 
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    priority TEXT DEFAULT 'medium',
    status TEXT DEFAULT 'pending',
    recurrence TEXT DEFAULT 'none',
    assigned_to UUID,
    assigned_to_name TEXT,
    assigned_to_role TEXT,
    due_date TIMESTAMPTZ,
    created_by UUID,
    created_by_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    progress INTEGER DEFAULT 0,
    deleted_at TIMESTAMPTZ
);

-- Add constraints (NO FOREIGN KEYS!)
ALTER TABLE tasks ADD CONSTRAINT tasks_category_check 
    CHECK (category IN ('general', 'operations', 'sales', 'delivery', 'inventory', 'customer_service', 'maintenance', 'admin', 'other'));
    
ALTER TABLE tasks ADD CONSTRAINT tasks_priority_check 
    CHECK (priority IN ('low', 'medium', 'high', 'urgent'));
    
ALTER TABLE tasks ADD CONSTRAINT tasks_status_check 
    CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'));
    
ALTER TABLE tasks ADD CONSTRAINT tasks_recurrence_check 
    CHECK (recurrence IN ('none', 'daily', 'weekly', 'monthly'));

ALTER TABLE tasks ADD CONSTRAINT tasks_progress_check 
    CHECK (progress >= 0 AND progress <= 100);

-- Add indexes for performance
CREATE INDEX idx_tasks_company ON tasks(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_branch ON tasks(branch_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_assigned ON tasks(assigned_to) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_status ON tasks(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE deleted_at IS NULL;

-- Add table comment
COMMENT ON TABLE tasks IS 'Task management table - NO FK constraints to avoid PostgREST cache issues';
""")
print("   ✓ Created tasks table with proper constraints")

# Step 3: Setup RLS
print("\n3️⃣ Setting up Row Level Security...")
cur.execute("""
-- Enable RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Simple policies for testing (adjust later)
CREATE POLICY "Allow all operations on tasks" ON tasks
FOR ALL USING (true) WITH CHECK (true);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON tasks TO anon, authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
""")
print("   ✓ Enabled RLS with permissive policies")

# Step 4: Insert sample data
print("\n4️⃣ Adding sample data...")
cur.execute("""
INSERT INTO tasks (
    title, description, category, priority, status,
    assigned_to_name, created_by_name, due_date, notes
) VALUES 
('Sample Task 1', 'Test task description', 'general', 'medium', 'pending', 
 'Test User', 'System', NOW() + INTERVAL '7 days', 'Sample task for testing'),
('Sample Task 2', 'Another test task', 'operations', 'high', 'in_progress',
 'Test User', 'System', NOW() + INTERVAL '3 days', 'Second sample task');
""")
print("   ✓ Added 2 sample tasks")

# Step 5: Force complete schema reload
print("\n5️⃣ Forcing PostgREST complete reload...")
for i in range(100):
    cur.execute("NOTIFY pgrst, 'reload schema';")
    cur.execute("NOTIFY pgrst, 'reload config';")
    if (i + 1) % 20 == 0:
        print(f"   ✓ Sent {i+1} reload signals")

# Final verification
print("\n✅ FOUNDATION SETUP COMPLETE!")
cur.execute("SELECT COUNT(*) FROM tasks;")
count = cur.fetchone()[0]
print(f"   Tasks in table: {count}")

cur.execute("""
    SELECT COUNT(*) FROM pg_constraint 
    WHERE conrelid = 'tasks'::regclass AND contype = 'f';
""")
fk_count = cur.fetchone()[0] 
print(f"   Foreign key constraints: {fk_count} (should be 0)")

print("\n🎯 Clean foundation ready!")
print("   - No FK constraints")
print("   - Fresh schema") 
print("   - PostgREST cache cleared")
print("   - Sample data loaded")

cur.close()
conn.close()