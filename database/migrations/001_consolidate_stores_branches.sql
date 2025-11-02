-- ============================================
-- Migration: Consolidate Stores → Branches
-- Author: Backend Expert
-- Date: 2025-11-02
-- Description: Merge stores table into branches table
-- ============================================

BEGIN;

-- ============================================
-- STEP 1: Analyze Current Data
-- ============================================

DO $$
DECLARE
  stores_count INTEGER;
  branches_count INTEGER;
  conflicts_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO stores_count FROM stores WHERE deleted_at IS NULL;
  SELECT COUNT(*) INTO branches_count FROM branches WHERE deleted_at IS NULL;
  
  SELECT COUNT(*) INTO conflicts_count
  FROM stores s
  WHERE EXISTS (
    SELECT 1 FROM branches b 
    WHERE b.company_id = s.company_id 
    AND b.code = s.code
  );
  
  RAISE NOTICE '📊 Current Status:';
  RAISE NOTICE '  - Stores: % records', stores_count;
  RAISE NOTICE '  - Branches: % records', branches_count;
  RAISE NOTICE '  - Conflicts: % records', conflicts_count;
  
  IF conflicts_count > 0 THEN
    RAISE EXCEPTION '❌ Found % conflicting records! Please resolve manually first.', conflicts_count;
  END IF;
END $$;

-- ============================================
-- STEP 2: Show Data to be Migrated
-- ============================================

RAISE NOTICE '📋 Data to be migrated from stores to branches:';
SELECT 
  id,
  company_id,
  name,
  code,
  address,
  phone,
  manager_id,
  status as store_status,
  CASE WHEN status = 'ACTIVE' THEN true ELSE false END as will_be_active
FROM stores
WHERE deleted_at IS NULL;

-- ============================================
-- STEP 3: Add missing columns to branches (if needed)
-- ============================================

-- Check if 'slug' column exists in branches, if not add it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'slug'
  ) THEN
    ALTER TABLE branches ADD COLUMN slug TEXT;
    RAISE NOTICE '✅ Added slug column to branches';
  END IF;
END $$;

-- ============================================
-- STEP 4: Migrate Data from Stores to Branches
-- ============================================

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
  AND deleted_at IS NULL
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  code = EXCLUDED.code,
  address = EXCLUDED.address,
  phone = EXCLUDED.phone,
  manager_id = EXCLUDED.manager_id,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

RAISE NOTICE '✅ Migrated stores data to branches';

-- ============================================
-- STEP 5: Update Foreign Keys in Related Tables
-- ============================================

-- 5.1: Update tables table (rename store_id to branch_id if needed)
DO $$
BEGIN
  -- Check if store_id column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tables' AND column_name = 'store_id'
  ) THEN
    -- If branch_id doesn't exist, rename store_id to branch_id
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'tables' AND column_name = 'branch_id'
    ) THEN
      ALTER TABLE tables RENAME COLUMN store_id TO branch_id;
      RAISE NOTICE '✅ Renamed tables.store_id to branch_id';
    ELSE
      -- If both exist, copy data and drop store_id
      UPDATE tables SET branch_id = store_id WHERE branch_id IS NULL;
      ALTER TABLE tables DROP COLUMN store_id;
      RAISE NOTICE '✅ Copied store_id to branch_id and dropped store_id column';
    END IF;
  END IF;
END $$;

-- 5.2: Update tasks table
UPDATE tasks 
SET branch_id = store_id 
WHERE store_id IS NOT NULL 
  AND (branch_id IS NULL OR branch_id != store_id);

RAISE NOTICE '✅ Updated tasks.branch_id from store_id';

-- Drop store_id column from tasks if exists
ALTER TABLE tasks DROP COLUMN IF EXISTS store_id;
RAISE NOTICE '✅ Dropped tasks.store_id column';

-- 5.3: Update any other tables referencing stores
-- Add more UPDATE statements here if needed

-- ============================================
-- STEP 6: Verify Data Integrity
-- ============================================

DO $$
DECLARE
  orphaned_tables INTEGER;
  orphaned_tasks INTEGER;
BEGIN
  -- Check for orphaned records in tables
  SELECT COUNT(*) INTO orphaned_tables
  FROM tables t
  WHERE NOT EXISTS (
    SELECT 1 FROM branches b WHERE b.id = t.branch_id
  );
  
  -- Check for orphaned records in tasks
  SELECT COUNT(*) INTO orphaned_tasks
  FROM tasks t
  WHERE branch_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM branches b WHERE b.id = t.branch_id
    );
  
  RAISE NOTICE '🔍 Data Integrity Check:';
  RAISE NOTICE '  - Orphaned tables records: %', orphaned_tables;
  RAISE NOTICE '  - Orphaned tasks records: %', orphaned_tasks;
  
  IF orphaned_tables > 0 OR orphaned_tasks > 0 THEN
    RAISE WARNING '⚠️  Found orphaned records! Please review.';
  ELSE
    RAISE NOTICE '✅ All foreign keys are valid!';
  END IF;
END $$;

-- ============================================
-- STEP 7: Update Foreign Key Constraints
-- ============================================

-- Drop old foreign key on tables.store_id (if exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'tables' 
      AND constraint_name LIKE '%store_id%'
      AND constraint_type = 'FOREIGN KEY'
  ) THEN
    ALTER TABLE tables DROP CONSTRAINT IF EXISTS tables_store_id_fkey;
    RAISE NOTICE '✅ Dropped old foreign key constraint on tables';
  END IF;
END $$;

-- Ensure foreign key on tables.branch_id exists
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
    RAISE NOTICE '✅ Added foreign key constraint on tables.branch_id';
  END IF;
END $$;

-- ============================================
-- STEP 8: Create Indexes
-- ============================================

CREATE INDEX IF NOT EXISTS idx_tables_branch_id ON tables(branch_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_branch_id ON tasks(branch_id) WHERE deleted_at IS NULL;

RAISE NOTICE '✅ Created/verified indexes on branch_id columns';

-- ============================================
-- STEP 9: Soft Delete Stores Table Data
-- ============================================

-- Mark all stores as deleted (soft delete)
UPDATE stores 
SET deleted_at = NOW(), 
    updated_at = NOW()
WHERE deleted_at IS NULL;

RAISE NOTICE '✅ Soft deleted all stores records (for backup purposes)';

-- ============================================
-- STEP 10: Final Summary
-- ============================================

DO $$
DECLARE
  final_branches_count INTEGER;
  final_tables_count INTEGER;
  final_tasks_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO final_branches_count FROM branches WHERE deleted_at IS NULL;
  SELECT COUNT(*) INTO final_tables_count FROM tables WHERE deleted_at IS NULL;
  SELECT COUNT(*) INTO final_tasks_count FROM tasks WHERE deleted_at IS NULL;
  
  RAISE NOTICE '';
  RAISE NOTICE '==================================================';
  RAISE NOTICE '✅ Migration Completed Successfully!';
  RAISE NOTICE '==================================================';
  RAISE NOTICE 'Final Statistics:';
  RAISE NOTICE '  - Active Branches: %', final_branches_count;
  RAISE NOTICE '  - Active Tables: %', final_tables_count;
  RAISE NOTICE '  - Active Tasks: %', final_tasks_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  1. Update Flutter code to use "branches" instead of "stores"';
  RAISE NOTICE '  2. Test all CRUD operations';
  RAISE NOTICE '  3. After verification, can drop stores table completely';
  RAISE NOTICE '';
END $$;

COMMIT;

-- ============================================
-- ROLLBACK SCRIPT (Keep this commented for emergency use)
-- ============================================

/*
BEGIN;

-- Restore stores from soft delete
UPDATE stores 
SET deleted_at = NULL, updated_at = NOW()
WHERE deleted_at IS NOT NULL;

-- Restore original column names if needed
-- ALTER TABLE tables RENAME COLUMN branch_id TO store_id;
-- ALTER TABLE tasks ADD COLUMN store_id UUID;
-- UPDATE tasks SET store_id = branch_id;

COMMIT;
*/

-- ============================================
-- CLEANUP SCRIPT (Run after verification)
-- ============================================

/*
-- After verifying everything works, you can drop stores table:

BEGIN;
DROP TABLE IF EXISTS stores CASCADE;
COMMIT;
*/
