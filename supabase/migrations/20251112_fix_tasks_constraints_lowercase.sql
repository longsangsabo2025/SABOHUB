-- Migration: Fix tasks table constraints to use lowercase values
-- Date: 2025-11-12
-- This migration ensures consistency between database and Flutter enum.name behavior
-- All enum-like fields use lowercase to match Dart enum.name output

-- ============================================================================
-- STEP 1: Drop old constraints
-- ============================================================================
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_priority_check;
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_status_check;
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_recurrence_check;

-- ============================================================================
-- STEP 2: Convert existing data to lowercase
-- ============================================================================
UPDATE public.tasks SET priority = LOWER(priority);
UPDATE public.tasks SET status = LOWER(status);
UPDATE public.tasks SET recurrence = LOWER(recurrence);

-- ============================================================================
-- STEP 3: Add new constraints with lowercase values
-- ============================================================================
ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_priority_check 
CHECK (priority IN ('low', 'medium', 'high', 'urgent'));

ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_status_check 
CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'));

ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_recurrence_check 
CHECK (recurrence IN ('none', 'daily', 'weekly', 'monthly', 'adhoc', 'project'));

-- ============================================================================
-- STEP 4: Update default values to lowercase
-- ============================================================================
ALTER TABLE public.tasks ALTER COLUMN priority SET DEFAULT 'medium';
ALTER TABLE public.tasks ALTER COLUMN status SET DEFAULT 'pending';
ALTER TABLE public.tasks ALTER COLUMN recurrence SET DEFAULT 'none';

-- ============================================================================
-- STEP 5: Update users.role constraint to lowercase as well
-- ============================================================================
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;
UPDATE public.users SET role = LOWER(role);
ALTER TABLE public.users 
ADD CONSTRAINT users_role_check 
CHECK (role IN ('ceo', 'manager', 'shift_leader', 'staff'));

-- ============================================================================
-- STEP 6: Add comments for documentation
-- ============================================================================
COMMENT ON COLUMN public.tasks.priority IS 'Task priority level: low, medium, high, urgent (matches Flutter enum.name)';
COMMENT ON COLUMN public.tasks.status IS 'Task status: pending, in_progress, completed, cancelled (matches Flutter enum.name)';
COMMENT ON COLUMN public.tasks.recurrence IS 'Task recurrence pattern: none, daily, weekly, monthly, adhoc, project (matches Flutter enum.name)';
COMMENT ON COLUMN public.tasks.progress IS 'Task completion progress percentage (0-100)';
COMMENT ON COLUMN public.users.role IS 'User role: ceo, manager, shift_leader, staff (matches Flutter enum.name)';

-- Verification query (commented out for migration)
-- SELECT 
--     con.conname AS constraint_name,
--     pg_get_constraintdef(con.oid) AS constraint_definition
-- FROM pg_constraint con
-- JOIN pg_class rel ON rel.oid = con.conrelid
-- JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
-- WHERE rel.relname = 'tasks'
-- AND nsp.nspname = 'public'
-- AND con.contype = 'c'
-- ORDER BY con.conname;
