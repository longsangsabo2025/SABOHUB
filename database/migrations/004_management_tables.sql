-- ===================================
-- MANAGEMENT TABLES MIGRATION
-- Phase 2 - Operations, Staff, Tasks, Notifications, Activities
-- ===================================

-- Enable UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===================================
-- TASKS TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('HIGH', 'MEDIUM', 'LOW')),
  status TEXT NOT NULL DEFAULT 'TODO' CHECK (status IN ('TODO', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  category TEXT NOT NULL DEFAULT 'OTHER' CHECK (category IN ('OPERATIONS', 'MAINTENANCE', 'INVENTORY', 'CUSTOMER_SERVICE', 'OTHER')),
  assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL,
  due_date TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE
);

-- Index for tasks
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON public.tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_store_id ON public.tasks(store_id);

-- ===================================
-- NOTIFICATIONS TABLE  
-- ===================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'INFO' CHECK (type IN ('SYSTEM', 'REVENUE', 'STAFF', 'TABLES', 'ALERT', 'INFO')),
  priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('HIGH', 'MEDIUM', 'LOW')),
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  action_url TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON public.notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ===================================
-- ACTIVITIES TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS public.activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL CHECK (type IN ('TABLE_START', 'TABLE_END', 'ORDER', 'PAYMENT', 'MAINTENANCE', 'CHECK_IN', 'CHECK_OUT')),
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  details JSONB,
  staff_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  staff_name TEXT,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  table_id UUID REFERENCES public.tables(id) ON DELETE SET NULL,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for activities
CREATE INDEX IF NOT EXISTS idx_activities_timestamp ON public.activities(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_activities_type ON public.activities(type);
CREATE INDEX IF NOT EXISTS idx_activities_shift_id ON public.activities(shift_id);
CREATE INDEX IF NOT EXISTS idx_activities_staff_id ON public.activities(staff_id);
CREATE INDEX IF NOT EXISTS idx_activities_date ON public.activities(DATE(timestamp));

-- ===================================
-- ENHANCE SHIFTS TABLE
-- ===================================
-- Add missing columns to shifts table if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shifts' AND column_name = 'status') 
  THEN
    ALTER TABLE public.shifts ADD COLUMN status TEXT DEFAULT 'PLANNED' 
      CHECK (status IN ('PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shifts' AND column_name = 'revenue') 
  THEN
    ALTER TABLE public.shifts ADD COLUMN revenue DECIMAL(10, 2) DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shifts' AND column_name = 'activities_count') 
  THEN
    ALTER TABLE public.shifts ADD COLUMN activities_count INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shifts' AND column_name = 'actual_start_time') 
  THEN
    ALTER TABLE public.shifts ADD COLUMN actual_start_time TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shifts' AND column_name = 'actual_end_time') 
  THEN
    ALTER TABLE public.shifts ADD COLUMN actual_end_time TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shifts' AND column_name = 'notes') 
  THEN
    ALTER TABLE public.shifts ADD COLUMN notes TEXT;
  END IF;
END $$;

-- ===================================
-- ENHANCE USERS TABLE FOR STAFF MANAGEMENT
-- ===================================
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'status') 
  THEN
    ALTER TABLE public.users ADD COLUMN status TEXT DEFAULT 'ACTIVE' 
      CHECK (status IN ('ACTIVE', 'INACTIVE', 'ON_LEAVE'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'hire_date') 
  THEN
    ALTER TABLE public.users ADD COLUMN hire_date DATE DEFAULT CURRENT_DATE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'monthly_salary') 
  THEN
    ALTER TABLE public.users ADD COLUMN monthly_salary DECIMAL(10, 2) DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'performance_score') 
  THEN
    ALTER TABLE public.users ADD COLUMN performance_score DECIMAL(3, 1) DEFAULT 7.0 
      CHECK (performance_score >= 0 AND performance_score <= 10);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'total_shifts') 
  THEN
    ALTER TABLE public.users ADD COLUMN total_shifts INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'completed_tasks') 
  THEN
    ALTER TABLE public.users ADD COLUMN completed_tasks INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'attendance_rate') 
  THEN
    ALTER TABLE public.users ADD COLUMN attendance_rate DECIMAL(5, 2) DEFAULT 100.00;
  END IF;
END $$;

-- ===================================
-- TRIGGERS FOR AUTO-UPDATE
-- ===================================

-- Auto-update updated_at timestamp for tasks
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tasks_updated_at
BEFORE UPDATE ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Auto-set read_at when marking notification as read
CREATE OR REPLACE FUNCTION set_notification_read_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
    NEW.read_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notification_read_at
BEFORE UPDATE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION set_notification_read_at();

-- Auto-set completed_at when task is completed
CREATE OR REPLACE FUNCTION set_task_completed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
    NEW.completed_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_task_completed_at
BEFORE UPDATE ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION set_task_completed_at();

-- ===================================
-- GRANT PERMISSIONS
-- ===================================
GRANT ALL ON public.tasks TO authenticated;
GRANT ALL ON public.notifications TO authenticated;
GRANT ALL ON public.activities TO authenticated;

-- ===================================
-- COMMENTS FOR DOCUMENTATION
-- ===================================
COMMENT ON TABLE public.tasks IS 'Task management system with priorities and assignments';
COMMENT ON TABLE public.notifications IS 'Real-time notification system for users';
COMMENT ON TABLE public.activities IS 'Activity log for tracking all system events';
COMMENT ON COLUMN public.users.performance_score IS 'Performance rating from 0-10';
COMMENT ON COLUMN public.users.attendance_rate IS 'Attendance rate percentage 0-100';

