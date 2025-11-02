-- Create TASKS table for AI Agent task management
-- Migration: Create tasks table with all necessary fields

CREATE TABLE IF NOT EXISTS public.tasks (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Task information
  title TEXT NOT NULL,
  description TEXT,
  category TEXT CHECK (category IN ('inventory', 'customer_service', 'cleaning', 'maintenance', 'admin', 'other')),
  
  -- Assignment
  assignee_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  assignee_name TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Status & Priority
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  
  -- Dates
  deadline TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  
  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS tasks_assignee_id_idx ON public.tasks(assignee_id);
CREATE INDEX IF NOT EXISTS tasks_status_idx ON public.tasks(status);
CREATE INDEX IF NOT EXISTS tasks_created_at_idx ON public.tasks(created_at DESC);
CREATE INDEX IF NOT EXISTS tasks_deadline_idx ON public.tasks(deadline);

-- RLS Policies
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- CEO can see all tasks
CREATE POLICY "CEO can view all tasks"
  ON public.tasks
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'CEO'
    )
  );

-- Manager can see all tasks
CREATE POLICY "Manager can view all tasks"
  ON public.tasks
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('CEO', 'MANAGER')
    )
  );

-- Staff can see their own tasks
CREATE POLICY "Staff can view their own tasks"
  ON public.tasks
  FOR SELECT
  TO authenticated
  USING (
    assignee_id = auth.uid()
  );

-- CEO and Manager can create tasks
CREATE POLICY "CEO and Manager can create tasks"
  ON public.tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('CEO', 'MANAGER')
    )
  );

-- CEO and Manager can update any task
CREATE POLICY "CEO and Manager can update tasks"
  ON public.tasks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('CEO', 'MANAGER')
    )
  );

-- Staff can update their own tasks (status only)
CREATE POLICY "Staff can update their own tasks"
  ON public.tasks
  FOR UPDATE
  TO authenticated
  USING (assignee_id = auth.uid())
  WITH CHECK (assignee_id = auth.uid());

-- CEO can delete tasks
CREATE POLICY "CEO can delete tasks"
  ON public.tasks
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'CEO'
    )
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER tasks_updated_at_trigger
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_tasks_updated_at();

-- Grant permissions
GRANT ALL ON public.tasks TO authenticated;
GRANT ALL ON public.tasks TO service_role;

COMMENT ON TABLE public.tasks IS 'Task management for AI Agent - CEO can assign tasks to employees';
COMMENT ON COLUMN public.tasks.metadata IS 'JSON metadata including source (ai_agent, manual), tags, etc';
