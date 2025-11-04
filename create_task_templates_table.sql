-- Task Templates Table for Recurring Tasks
-- This table stores templates for tasks that repeat daily/weekly/monthly

CREATE TABLE IF NOT EXISTS task_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  
  -- Template Info
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('checklist', 'sop', 'kpi', 'training', 'maintenance', 'operations', 'other')),
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  
  -- Recurrence Pattern
  recurrence_pattern TEXT NOT NULL CHECK (recurrence_pattern IN ('daily', 'weekly', 'monthly', 'custom')),
  scheduled_time TIME, -- Time of day to create task (e.g., '08:00:00')
  scheduled_days INTEGER[], -- For weekly: [1,2,3,4,5] = Mon-Fri, For monthly: [1,15,30] = 1st, 15th, 30th
  
  -- Assignment
  assigned_role TEXT CHECK (assigned_role IN ('ceo', 'manager', 'shift_leader', 'staff', 'any')),
  assigned_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Task Details
  estimated_duration INTEGER, -- in minutes
  checklist_items JSONB, -- Array of checklist items if category = 'checklist'
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  last_generated_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- AI Source
  ai_suggestion_id TEXT, -- Link back to original AI suggestion
  ai_confidence FLOAT -- AI confidence score (0-1)
);

-- Indexes
CREATE INDEX idx_task_templates_company ON task_templates(company_id);
CREATE INDEX idx_task_templates_active ON task_templates(is_active);
CREATE INDEX idx_task_templates_recurrence ON task_templates(recurrence_pattern);
CREATE INDEX idx_task_templates_branch ON task_templates(branch_id);

-- Table to track generated tasks from templates
CREATE TABLE IF NOT EXISTS recurring_task_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES task_templates(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(template_id, scheduled_date) -- One instance per template per day
);

CREATE INDEX idx_recurring_instances_template ON recurring_task_instances(template_id);
CREATE INDEX idx_recurring_instances_task ON recurring_task_instances(task_id);
CREATE INDEX idx_recurring_instances_date ON recurring_task_instances(scheduled_date);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_task_template_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER task_templates_updated_at
  BEFORE UPDATE ON task_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_task_template_updated_at();

-- RLS Policies (Row Level Security)
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_task_instances ENABLE ROW LEVEL SECURITY;

-- Allow all operations for now (will refine later)
CREATE POLICY task_templates_all ON task_templates FOR ALL USING (true);
CREATE POLICY recurring_instances_all ON recurring_task_instances FOR ALL USING (true);

COMMENT ON TABLE task_templates IS 'Templates for recurring tasks (daily/weekly/monthly)';
COMMENT ON TABLE recurring_task_instances IS 'Tracks which tasks were generated from which templates';
