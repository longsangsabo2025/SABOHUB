-- ============================================
-- MIGRATION: Add Soft Delete Support to Companies
-- Date: 2025-11-11
-- Description: Add deleted_at column and update RLS policies
-- ============================================

-- Step 1: Add deleted_at column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'companies' AND column_name = 'deleted_at'
    ) THEN
        ALTER TABLE companies ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
        COMMENT ON COLUMN companies.deleted_at IS 'Timestamp when company was soft deleted. NULL = active, NOT NULL = deleted';
        
        -- Create partial index for performance (only index active companies)
        CREATE INDEX idx_companies_deleted_at 
            ON companies(deleted_at) 
            WHERE deleted_at IS NULL;
        
        RAISE NOTICE '✅ Added deleted_at column to companies table';
    ELSE
        RAISE NOTICE '⚠️  deleted_at column already exists';
    END IF;
END $$;

-- Step 2: Update RLS policies to exclude soft-deleted companies

-- SELECT policy: Users can only see non-deleted companies they own
DROP POLICY IF EXISTS "Users can view their companies" ON companies;
CREATE POLICY "Users can view their companies" ON companies
    FOR SELECT
    USING (
        (created_by = auth.uid() OR owner_id = auth.uid())
        AND deleted_at IS NULL  -- Exclude soft-deleted companies
    );

-- UPDATE policy: Users can only update non-deleted companies they own
DROP POLICY IF EXISTS "Users can update their companies" ON companies;
CREATE POLICY "Users can update their companies" ON companies
    FOR UPDATE
    USING (
        (created_by = auth.uid() OR owner_id = auth.uid())
        AND deleted_at IS NULL  -- Cannot update deleted companies
    );

-- DELETE policy: Actually performs soft delete (sets deleted_at)
DROP POLICY IF EXISTS "Users can delete their companies" ON companies;
CREATE POLICY "Users can delete their companies" ON companies
    FOR UPDATE  -- Changed from DELETE to UPDATE since we're doing soft delete
    USING (
        (created_by = auth.uid() OR owner_id = auth.uid())
        AND deleted_at IS NULL  -- Can only soft-delete active companies
    );

-- Step 3: Create helper function for soft delete (optional)
CREATE OR REPLACE FUNCTION soft_delete_company(company_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE companies
    SET deleted_at = NOW()
    WHERE id = company_id
      AND (created_by = auth.uid() OR owner_id = auth.uid())
      AND deleted_at IS NULL;
      
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Company not found or already deleted';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create helper function for restore (optional)
CREATE OR REPLACE FUNCTION restore_company(company_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE companies
    SET deleted_at = NULL
    WHERE id = company_id
      AND (created_by = auth.uid() OR owner_id = auth.uid())
      AND deleted_at IS NOT NULL;
      
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Company not found or not deleted';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Verification
DO $$
DECLARE
    column_exists BOOLEAN;
    index_exists BOOLEAN;
    policy_count INTEGER;
BEGIN
    -- Check column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'companies' AND column_name = 'deleted_at'
    ) INTO column_exists;
    
    -- Check index
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'companies' AND indexname = 'idx_companies_deleted_at'
    ) INTO index_exists;
    
    -- Check policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'companies';
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'MIGRATION VERIFICATION';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Column deleted_at exists: %', column_exists;
    RAISE NOTICE 'Index created: %', index_exists;
    RAISE NOTICE 'RLS policies count: %', policy_count;
    RAISE NOTICE '==============================================';
    
    IF column_exists AND index_exists AND policy_count >= 3 THEN
        RAISE NOTICE '✅ Migration completed successfully!';
    ELSE
        RAISE WARNING '⚠️  Migration may be incomplete. Please verify manually.';
    END IF;
END $$;
