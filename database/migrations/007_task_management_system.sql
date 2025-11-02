-- ============================================
-- Migration 007: Task Management System
-- Created: ${new Date().toISOString()}
-- Purpose: Complete task management, checklists, KPI tracking, and automation
-- ============================================

-- ==========================================
-- 1. TASK TEMPLATES (Mẫu công việc tự động)
-- ==========================================
CREATE TABLE IF NOT EXISTS task_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100), -- cleaning, food_prep, opening, closing, custom
  default_duration INT DEFAULT 30, -- minutes
  default_priority VARCHAR(20) DEFAULT 'medium' CHECK (default_priority IN ('low', 'medium', 'high', 'urgent')),
  requires_photo BOOLEAN DEFAULT FALSE,
  min_photos INT DEFAULT 0,
  checklist_items JSONB DEFAULT '[]', -- array of checklist items
  recurrence_rule VARCHAR(50), -- daily, weekly, monthly
  recurrence_time TIME,
  recurrence_days INT[], -- 0=Sunday, 1=Monday, etc.
  applicable_roles TEXT[] DEFAULT ARRAY['STAFF'], -- which roles can be assigned
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_task_templates_active ON task_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_task_templates_category ON task_templates(category);

-- ==========================================
-- 2. TASKS (Nhiệm vụ)
-- ==========================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(50) DEFAULT 'one_time' CHECK (type IN ('daily', 'one_time', 'recurring')),
  template_id UUID REFERENCES task_templates(id) ON DELETE SET NULL,
  assigned_to UUID NOT NULL, -- user_id
  assigned_to_name VARCHAR(255),
  created_by UUID NOT NULL,
  created_by_name VARCHAR(255),
  priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue', 'cancelled')),
  due_date DATE NOT NULL,
  due_time TIME,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  estimated_duration INT, -- minutes
  actual_duration INT, -- minutes
  requires_photo BOOLEAN DEFAULT FALSE,
  photo_count INT DEFAULT 0,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  reminder_sent BOOLEAN DEFAULT FALSE,
  reminder_sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_assigned ON tasks(assigned_to, status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date, status);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_template ON tasks(template_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by);

-- ==========================================
-- 3. TASK REPORTS (Báo cáo hoàn thành)
-- ==========================================
CREATE TABLE IF NOT EXISTS task_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  user_name VARCHAR(255),
  status VARCHAR(20) CHECK (status IN ('completed', 'partial', 'failed')),
  completion_rate DECIMAL(5,2) DEFAULT 100.00, -- percentage
  notes TEXT,
  photos TEXT[] DEFAULT ARRAY[]::TEXT[], -- array of Supabase storage URLs
  checklist_data JSONB DEFAULT '{}', -- completed checklist items
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_by UUID,
  reviewed_by_name VARCHAR(255),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  quality_score INT CHECK (quality_score BETWEEN 1 AND 5),
  feedback TEXT
);

CREATE INDEX IF NOT EXISTS idx_task_reports_task ON task_reports(task_id);
CREATE INDEX IF NOT EXISTS idx_task_reports_user ON task_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_task_reports_submitted ON task_reports(submitted_at DESC);

-- ==========================================
-- 4. DAILY CHECKLISTS (Checklist hàng ngày)
-- ==========================================
CREATE TABLE IF NOT EXISTS daily_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) CHECK (type IN ('opening', 'closing', 'cleaning', 'food_prep', 'custom')),
  description TEXT,
  items JSONB NOT NULL DEFAULT '[]', -- array of checklist items with structure
  required_photos INT DEFAULT 0,
  applicable_shifts TEXT[] DEFAULT ARRAY['morning', 'afternoon', 'evening'],
  applicable_roles TEXT[] DEFAULT ARRAY['STAFF'],
  is_active BOOLEAN DEFAULT TRUE,
  display_order INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_daily_checklists_type ON daily_checklists(type);
CREATE INDEX IF NOT EXISTS idx_daily_checklists_active ON daily_checklists(is_active);

-- ==========================================
-- 5. CHECKLIST SUBMISSIONS (Nộp checklist)
-- ==========================================
CREATE TABLE IF NOT EXISTS checklist_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID REFERENCES daily_checklists(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  user_name VARCHAR(255),
  shift_id UUID,
  submission_date DATE NOT NULL,
  items_data JSONB NOT NULL DEFAULT '{}', -- completed items with timestamps and photos
  photos TEXT[] DEFAULT ARRAY[]::TEXT[],
  completion_rate DECIMAL(5,2),
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT,
  UNIQUE(checklist_id, user_id, submission_date)
);

CREATE INDEX IF NOT EXISTS idx_checklist_submissions_checklist ON checklist_submissions(checklist_id);
CREATE INDEX IF NOT EXISTS idx_checklist_submissions_user ON checklist_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_checklist_submissions_date ON checklist_submissions(submission_date DESC);

-- ==========================================
-- 6. KPI TARGETS (Chỉ tiêu KPI)
-- ==========================================
CREATE TABLE IF NOT EXISTS kpi_targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  role VARCHAR(50),
  metric_name VARCHAR(100) NOT NULL,
  metric_type VARCHAR(50) CHECK (metric_type IN ('completion_rate', 'quality_score', 'timeliness', 'photo_submission', 'custom')),
  target_value DECIMAL(10,2) NOT NULL,
  period VARCHAR(20) CHECK (period IN ('daily', 'weekly', 'monthly')) DEFAULT 'weekly',
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kpi_targets_user ON kpi_targets(user_id);
CREATE INDEX IF NOT EXISTS idx_kpi_targets_role ON kpi_targets(role);
CREATE INDEX IF NOT EXISTS idx_kpi_targets_active ON kpi_targets(is_active);

-- ==========================================
-- 7. PERFORMANCE METRICS (Đo lường hiệu suất)
-- ==========================================
CREATE TABLE IF NOT EXISTS performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  user_name VARCHAR(255),
  metric_date DATE NOT NULL,
  tasks_assigned INT DEFAULT 0,
  tasks_completed INT DEFAULT 0,
  tasks_overdue INT DEFAULT 0,
  tasks_cancelled INT DEFAULT 0,
  completion_rate DECIMAL(5,2),
  avg_quality_score DECIMAL(3,2),
  on_time_rate DECIMAL(5,2),
  photo_submission_rate DECIMAL(5,2),
  total_work_duration INT DEFAULT 0, -- minutes
  checklists_completed INT DEFAULT 0,
  incidents_reported INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, metric_date)
);

CREATE INDEX IF NOT EXISTS idx_performance_metrics_user ON performance_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_date ON performance_metrics(metric_date DESC);

-- ==========================================
-- 8. INCIDENT REPORTS (Báo cáo sự cố)
-- ==========================================
CREATE TABLE IF NOT EXISTS incident_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reported_by UUID NOT NULL,
  reported_by_name VARCHAR(255),
  incident_type VARCHAR(100) NOT NULL, -- equipment_failure, safety_issue, cleanliness, food_quality, customer_complaint, other
  severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
  title VARCHAR(255) NOT NULL,
  description TEXT,
  location VARCHAR(255),
  photos TEXT[] DEFAULT ARRAY[]::TEXT[],
  occurred_at TIMESTAMP WITH TIME ZONE,
  reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'closed')),
  assigned_to UUID,
  assigned_to_name VARCHAR(255),
  resolution TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID,
  resolved_by_name VARCHAR(255),
  priority_escalated BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_incident_reports_reported_by ON incident_reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_incident_reports_status ON incident_reports(status);
CREATE INDEX IF NOT EXISTS idx_incident_reports_severity ON incident_reports(severity);
CREATE INDEX IF NOT EXISTS idx_incident_reports_date ON incident_reports(reported_at DESC);

-- ==========================================
-- 9. AUTO TASK SCHEDULE (Lịch tự động tạo task)
-- ==========================================
CREATE TABLE IF NOT EXISTS auto_task_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID REFERENCES task_templates(id) ON DELETE CASCADE,
  schedule_time TIME NOT NULL,
  days_of_week INT[] NOT NULL, -- 0=Sunday, 1=Monday, etc.
  assign_to_role VARCHAR(50) NOT NULL,
  assign_to_shift VARCHAR(50), -- morning, afternoon, evening
  is_active BOOLEAN DEFAULT TRUE,
  last_generated_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auto_task_schedule_template ON auto_task_schedule(template_id);
CREATE INDEX IF NOT EXISTS idx_auto_task_schedule_active ON auto_task_schedule(is_active);

-- ==========================================
-- FUNCTIONS & TRIGGERS
-- ==========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER update_task_templates_updated_at BEFORE UPDATE ON task_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_checklists_updated_at BEFORE UPDATE ON daily_checklists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kpi_targets_updated_at BEFORE UPDATE ON kpi_targets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_auto_task_schedule_updated_at BEFORE UPDATE ON auto_task_schedule
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- SAMPLE DATA
-- ==========================================

-- Insert sample task templates
INSERT INTO task_templates (name, description, category, default_duration, default_priority, requires_photo, min_photos, checklist_items, recurrence_rule, recurrence_time, recurrence_days, applicable_roles) VALUES
  ('Mở cửa sáng', 'Chuẩn bị mở cửa quán buổi sáng', 'opening', 30, 'high', TRUE, 2, 
   '[{"id": "1", "text": "Kiểm tra thiết bị bếp", "requires_photo": true}, {"id": "2", "text": "Vệ sinh khu vực phục vụ", "requires_photo": true}, {"id": "3", "text": "Kiểm tra nguyên liệu", "requires_photo": false}]'::jsonb,
   'daily', '07:00:00', ARRAY[1,2,3,4,5,6,0], ARRAY['SHIFT_LEADER', 'STAFF']),
  
  ('Đóng cửa tối', 'Đóng cửa và dọn dẹp cuối ngày', 'closing', 45, 'high', TRUE, 3,
   '[{"id": "1", "text": "Vệ sinh bếp", "requires_photo": true}, {"id": "2", "text": "Kiểm tra thiết bị", "requires_photo": true}, {"id": "3", "text": "Khóa cửa an toàn", "requires_photo": true}]'::jsonb,
   'daily', '22:00:00', ARRAY[1,2,3,4,5,6,0], ARRAY['SHIFT_LEADER', 'MANAGER']),
  
  ('Vệ sinh nhà vệ sinh', 'Vệ sinh và kiểm tra nhà vệ sinh', 'cleaning', 20, 'medium', TRUE, 2,
   '[{"id": "1", "text": "Lau chùi bồn cầu", "requires_photo": true}, {"id": "2", "text": "Kiểm tra giấy vệ sinh", "requires_photo": false}, {"id": "3", "text": "Lau gương", "requires_photo": true}]'::jsonb,
   'daily', '10:00:00', ARRAY[1,2,3,4,5,6,0], ARRAY['STAFF']),
  
  ('Chuẩn bị nguyên liệu', 'Chuẩn bị nguyên liệu cho ca làm việc', 'food_prep', 60, 'high', TRUE, 1,
   '[{"id": "1", "text": "Kiểm tra hạn sử dụng", "requires_photo": true}, {"id": "2", "text": "Chuẩn bị rau củ", "requires_photo": false}, {"id": "3", "text": "Kiểm tra tủ lạnh", "requires_photo": true}]'::jsonb,
   'daily', '08:00:00', ARRAY[1,2,3,4,5,6,0], ARRAY['STAFF'])
ON CONFLICT DO NOTHING;

-- Insert sample daily checklists
INSERT INTO daily_checklists (name, type, description, items, required_photos, applicable_shifts, applicable_roles) VALUES
  ('Checklist mở cửa', 'opening', 'Danh sách công việc mở cửa sáng',
   '[
     {"id": "1", "text": "Bật điện, đèn, điều hòa", "order": 1},
     {"id": "2", "text": "Kiểm tra thiết bị bếp", "order": 2, "requires_photo": true},
     {"id": "3", "text": "Vệ sinh khu vực khách hàng", "order": 3, "requires_photo": true},
     {"id": "4", "text": "Chuẩn bị quầy thu ngân", "order": 4},
     {"id": "5", "text": "Kiểm tra nguyên liệu", "order": 5, "requires_photo": true}
   ]'::jsonb, 3, ARRAY['morning'], ARRAY['SHIFT_LEADER', 'STAFF']),
  
  ('Checklist đóng cửa', 'closing', 'Danh sách công việc đóng cửa tối',
   '[
     {"id": "1", "text": "Tắt tất cả thiết bị bếp", "order": 1},
     {"id": "2", "text": "Vệ sinh bếp và khu vực ăn", "order": 2, "requires_photo": true},
     {"id": "3", "text": "Đối chiếu tiền thu ngân", "order": 3},
     {"id": "4", "text": "Khóa cửa sổ, cửa chính", "order": 4, "requires_photo": true},
     {"id": "5", "text": "Tắt điện, đèn, điều hòa", "order": 5}
   ]'::jsonb, 2, ARRAY['evening'], ARRAY['SHIFT_LEADER', 'MANAGER'])
ON CONFLICT DO NOTHING;

-- Insert sample KPI targets
INSERT INTO kpi_targets (role, metric_name, metric_type, target_value, period, start_date, end_date, is_active) VALUES
  ('STAFF', 'Task Completion Rate', 'completion_rate', 95.00, 'weekly', CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days', TRUE),
  ('STAFF', 'Quality Score', 'quality_score', 4.00, 'weekly', CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days', TRUE),
  ('SHIFT_LEADER', 'Team Completion Rate', 'completion_rate', 98.00, 'weekly', CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days', TRUE),
  ('MANAGER', 'Overall Performance', 'completion_rate', 99.00, 'weekly', CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days', TRUE)
ON CONFLICT DO NOTHING;

-- ==========================================
-- COMMENTS
-- ==========================================

COMMENT ON TABLE task_templates IS 'Templates for recurring and automated tasks';
COMMENT ON TABLE tasks IS 'Individual task assignments to users';
COMMENT ON TABLE task_reports IS 'Task completion reports with photos and quality scores';
COMMENT ON TABLE daily_checklists IS 'Daily checklist templates for opening, closing, cleaning';
COMMENT ON TABLE checklist_submissions IS 'User submissions of daily checklists';
COMMENT ON TABLE kpi_targets IS 'KPI targets for users and roles';
COMMENT ON TABLE performance_metrics IS 'Daily performance metrics for each user';
COMMENT ON TABLE incident_reports IS 'Incident and issue reports with photo evidence';
COMMENT ON TABLE auto_task_schedule IS 'Schedule for automatic task generation';

-- ==========================================
-- END OF MIGRATION
-- ==========================================

