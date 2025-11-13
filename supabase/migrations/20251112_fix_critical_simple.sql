-- ============================================
-- CRITICAL SCHEMA FIXES - PHASE 1 (SIMPLIFIED)
-- ============================================
-- Migration: fix_critical_schema_issues_simplified
-- Date: 2025-11-12
-- Priority: P0 - IMMEDIATE
-- ============================================

-- ============================================
-- 1. FIX ATTENDANCE TABLE SCHEMA
-- ============================================

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
    RAISE NOTICE 'Renamed store_id to branch_id in attendance table';
  END IF;
END $$;

-- Add new foreign key to branches table
ALTER TABLE public.attendance 
  ADD CONSTRAINT attendance_branch_id_fkey 
  FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

-- Add missing columns
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_in_latitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_in_longitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_out_latitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_out_longitude DOUBLE PRECISION;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON public.attendance(company_id);
CREATE INDEX IF NOT EXISTS idx_attendance_branch_id ON public.attendance(branch_id);

-- ============================================
-- 2. FIX TASKS TABLE RLS POLICIES
-- ============================================

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
    assigned_to = auth.uid()
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
  USING (assigned_to = auth.uid())
  WITH CHECK (assigned_to = auth.uid());

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

-- ============================================
-- 3. FIX STORAGE BUCKET POLICIES
-- ============================================

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

-- ============================================
-- 4. UPDATE ATTENDANCE RLS POLICIES
-- ============================================

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
    user_id = auth.uid()
    OR
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

-- ============================================
-- 5. ADD MISSING COLUMNS TO COMPANIES
-- ============================================

ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS legal_name TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id);
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS primary_color TEXT DEFAULT '#007AFF';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS secondary_color TEXT DEFAULT '#5856D6';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{
  "timezone": "Asia/Ho_Chi_Minh",
  "currency": "VND",
  "locale": "vi-VN"
}'::jsonb;

-- ============================================
-- 6. POPULATE COMPANY_ID IN ATTENDANCE
-- ============================================

UPDATE public.attendance
SET company_id = (
  SELECT company_id 
  FROM public.users 
  WHERE users.id = attendance.user_id
)
WHERE company_id IS NULL;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
DECLARE
  att_count INTEGER;
  task_policies INTEGER;
BEGIN
  -- Count attendance columns
  SELECT COUNT(*) INTO att_count
  FROM information_schema.columns
  WHERE table_name = 'attendance' AND column_name IN ('branch_id', 'company_id', 'check_in_latitude');
  
  -- Count task policies
  SELECT COUNT(*) INTO task_policies
  FROM pg_policies
  WHERE tablename = 'tasks';
  
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'MIGRATION COMPLETED';
  RAISE NOTICE 'Attendance new columns: %', att_count;
  RAISE NOTICE 'Tasks policies: %', task_policies;
  RAISE NOTICE '===========================================';
END $$;
