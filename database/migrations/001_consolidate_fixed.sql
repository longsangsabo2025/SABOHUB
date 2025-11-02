-- ============================================
-- Migration 001: Consolidate Stores → Branches (Fixed)
-- ============================================

-- Step 1: Add missing columns to branches
DO $$
BEGIN
  -- Add slug if not exists
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branches' AND column_name = 'slug') THEN
    ALTER TABLE branches ADD COLUMN slug TEXT;
  END IF;
  
  -- Add deleted_at if not exists  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branches' AND column_name = 'deleted_at') THEN
    ALTER TABLE branches ADD COLUMN deleted_at TIMESTAMPTZ;
  END IF;
END $$;

-- Step 2: Migrate data from stores to branches
INSERT INTO branches (
  id, company_id, name, code, address, phone, manager_id, is_active, created_at, updated_at
)
SELECT 
  id, company_id, name, code, address, phone, manager_id,
  CASE WHEN status = 'ACTIVE' THEN true ELSE false END as is_active,
  created_at, updated_at
FROM stores
WHERE id NOT IN (SELECT id FROM branches)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  code = EXCLUDED.code,
  address = EXCLUDED.address,
  phone = EXCLUDED.phone,
  manager_id = EXCLUDED.manager_id,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- Step 3: Add branch_id to tasks if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tasks' AND column_name = 'branch_id') THEN
    ALTER TABLE tasks ADD COLUMN branch_id UUID;
  END IF;
END $$;

-- Step 4: Copy store_id to branch_id in tasks
UPDATE tasks 
SET branch_id = store_id 
WHERE store_id IS NOT NULL AND branch_id IS NULL;

-- Step 5: Add foreign key on tasks.branch_id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'tasks' AND constraint_name = 'tasks_branch_id_fkey'
  ) THEN
    ALTER TABLE tasks ADD CONSTRAINT tasks_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Step 6: Create index on tasks.branch_id
CREATE INDEX IF NOT EXISTS idx_tasks_branch_id ON tasks(branch_id);

-- Step 7: Note about tables table
-- We cannot safely modify the 'tables' table name conflict
-- This will need to be done manually or in a separate migration

-- Step 8: Add deleted_at to stores and soft delete
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'stores' AND column_name = 'deleted_at') THEN
    ALTER TABLE stores ADD COLUMN deleted_at TIMESTAMPTZ;
  END IF;
END $$;

UPDATE stores 
SET deleted_at = NOW(), updated_at = NOW()
WHERE deleted_at IS NULL;
