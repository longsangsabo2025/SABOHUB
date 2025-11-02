-- ============================================
-- Migration 001: Consolidate Stores → Branches
-- Simple version for Python execution
-- ============================================

-- Step 1: Add slug column to branches if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'slug'
  ) THEN
    ALTER TABLE branches ADD COLUMN slug TEXT;
  END IF;
END $$;

-- Step 2: Migrate data from stores to branches
INSERT INTO branches (
  id, 
  company_id, 
  name, 
  code, 
  address, 
  phone,
  manager_id, 
  is_active, 
  created_at, 
  updated_at
)
SELECT 
  id, 
  company_id, 
  name, 
  code, 
  address, 
  phone,
  manager_id, 
  CASE 
    WHEN status = 'ACTIVE' THEN true 
    ELSE false 
  END as is_active,
  created_at, 
  updated_at
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

-- Step 3: Update tables - rename store_id to branch_id if needed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tables' AND column_name = 'store_id'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'tables' AND column_name = 'branch_id'
    ) THEN
      ALTER TABLE tables RENAME COLUMN store_id TO branch_id;
    ELSE
      UPDATE tables SET branch_id = store_id WHERE branch_id IS NULL;
      ALTER TABLE tables DROP COLUMN store_id;
    END IF;
  END IF;
END $$;

-- Step 4: Update tasks - copy store_id to branch_id
UPDATE tasks 
SET branch_id = store_id 
WHERE store_id IS NOT NULL 
  AND (branch_id IS NULL OR branch_id != store_id);

-- Step 5: Drop store_id column from tasks
ALTER TABLE tasks DROP COLUMN IF EXISTS store_id;

-- Step 6: Update foreign key constraints on tables
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'tables' 
      AND constraint_name LIKE '%store_id%'
      AND constraint_type = 'FOREIGN KEY'
  ) THEN
    ALTER TABLE tables DROP CONSTRAINT IF EXISTS tables_store_id_fkey;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'tables' 
      AND constraint_name = 'tables_branch_id_fkey'
  ) THEN
    ALTER TABLE tables 
    ADD CONSTRAINT tables_branch_id_fkey 
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Step 7: Create indexes
CREATE INDEX IF NOT EXISTS idx_tables_branch_id ON tables(branch_id);
CREATE INDEX IF NOT EXISTS idx_tasks_branch_id ON tasks(branch_id);

-- Step 8: Add deleted_at column to stores if not exists, then soft delete
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE stores ADD COLUMN deleted_at TIMESTAMPTZ;
  END IF;
END $$;

UPDATE stores 
SET deleted_at = NOW(), 
    updated_at = NOW()
WHERE deleted_at IS NULL;
