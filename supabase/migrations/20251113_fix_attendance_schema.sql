-- Migration: Fix Attendance Table Schema
-- Date: 2025-11-13
-- Priority: CRITICAL
-- Description: Update attendance table to use branch_id and company_id instead of store_id

-- ============================================
-- 1. ADD MISSING COLUMNS
-- ============================================

DO $$ 
BEGIN
  RAISE NOTICE '🔧 Adding missing columns to attendance table...';
END $$;

-- Add branch_id if not exists
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE;

-- Add company_id if not exists  
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;

-- Add GPS coordinates for check-in
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_in_latitude DECIMAL(10, 8);
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_in_longitude DECIMAL(11, 8);

-- Add GPS coordinates for check-out
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_out_latitude DECIMAL(10, 8);
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_out_longitude DECIMAL(11, 8);

-- Add cached employee info
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS employee_name TEXT;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS employee_role TEXT;

-- Add soft delete
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

DO $$ 
BEGIN
  RAISE NOTICE '✅ Missing columns added';
END $$;

-- ============================================
-- 2. MIGRATE DATA FROM store_id TO branch_id
-- ============================================

DO $$ 
DECLARE
  store_id_exists BOOLEAN;
  migration_count INTEGER := 0;
BEGIN
  -- Check if store_id column exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'attendance' AND column_name = 'store_id'
  ) INTO store_id_exists;
  
  IF store_id_exists THEN
    RAISE NOTICE '🔄 Migrating data from store_id to branch_id...';
    
    -- For each attendance record with store_id, find corresponding branch
    -- Assuming stores table has a branch_id column, or we need to map manually
    UPDATE public.attendance a
    SET branch_id = s.branch_id,
        company_id = s.company_id
    FROM public.stores s
    WHERE a.store_id = s.id
      AND a.branch_id IS NULL;
    
    GET DIAGNOSTICS migration_count = ROW_COUNT;
    RAISE NOTICE '✅ Migrated % attendance records from store_id to branch_id', migration_count;
    
    -- Drop store_id column
    ALTER TABLE public.attendance DROP COLUMN IF EXISTS store_id CASCADE;
    RAISE NOTICE '✅ Dropped store_id column';
  ELSE
    RAISE NOTICE '✅ store_id column does not exist, skipping migration';
  END IF;
END $$;

-- ============================================
-- 3. ADD CONSTRAINTS
-- ============================================

DO $$ 
BEGIN
  RAISE NOTICE '🔧 Adding constraints...';
END $$;

-- Make branch_id and company_id NOT NULL (after migration)
-- Only if there's data to migrate, otherwise skip
DO $$ 
DECLARE
  record_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO record_count FROM public.attendance WHERE branch_id IS NULL OR company_id IS NULL;
  
  IF record_count = 0 THEN
    ALTER TABLE public.attendance ALTER COLUMN branch_id SET NOT NULL;
    ALTER TABLE public.attendance ALTER COLUMN company_id SET NOT NULL;
    RAISE NOTICE '✅ Set branch_id and company_id as NOT NULL';
  ELSE
    RAISE NOTICE '⚠️  Found % records with NULL branch_id or company_id - manual fix required', record_count;
  END IF;
END $$;

-- ============================================
-- 4. ADD INDEXES
-- ============================================

DO $$ 
BEGIN
  RAISE NOTICE '🔧 Creating indexes...';
END $$;

CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON public.attendance(company_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_attendance_branch_id ON public.attendance(branch_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_attendance_deleted_at ON public.attendance(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_attendance_company_date ON public.attendance(company_id, check_in) WHERE deleted_at IS NULL;

DO $$ 
BEGIN
  RAISE NOTICE '✅ Indexes created';
END $$;

-- ============================================
-- 5. UPDATE RLS POLICIES
-- ============================================

DO $$ 
BEGIN
  RAISE NOTICE '🔧 Updating RLS policies...';
END $$;

-- Drop old policies
DROP POLICY IF EXISTS "company_attendance_select" ON public.attendance;
DROP POLICY IF EXISTS "users_insert_own_attendance" ON public.attendance;
DROP POLICY IF EXISTS "users_update_own_attendance" ON public.attendance;
DROP POLICY IF EXISTS "managers_delete_attendance" ON public.attendance;
DROP POLICY IF EXISTS "Users can view attendance in their company" ON public.attendance;
DROP POLICY IF EXISTS "Users can check in" ON public.attendance;
DROP POLICY IF EXISTS "Users can check out" ON public.attendance;
DROP POLICY IF EXISTS "Managers can delete attendance" ON public.attendance;

-- Create optimized policies using company_id directly
CREATE POLICY "attendance_select_policy" ON public.attendance
  FOR SELECT
  TO authenticated
  USING (
    deleted_at IS NULL
    AND (
      -- User can see their own attendance
      user_id = auth.uid()
      OR
      -- CEO/Manager can see all attendance in their company
      company_id IN (
        SELECT company_id FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('ceo', 'manager')
        AND company_id IS NOT NULL
      )
    )
  );

CREATE POLICY "attendance_insert_policy" ON public.attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND deleted_at IS NULL
    -- Company must match user's company
    AND company_id IN (
      SELECT company_id FROM public.users WHERE id = auth.uid() AND company_id IS NOT NULL
    )
  );

CREATE POLICY "attendance_update_policy" ON public.attendance
  FOR UPDATE
  TO authenticated
  USING (
    deleted_at IS NULL
    AND (
      -- User can update their own attendance (check-out)
      user_id = auth.uid()
      OR
      -- CEO/Manager can update attendance in their company
      company_id IN (
        SELECT company_id FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('ceo', 'manager')
        AND company_id IS NOT NULL
      )
    )
  )
  WITH CHECK (
    deleted_at IS NULL
    AND (
      user_id = auth.uid()
      OR
      company_id IN (
        SELECT company_id FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('ceo', 'manager')
        AND company_id IS NOT NULL
      )
    )
  );

CREATE POLICY "attendance_delete_policy" ON public.attendance
  FOR DELETE
  TO authenticated
  USING (
    -- Only CEO/Manager can delete (soft delete preferred)
    company_id IN (
      SELECT company_id FROM public.users 
      WHERE id = auth.uid() 
      AND role IN ('ceo', 'manager')
      AND company_id IS NOT NULL
    )
  );

DO $$ 
BEGIN
  RAISE NOTICE '✅ RLS policies updated';
END $$;

-- ============================================
-- 6. ADD HELPFUL FUNCTIONS
-- ============================================

DO $$ 
BEGIN
  RAISE NOTICE '🔧 Creating helper functions...';
END $$;

-- Function to prevent duplicate check-in on same day
CREATE OR REPLACE FUNCTION prevent_duplicate_checkin()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.check_in IS NOT NULL THEN
    -- Check if user already has attendance today
    IF EXISTS (
      SELECT 1 FROM public.attendance
      WHERE user_id = NEW.user_id
        AND DATE(check_in) = DATE(NEW.check_in)
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        AND deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'User already checked in today';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS attendance_prevent_duplicate ON public.attendance;
CREATE TRIGGER attendance_prevent_duplicate
  BEFORE INSERT OR UPDATE ON public.attendance
  FOR EACH ROW
  EXECUTE FUNCTION prevent_duplicate_checkin();

DO $$ 
BEGIN
  RAISE NOTICE '✅ Helper functions created';
END $$;

-- ============================================
-- 7. VERIFICATION
-- ============================================

DO $$
DECLARE
  total_attendance INTEGER;
  with_branch INTEGER;
  with_company INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_attendance FROM public.attendance WHERE deleted_at IS NULL;
  SELECT COUNT(*) INTO with_branch FROM public.attendance WHERE branch_id IS NOT NULL AND deleted_at IS NULL;
  SELECT COUNT(*) INTO with_company FROM public.attendance WHERE company_id IS NOT NULL AND deleted_at IS NULL;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== MIGRATION SUMMARY ===';
  RAISE NOTICE 'Total attendance records: %', total_attendance;
  RAISE NOTICE 'Records with branch_id: %', with_branch;
  RAISE NOTICE 'Records with company_id: %', with_company;
  RAISE NOTICE '';
  RAISE NOTICE '✅ ATTENDANCE SCHEMA MIGRATION COMPLETED';
  RAISE NOTICE '========================';
END $$;

