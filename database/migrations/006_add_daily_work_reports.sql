-- Migration: Add daily_work_reports table
-- Auto-generated work reports when employees check out

-- Create daily_work_reports table
CREATE TABLE IF NOT EXISTS public.daily_work_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  check_in_time TIMESTAMPTZ NOT NULL,
  check_out_time TIMESTAMPTZ NOT NULL,
  total_hours DECIMAL(5, 2) NOT NULL DEFAULT 0,

  -- Auto-collected data
  tasks_completed INTEGER DEFAULT 0,
  tasks_assigned INTEGER DEFAULT 0,
  completed_tasks JSONB DEFAULT '[]'::jsonb,
  auto_generated_summary TEXT,

  -- Employee input (optional)
  employee_notes TEXT,
  achievements TEXT[],
  challenges TEXT[],
  tomorrow_plan TEXT,

  -- Status
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'reviewed', 'approved')),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Unique constraint: one report per user per day
  UNIQUE(user_id, date)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_daily_work_reports_user_date 
ON public.daily_work_reports(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_work_reports_company_date 
ON public.daily_work_reports(company_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_work_reports_status 
ON public.daily_work_reports(status);

CREATE INDEX IF NOT EXISTS idx_daily_work_reports_submitted 
ON public.daily_work_reports(submitted_at DESC) 
WHERE submitted_at IS NOT NULL;

-- Enable RLS
ALTER TABLE public.daily_work_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Policy: Users can view their own reports
CREATE POLICY daily_work_reports_select_own 
ON public.daily_work_reports 
FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Managers can view reports of their company employees
CREATE POLICY daily_work_reports_select_manager 
ON public.daily_work_reports 
FOR SELECT 
USING (
  company_id IN (
    SELECT id FROM public.companies 
    WHERE manager_id = auth.uid()
  )
);

-- Policy: Users can insert their own reports
CREATE POLICY daily_work_reports_insert_own 
ON public.daily_work_reports 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own draft reports
CREATE POLICY daily_work_reports_update_own 
ON public.daily_work_reports 
FOR UPDATE 
USING (auth.uid() = user_id AND status = 'draft')
WITH CHECK (auth.uid() = user_id);

-- Policy: Managers can update reports status (review/approve)
CREATE POLICY daily_work_reports_update_manager 
ON public.daily_work_reports 
FOR UPDATE 
USING (
  company_id IN (
    SELECT id FROM public.companies 
    WHERE manager_id = auth.uid()
  )
)
WITH CHECK (
  company_id IN (
    SELECT id FROM public.companies 
    WHERE manager_id = auth.uid()
  )
);

-- Policy: Users can delete their own draft reports
CREATE POLICY daily_work_reports_delete_own 
ON public.daily_work_reports 
FOR DELETE 
USING (auth.uid() = user_id AND status = 'draft');

-- Trigger: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_daily_work_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_daily_work_reports_updated_at 
BEFORE UPDATE ON public.daily_work_reports
FOR EACH ROW
EXECUTE FUNCTION update_daily_work_reports_updated_at();

-- Comments
COMMENT ON TABLE public.daily_work_reports IS 'Auto-generated daily work reports when employees check out';
COMMENT ON COLUMN public.daily_work_reports.completed_tasks IS 'JSON array of TaskSummary objects with task details';
COMMENT ON COLUMN public.daily_work_reports.auto_generated_summary IS 'AI-powered summary of the work day';
COMMENT ON COLUMN public.daily_work_reports.status IS 'Report status: draft, submitted, reviewed, approved';
