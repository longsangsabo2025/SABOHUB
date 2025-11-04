-- Migration: Ensure attendance table and related structures are ready
-- Date: 2025-11-04
-- Description: Prepare database for attendance feature with real data

-- 1. Ensure attendance table exists with correct structure
CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  check_in TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  check_out TIMESTAMPTZ,
  check_in_location TEXT,
  check_out_location TEXT,
  check_in_photo_url TEXT,
  total_hours DECIMAL(5, 2),
  is_late BOOLEAN DEFAULT false,
  is_early_leave BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add company_id to users table if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE public.users 
    ADD COLUMN company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;
    
    RAISE NOTICE 'Added company_id column to users table';
  ELSE
    RAISE NOTICE 'company_id column already exists in users table';
  END IF;
END $$;

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON public.attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_store_id ON public.attendance(store_id);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in ON public.attendance(check_in);
CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON public.attendance(user_id, check_in);
CREATE INDEX IF NOT EXISTS idx_users_company_id ON public.users(company_id);

-- 4. Create RLS policies for attendance

-- Enable RLS
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view attendance of their own company
DROP POLICY IF EXISTS "company_attendance_select" ON public.attendance;
CREATE POLICY "company_attendance_select" ON public.attendance
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND (
          -- User can see their own attendance
          attendance.user_id = auth.uid()
          OR
          -- CEO/Manager can see all attendance in their company
          (
            users.role IN ('CEO', 'MANAGER') 
            AND users.company_id = (
              SELECT company_id FROM public.users WHERE id = attendance.user_id
            )
          )
        )
    )
  );

-- Policy: Users can insert their own attendance (check-in)
DROP POLICY IF EXISTS "users_insert_own_attendance" ON public.attendance;
CREATE POLICY "users_insert_own_attendance" ON public.attendance
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
  );

-- Policy: Users can update their own attendance (check-out)
DROP POLICY IF EXISTS "users_update_own_attendance" ON public.attendance;
CREATE POLICY "users_update_own_attendance" ON public.attendance
  FOR UPDATE
  USING (
    auth.uid() = user_id
    OR
    -- CEO/Manager can update attendance in their company
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role IN ('CEO', 'MANAGER')
        AND users.company_id = (
          SELECT company_id FROM public.users WHERE id = attendance.user_id
        )
    )
  );

-- Policy: Only CEO/Manager can delete attendance
DROP POLICY IF EXISTS "managers_delete_attendance" ON public.attendance;
CREATE POLICY "managers_delete_attendance" ON public.attendance
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role IN ('CEO', 'MANAGER')
        AND users.company_id = (
          SELECT company_id FROM public.users WHERE id = attendance.user_id
        )
    )
  );

-- 5. Create function to auto-calculate total_hours on check_out
CREATE OR REPLACE FUNCTION calculate_total_hours()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.check_out IS NOT NULL AND NEW.check_in IS NOT NULL THEN
    NEW.total_hours := EXTRACT(EPOCH FROM (NEW.check_out - NEW.check_in)) / 3600.0;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS attendance_calculate_hours ON public.attendance;
CREATE TRIGGER attendance_calculate_hours
  BEFORE INSERT OR UPDATE ON public.attendance
  FOR EACH ROW
  EXECUTE FUNCTION calculate_total_hours();

-- 6. Verification queries
DO $$
BEGIN
  RAISE NOTICE '=== VERIFICATION ===';
  RAISE NOTICE 'Attendance table: Ready';
  RAISE NOTICE 'Indexes: Created';
  RAISE NOTICE 'RLS Policies: Applied';
  RAISE NOTICE 'Triggers: Created';
  RAISE NOTICE '===================';
END $$;

-- Check if data exists
DO $$
DECLARE
  attendance_count INTEGER;
  users_with_company INTEGER;
BEGIN
  SELECT COUNT(*) INTO attendance_count FROM public.attendance;
  SELECT COUNT(*) INTO users_with_company FROM public.users WHERE company_id IS NOT NULL;
  
  RAISE NOTICE 'Total attendance records: %', attendance_count;
  RAISE NOTICE 'Users with company_id: %', users_with_company;
  
  IF attendance_count = 0 THEN
    RAISE NOTICE '⚠️  No attendance data yet. You can add test data or use check-in feature in app.';
  END IF;
  
  IF users_with_company = 0 THEN
    RAISE NOTICE '⚠️  No users with company_id. Please ensure users are assigned to companies.';
  END IF;
END $$;

COMMENT ON TABLE public.attendance IS 'Employee attendance tracking with check-in/check-out';
COMMENT ON COLUMN public.attendance.check_in IS 'Time when employee checked in';
COMMENT ON COLUMN public.attendance.check_out IS 'Time when employee checked out';
COMMENT ON COLUMN public.attendance.total_hours IS 'Total hours worked (auto-calculated)';
COMMENT ON COLUMN public.attendance.is_late IS 'Whether employee was late';
COMMENT ON COLUMN public.attendance.is_early_leave IS 'Whether employee left early';
COMMENT ON COLUMN public.attendance.check_in_location IS 'GPS location at check-in';
COMMENT ON COLUMN public.attendance.check_out_location IS 'GPS location at check-out';
