-- Tasks Management Schema
-- Phase 9: Task Assignment System

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'cancelled')),
  deadline TIMESTAMPTZ,
  assigned_to UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

-- Task attachments
CREATE TABLE IF NOT EXISTS task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Task progress notes
CREATE TABLE IF NOT EXISTS task_progress_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  note TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Task reminders log
CREATE TABLE IF NOT EXISTS task_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('before_deadline', 'overdue', 'completed')),
  sent_to UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_store_id ON tasks(store_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_by ON tasks(assigned_by);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON tasks(deadline);
CREATE INDEX IF NOT EXISTS idx_task_attachments_task_id ON task_attachments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_progress_notes_task_id ON task_progress_notes(task_id);
CREATE INDEX IF NOT EXISTS idx_task_reminders_task_id ON task_reminders(task_id);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_tasks_updated_at();

-- RLS Policies
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_progress_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_reminders ENABLE ROW LEVEL SECURITY;

-- Tasks policies
CREATE POLICY "Users can view tasks in their store"
  ON tasks FOR SELECT
  USING (
    store_id IN (
      SELECT store_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Managers can create tasks"
  ON tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND store_id = tasks.store_id
      AND role IN ('ceo', 'general_manager', 'shift_leader')
    )
  );

CREATE POLICY "Assigned users and managers can update tasks"
  ON tasks FOR UPDATE
  USING (
    assigned_to = auth.uid()
    OR EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND store_id = tasks.store_id
      AND role IN ('ceo', 'general_manager', 'shift_leader')
    )
  );

CREATE POLICY "Managers can delete tasks"
  ON tasks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND store_id = tasks.store_id
      AND role IN ('ceo', 'general_manager')
    )
  );

-- Task attachments policies
CREATE POLICY "Users can view attachments of tasks they can see"
  ON task_attachments FOR SELECT
  USING (
    task_id IN (
      SELECT id FROM tasks
      WHERE store_id IN (
        SELECT store_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can add attachments to tasks"
  ON task_attachments FOR INSERT
  WITH CHECK (
    task_id IN (
      SELECT id FROM tasks
      WHERE store_id IN (
        SELECT store_id FROM users WHERE id = auth.uid()
      )
    )
  );

-- Task progress notes policies
CREATE POLICY "Users can view notes of tasks they can see"
  ON task_progress_notes FOR SELECT
  USING (
    task_id IN (
      SELECT id FROM tasks
      WHERE store_id IN (
        SELECT store_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can add notes to tasks"
  ON task_progress_notes FOR INSERT
  WITH CHECK (
    task_id IN (
      SELECT id FROM tasks
      WHERE store_id IN (
        SELECT store_id FROM users WHERE id = auth.uid()
      )
    )
  );

-- Task reminders policies
CREATE POLICY "Users can view their reminders"
  ON task_reminders FOR SELECT
  USING (sent_to = auth.uid());

CREATE POLICY "System can create reminders"
  ON task_reminders FOR INSERT
  WITH CHECK (true);
