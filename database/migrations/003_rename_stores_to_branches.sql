-- Migration 003: Rename stores table to branches and update all foreign keys
-- This completes the consolidation from stores to branches naming convention

BEGIN;

-- 1. Rename stores table to branches
ALTER TABLE stores RENAME TO branches;

-- 2. Rename store_id columns to branch_id in all related tables
ALTER TABLE tables RENAME COLUMN store_id TO branch_id;
ALTER TABLE users RENAME COLUMN store_id TO branch_id;
ALTER TABLE tasks RENAME COLUMN store_id TO branch_id;
ALTER TABLE daily_revenue RENAME COLUMN store_id TO branch_id;
ALTER TABLE activity_logs RENAME COLUMN store_id TO branch_id;

-- 3. Update constraint names (if they exist)
-- Note: Constraints might have been auto-generated with different names
DO $$ 
BEGIN
    -- Rename foreign key constraints for tables
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'tables_store_id_fkey' AND table_name = 'tables') THEN
        ALTER TABLE tables RENAME CONSTRAINT tables_store_id_fkey TO tables_branch_id_fkey;
    END IF;

    -- Rename foreign key constraints for users
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'users_store_id_fkey' AND table_name = 'users') THEN
        ALTER TABLE users RENAME CONSTRAINT users_store_id_fkey TO users_branch_id_fkey;
    END IF;

    -- Rename foreign key constraints for tasks
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'tasks_store_id_fkey' AND table_name = 'tasks') THEN
        ALTER TABLE tasks RENAME CONSTRAINT tasks_store_id_fkey TO tasks_branch_id_fkey;
    END IF;

    -- Rename foreign key constraints for daily_revenue
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'daily_revenue_store_id_fkey' AND table_name = 'daily_revenue') THEN
        ALTER TABLE daily_revenue RENAME CONSTRAINT daily_revenue_store_id_fkey TO daily_revenue_branch_id_fkey;
    END IF;

    -- Rename foreign key constraints for activity_logs
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'activity_logs_store_id_fkey' AND table_name = 'activity_logs') THEN
        ALTER TABLE activity_logs RENAME CONSTRAINT activity_logs_store_id_fkey TO activity_logs_branch_id_fkey;
    END IF;
END $$;

-- 4. Update indexes (if they exist)
DO $$ 
BEGIN
    -- Rename indexes for tables
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_tables_store_id') THEN
        ALTER INDEX idx_tables_store_id RENAME TO idx_tables_branch_id;
    END IF;

    -- Rename indexes for users
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_store_id') THEN
        ALTER INDEX idx_users_store_id RENAME TO idx_users_branch_id;
    END IF;

    -- Rename indexes for tasks
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_tasks_store_id') THEN
        ALTER INDEX idx_tasks_store_id RENAME TO idx_tasks_branch_id;
    END IF;

    -- Rename indexes for daily_revenue
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_daily_revenue_store_id') THEN
        ALTER INDEX idx_daily_revenue_store_id RENAME TO idx_daily_revenue_branch_id;
    END IF;
END $$;

-- 5. Add helpful indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_branches_company_id ON branches(company_id);
CREATE INDEX IF NOT EXISTS idx_branches_status ON branches(status);
CREATE INDEX IF NOT EXISTS idx_tables_branch_id ON tables(branch_id);
CREATE INDEX IF NOT EXISTS idx_users_branch_id ON users(branch_id);
CREATE INDEX IF NOT EXISTS idx_tasks_branch_id ON tasks(branch_id);

COMMIT;

-- Verification queries
SELECT 'Migration 003 completed successfully!' as message;
SELECT 'branches table' as table_name, COUNT(*) as row_count FROM branches;
SELECT 'Tables with branch_id' as info, COUNT(*) as count FROM tables WHERE branch_id IS NOT NULL;
SELECT 'Users with branch_id' as info, COUNT(*) as count FROM users WHERE branch_id IS NOT NULL;
