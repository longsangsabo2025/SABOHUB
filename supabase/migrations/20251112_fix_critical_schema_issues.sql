-- ============================================
-- CRITICAL SCHEMA FIXES - PHASE 1
-- ============================================
-- Migration: fix_critical_schema_issues
-- Date: 2025-11-12
-- Priority: P0 - IMMEDIATE
-- Description: Fix critical mismatches between backend schema and frontend expectations
-- Based on: SUPABASE-FRONTEND-AUDIT-REPORT.md
-- ============================================

-- ============================================
-- 1. FIX ATTENDANCE TABLE SCHEMA
-- ============================================

RAISE NOTICE '🔧 Fixing attendance table schema...';

-- Drop old foreign key constraint
ALTER TABLE IF EXISTS public.attendance 
  DROP CONSTRAINT IF EXISTS attendance_store_id_fkey;

-- Rename store_id to branch_id
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'attendance' AND column_name = 'store_id'
  ) THEN
    ALTER TABLE public.attendance RENAME COLUMN store_id TO branch_id;
    RAISE NOTICE '✅ Renamed store_id to branch_id in attendance table';
  ELSE
    RAISE NOTICE '✅ Column branch_id already exists in attendance table';
  END IF;
END $$;

-- Add new foreign key to branches table
ALTER TABLE public.attendance 
  ADD CONSTRAINT attendance_branch_id_fkey 
  FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

-- Add missing columns
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS employee_name TEXT;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS employee_role TEXT;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_in_latitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_in_longitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_out_latitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_out_longitude DOUBLE PRECISION;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON public.attendance(company_id);
CREATE INDEX IF NOT EXISTS idx_attendance_branch_id ON public.attendance(branch_id);

-- Add comments
COMMENT ON COLUMN public.attendance.company_id IS 'Company this attendance record belongs to';
COMMENT ON COLUMN public.attendance.employee_name IS 'Cached employee name for performance';
COMMENT ON COLUMN public.attendance.employee_role IS 'Cached employee role for performance';
COMMENT ON COLUMN public.attendance.check_in_latitude IS 'GPS latitude at check-in';
COMMENT ON COLUMN public.attendance.check_in_longitude IS 'GPS longitude at check-in';
COMMENT ON COLUMN public.attendance.check_out_latitude IS 'GPS latitude at check-out';
COMMENT ON COLUMN public.attendance.check_out_longitude IS 'GPS longitude at check-out';

RAISE NOTICE '✅ Attendance table schema fixed';

-- ============================================
-- 2. FIX TASKS TABLE RLS POLICIES
-- ============================================

RAISE NOTICE '🔧 Fixing tasks table RLS policies...';

-- Drop all existing policies that reference 'profiles' table
DROP POLICY IF EXISTS "CEO can view all tasks" ON public.tasks;
DROP POLICY IF EXISTS "Manager can view all tasks" ON public.tasks;
DROP POLICY IF EXISTS "Staff can view their own tasks" ON public.tasks;
DROP POLICY IF EXISTS "CEO and Manager can create tasks" ON public.tasks;
DROP POLICY IF EXISTS "CEO and Manager can update tasks" ON public.tasks;
DROP POLICY IF EXISTS "Staff can update their own tasks" ON public.tasks;
DROP POLICY IF EXISTS "CEO can delete tasks" ON public.tasks;

-- Create CORRECT policies using 'users' table
CREATE POLICY "CEO can view all tasks" ON public.tasks
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
    )
  );

CREATE POLICY "Manager can view tasks in company" ON public.tasks
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
      AND users.company_id = tasks.company_id
    )
  );

CREATE POLICY "Staff can view their assigned tasks" ON public.tasks
  FOR SELECT
  TO authenticated
  USING (
    assignee_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.company_id = tasks.company_id
    )
  );

CREATE POLICY "CEO and Manager can create tasks" ON public.tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
      AND users.company_id = tasks.company_id
    )
  );

CREATE POLICY "CEO and Manager can update tasks" ON public.tasks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
      AND users.company_id = tasks.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
      AND users.company_id = tasks.company_id
    )
  );

CREATE POLICY "Staff can update their own tasks status" ON public.tasks
  FOR UPDATE
  TO authenticated
  USING (assignee_id = auth.uid())
  WITH CHECK (assignee_id = auth.uid());

CREATE POLICY "CEO can delete tasks" ON public.tasks
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
      AND users.company_id = tasks.company_id
    )
  );

RAISE NOTICE '✅ Tasks RLS policies fixed';

-- ============================================
-- 3. FIX STORAGE BUCKET POLICIES
-- ============================================

RAISE NOTICE '🔧 Fixing storage bucket policies...';

-- Drop old policies that reference 'profiles' table
DROP POLICY IF EXISTS "Users can upload AI files to their company" ON storage.objects;
DROP POLICY IF EXISTS "Users can view AI files from their company" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete AI files from their company" ON storage.objects;

-- Create CORRECT policies using 'users' table
CREATE POLICY "Users can upload AI files to their company"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'ai-files' AND
  (storage.foldername(name))[1] IN (
    SELECT c.id::text
    FROM companies c
    INNER JOIN users u ON u.company_id = c.id
    WHERE u.id = auth.uid()
  )
);

CREATE POLICY "Users can view AI files from their company"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'ai-files' AND
  (storage.foldername(name))[1] IN (
    SELECT c.id::text
    FROM companies c
    INNER JOIN users u ON u.company_id = c.id
    WHERE u.id = auth.uid()
  )
);

CREATE POLICY "Users can delete AI files from their company"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'ai-files' AND
  (storage.foldername(name))[1] IN (
    SELECT c.id::text
    FROM companies c
    INNER JOIN users u ON u.company_id = c.id
    WHERE u.id = auth.uid()
  )
);

RAISE NOTICE '✅ Storage bucket policies fixed';

-- ============================================
-- 4. UPDATE ATTENDANCE RLS POLICIES
-- ============================================

RAISE NOTICE '🔧 Updating attendance RLS policies to use company_id...';

-- Drop old policies
DROP POLICY IF EXISTS "company_attendance_select" ON public.attendance;
DROP POLICY IF EXISTS "users_insert_own_attendance" ON public.attendance;
DROP POLICY IF EXISTS "users_update_own_attendance" ON public.attendance;
DROP POLICY IF EXISTS "managers_delete_attendance" ON public.attendance;

-- Create new policies using company_id
CREATE POLICY "Users can view attendance in their company" ON public.attendance
  FOR SELECT
  TO authenticated
  USING (
    -- User can see their own attendance
    user_id = auth.uid()
    OR
    -- CEO/Manager can see all attendance in their company
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
      AND users.company_id = attendance.company_id
    )
  );

CREATE POLICY "Users can check in" ON public.attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND
    company_id IN (
      SELECT company_id FROM public.users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can check out" ON public.attendance
  FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = user_id
    OR
    -- CEO/Manager can update attendance in their company
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
      AND users.company_id = attendance.company_id
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
      AND users.company_id = attendance.company_id
    )
  );

CREATE POLICY "Managers can delete attendance" ON public.attendance
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
      AND users.company_id = attendance.company_id
    )
  );

RAISE NOTICE '✅ Attendance RLS policies updated';

-- ============================================
-- 5. ADD MISSING COLUMNS TO BRANCHES
-- ============================================

RAISE NOTICE '🔧 Adding missing columns to branches table...';

-- Add code column
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS code TEXT;

-- Add manager_id if not exists (it should exist from multi_company_architecture migration)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'manager_id'
  ) THEN
    ALTER TABLE public.branches ADD COLUMN manager_id UUID REFERENCES public.users(id);
    RAISE NOTICE '✅ Added manager_id column to branches table';
  ELSE
    RAISE NOTICE '✅ manager_id column already exists in branches table';
  END IF;
END $$;

-- Create index
CREATE INDEX IF NOT EXISTS idx_branches_manager_id ON public.branches(manager_id);
CREATE INDEX IF NOT EXISTS idx_branches_code ON public.branches(code) WHERE code IS NOT NULL;

-- Add comments
COMMENT ON COLUMN public.branches.code IS 'Unique branch code for identification';
COMMENT ON COLUMN public.branches.manager_id IS 'Branch manager user ID';

RAISE NOTICE '✅ Branches table columns added';

-- ============================================
-- 6. ENSURE COMPANIES TABLE HAS ALL FIELDS
-- ============================================

RAISE NOTICE '🔧 Verifying companies table schema...';

-- Add missing columns if they don't exist
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS legal_name TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS tax_code TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS primary_color TEXT DEFAULT '#007AFF';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS secondary_color TEXT DEFAULT '#5856D6';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{
  "timezone": "Asia/Ho_Chi_Minh",
  "currency": "VND",
  "locale": "vi-VN",
  "features": {}
}'::jsonb;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- Add soft delete support
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_companies_deleted_at ON public.companies(deleted_at) WHERE deleted_at IS NULL;

-- Add comments
COMMENT ON COLUMN public.companies.legal_name IS 'Official legal name of the company';
COMMENT ON COLUMN public.companies.tax_code IS 'Tax identification number';
COMMENT ON COLUMN public.companies.website IS 'Company website URL';
COMMENT ON COLUMN public.companies.settings IS 'Company-wide settings and preferences';
COMMENT ON COLUMN public.companies.created_by IS 'User who created the company record';
COMMENT ON COLUMN public.companies.deleted_at IS 'Soft delete timestamp';

RAISE NOTICE '✅ Companies table schema verified';

-- ============================================
-- 7. ADD PROGRESS COLUMN TO TASKS IF MISSING
-- ============================================

RAISE NOTICE '🔧 Ensuring tasks table has progress column...';

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'progress'
  ) THEN
    ALTER TABLE public.tasks ADD COLUMN progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100);
    RAISE NOTICE '✅ Added progress column to tasks table';
  ELSE
    RAISE NOTICE '✅ Progress column already exists in tasks table';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tasks_progress ON public.tasks(progress);
COMMENT ON COLUMN public.tasks.progress IS 'Task completion percentage (0-100)';

RAISE NOTICE '✅ Tasks progress column verified';

-- ============================================
-- 8. POPULATE COMPANY_ID IN ATTENDANCE RECORDS
-- ============================================

RAISE NOTICE '🔧 Populating company_id in existing attendance records...';

-- Update company_id based on user's company
UPDATE public.attendance
SET company_id = (
  SELECT company_id 
  FROM public.users 
  WHERE users.id = attendance.user_id
)
WHERE company_id IS NULL;

-- Update employee_name and employee_role from users table
UPDATE public.attendance
SET 
  employee_name = (SELECT name FROM public.users WHERE users.id = attendance.user_id),
  employee_role = (SELECT role FROM public.users WHERE users.id = attendance.user_id)
WHERE employee_name IS NULL OR employee_role IS NULL;

RAISE NOTICE '✅ Attendance records populated with company_id';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

RAISE NOTICE '============================================';
RAISE NOTICE '✅ MIGRATION COMPLETED SUCCESSFULLY';
RAISE NOTICE '============================================';

-- Verify attendance table
DO $$
DECLARE
  attendance_columns TEXT;
BEGIN
  SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
  INTO attendance_columns
  FROM information_schema.columns
  WHERE table_name = 'attendance';
  
  RAISE NOTICE 'Attendance columns: %', attendance_columns;
END $$;

-- Verify tasks policies
DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO policy_count
  FROM pg_policies
  WHERE tablename = 'tasks';
  
  RAISE NOTICE 'Tasks policies count: %', policy_count;
END $$;

-- Verify storage policies
DO $$
DECLARE
  storage_policy_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO storage_policy_count
  FROM pg_policies
  WHERE tablename = 'objects' AND schemaname = 'storage';
  
  RAISE NOTICE 'Storage policies count: %', storage_policy_count;
END $$;

RAISE NOTICE '============================================';
RAISE NOTICE '📋 NEXT STEPS:';
RAISE NOTICE '1. Test attendance check-in/check-out functionality';
RAISE NOTICE '2. Verify tasks CRUD for all user roles';
RAISE NOTICE '3. Test AI file upload/download';
RAISE NOTICE '4. Update frontend models as per audit report';
RAISE NOTICE '============================================';

