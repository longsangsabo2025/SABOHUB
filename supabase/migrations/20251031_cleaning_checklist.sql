-- =====================================================
-- CLEANING CHECKLIST SYSTEM - SABO BILLIARDS
-- Migration: 20251031_cleaning_checklist
-- Description: Hệ thống quản lý checklist vệ sinh hàng ngày
-- =====================================================

-- Enable UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: cleaning_checklist_templates
-- Mẫu checklist theo ca (Morning/Evening)
-- =====================================================
CREATE TABLE IF NOT EXISTS cleaning_checklist_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID,
  store_id UUID,
  name VARCHAR(255) NOT NULL,
  shift_type VARCHAR(50) NOT NULL CHECK (shift_type IN ('MORNING', 'EVENING', 'FULL_DAY')),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_cleaning_templates_store ON cleaning_checklist_templates(store_id);
CREATE INDEX idx_cleaning_templates_shift ON cleaning_checklist_templates(shift_type);
CREATE INDEX idx_cleaning_templates_active ON cleaning_checklist_templates(is_active);

-- =====================================================
-- TABLE: cleaning_checklist_items
-- Từng task trong checklist
-- =====================================================
CREATE TABLE IF NOT EXISTS cleaning_checklist_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID REFERENCES cleaning_checklist_templates(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  time_start TIME NOT NULL,
  time_end TIME NOT NULL,
  requires_photo BOOLEAN DEFAULT true,
  photo_locations JSONB DEFAULT '[]', -- ['counter', 'sink_area', 'fridge', 'sofa', 'full_view', 'bathroom']
  order_index INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_cleaning_items_template ON cleaning_checklist_items(template_id);
CREATE INDEX idx_cleaning_items_order ON cleaning_checklist_items(order_index);

-- =====================================================
-- TABLE: cleaning_checklist_logs
-- Lịch sử hoàn thành checklist
-- =====================================================
CREATE TABLE IF NOT EXISTS cleaning_checklist_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID REFERENCES cleaning_checklist_templates(id),
  item_id UUID REFERENCES cleaning_checklist_items(id),
  user_id UUID,
  store_id UUID,
  shift_date DATE NOT NULL,
  shift_type VARCHAR(50) NOT NULL CHECK (shift_type IN ('MORNING', 'EVENING')),
  completed_at TIMESTAMP,
  status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE', 'SKIPPED')),
  photos JSONB DEFAULT '[]', -- Array of photo URLs
  notes TEXT,
  is_on_time BOOLEAN, -- Completed within 15 minutes of time_end
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(item_id, shift_date, shift_type)
);

-- Indexes
CREATE INDEX idx_cleaning_logs_user ON cleaning_checklist_logs(user_id);
CREATE INDEX idx_cleaning_logs_store ON cleaning_checklist_logs(store_id);
CREATE INDEX idx_cleaning_logs_date ON cleaning_checklist_logs(shift_date);
CREATE INDEX idx_cleaning_logs_status ON cleaning_checklist_logs(status);

-- =====================================================
-- TABLE: shift_handover
-- Bàn giao ca
-- =====================================================
CREATE TABLE IF NOT EXISTS shift_handover (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID,
  handover_date DATE NOT NULL,
  from_shift VARCHAR(50) NOT NULL CHECK (from_shift IN ('MORNING', 'EVENING')),
  to_shift VARCHAR(50) NOT NULL CHECK (to_shift IN ('MORNING', 'EVENING')),
  from_user_id UUID,
  to_user_id UUID,
  handover_photos JSONB DEFAULT '[]', -- Photos of current state
  handover_notes TEXT,
  issues_reported JSONB DEFAULT '[]', -- Array of issues: [{ area: 'counter', issue: 'Not clean', severity: 'medium' }]
  status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'DISPUTED')),
  rejection_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  accepted_at TIMESTAMP,
  accepted_by UUID
);

-- Indexes
CREATE INDEX idx_handover_store ON shift_handover(store_id);
CREATE INDEX idx_handover_date ON shift_handover(handover_date);
CREATE INDEX idx_handover_status ON shift_handover(status);

-- =====================================================
-- SEED DATA: Default Cleaning Checklist Templates
-- Tạo mẫu checklist mặc định từ giấy tờ CLB
-- =====================================================

-- Morning Shift Template
INSERT INTO cleaning_checklist_templates (name, shift_type, description, is_active)
VALUES ('Checklist Vệ Sinh Ca Sáng', 'MORNING', 'Checklist vệ sinh hàng ngày ca sáng (08:00 - 19:00)', true)
ON CONFLICT DO NOTHING;

-- Get the template ID for morning shift
DO $$
DECLARE
  morning_template_id UUID;
BEGIN
  SELECT id INTO morning_template_id 
  FROM cleaning_checklist_templates 
  WHERE shift_type = 'MORNING' 
  LIMIT 1;

  -- Morning Shift Items
  INSERT INTO cleaning_checklist_items (template_id, title, description, time_start, time_end, requires_photo, photo_locations, order_index) VALUES
  (morning_template_id, 'Chụp hình hiện trạng ca tối', 'Chụp hình: quầy, khu rửa ly - tủ lạnh, khu sofa, toàn quán', '08:00', '08:30', true, '["counter", "sink_area", "fridge", "sofa", "full_view"]', 1),
  (morning_template_id, 'Xả phòng', 'Mở cửa, bật quạt', '08:00', '08:30', false, '[]', 2),
  (morning_template_id, 'Hút bụi toàn quán', 'Hút bụi sàn trên, sàn dưới, trong quầy', '08:30', '09:00', true, '["floor_upper", "floor_lower", "counter"]', 3),
  (morning_template_id, 'Vệ sinh bàn bi-a', 'Vệ sinh bàn bida, lau bàn, ghế, đánh bi', '09:00', '09:30', true, '["tables", "chairs"]', 4),
  (morning_template_id, 'Vệ sinh máy hút bụi', 'Vệ sinh 2 máy hút bụi sau khi làm xong', '09:30', '10:00', true, '["vacuum_cleaners"]', 5),
  (morning_template_id, 'Dọn quầy', 'Rửa ly, sắp đặt tủ lạnh (nếu ca tối chưa dọn)', '09:30', '10:00', true, '["counter", "sink_area", "fridge"]', 6),
  (morning_template_id, 'Vệ sinh chuyên sâu', 'Lau cửa sổ, cửa kính, lan can', '14:00', '18:00', true, '["windows", "glass_doors", "railings"]', 7),
  (morning_template_id, 'Chuẩn bị bàn giao ca', 'Dọn dẹp khu vực quầy, khu rửa ly, tủ lạnh', '18:00', '19:00', true, '["counter", "sink_area", "fridge"]', 8)
  ON CONFLICT DO NOTHING;
END $$;

-- Evening Shift Template
INSERT INTO cleaning_checklist_templates (name, shift_type, description, is_active)
VALUES ('Checklist Vệ Sinh Ca Tối', 'EVENING', 'Checklist vệ sinh hàng ngày ca tối (19:00 - 23:00)', true)
ON CONFLICT DO NOTHING;

-- Get the template ID for evening shift
DO $$
DECLARE
  evening_template_id UUID;
BEGIN
  SELECT id INTO evening_template_id 
  FROM cleaning_checklist_templates 
  WHERE shift_type = 'EVENING' 
  LIMIT 1;

  -- Evening Shift Items
  INSERT INTO cleaning_checklist_items (template_id, title, description, time_start, time_end, requires_photo, photo_locations, order_index) VALUES
  (evening_template_id, 'Chụp hình hiện trạng ca sáng', 'Chụp hình hiện trạng ca sáng bàn giao', '19:00', '19:30', true, '["counter", "sink_area", "fridge", "full_view"]', 1),
  (evening_template_id, 'Quét dọn trước quán', 'Quét sạch khu vực trước quán', '19:00', '19:30', true, '["entrance"]', 2),
  (evening_template_id, 'Lau dọn nhà vệ sinh', 'Vệ sinh nhà vệ sinh', '19:00', '19:30', true, '["bathroom"]', 3),
  (evening_template_id, 'Bàn giao ca sáng', 'Dọn dẹp khu vực quầy, khu rửa ly, tủ lạnh', '23:00', '23:15', true, '["counter", "sink_area", "fridge"]', 4)
  ON CONFLICT DO NOTHING;
END $$;

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE cleaning_checklist_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaning_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaning_checklist_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_handover ENABLE ROW LEVEL SECURITY;

-- Policies for cleaning_checklist_templates
CREATE POLICY "Users can view templates of their store"
  ON cleaning_checklist_templates FOR SELECT
  USING (true);

CREATE POLICY "Managers can manage templates"
  ON cleaning_checklist_templates FOR ALL
  USING (true);

-- Policies for cleaning_checklist_items
CREATE POLICY "Users can view items of their store templates"
  ON cleaning_checklist_items FOR SELECT
  USING (true);

CREATE POLICY "Managers can manage items"
  ON cleaning_checklist_items FOR ALL
  USING (true);

-- Policies for cleaning_checklist_logs
CREATE POLICY "Users can view logs of their store"
  ON cleaning_checklist_logs FOR SELECT
  USING (true);

CREATE POLICY "Staff can create and update their own logs"
  ON cleaning_checklist_logs FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Staff can update their own logs"
  ON cleaning_checklist_logs FOR UPDATE
  USING (true);

-- Policies for shift_handover
CREATE POLICY "Users can view handovers of their store"
  ON shift_handover FOR SELECT
  USING (true);

CREATE POLICY "Staff can create handovers"
  ON shift_handover FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Staff can update handovers they're involved in"
  ON shift_handover FOR UPDATE
  USING (true);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for cleaning_checklist_templates
CREATE TRIGGER update_cleaning_templates_updated_at
  BEFORE UPDATE ON cleaning_checklist_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to check if task is overdue
CREATE OR REPLACE FUNCTION check_task_overdue()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'COMPLETED' AND NEW.completed_at IS NOT NULL THEN
    -- Get task end time
    DECLARE
      task_end_time TIMESTAMP;
      deadline TIMESTAMP;
    BEGIN
      SELECT (NEW.shift_date::TEXT || ' ' || time_end)::TIMESTAMP INTO task_end_time
      FROM cleaning_checklist_items
      WHERE id = NEW.item_id;
      
      deadline := task_end_time + INTERVAL '15 minutes';
      
      NEW.is_on_time := NEW.completed_at <= deadline;
    END;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check if task completed on time
CREATE TRIGGER check_cleaning_task_ontime
  BEFORE INSERT OR UPDATE ON cleaning_checklist_logs
  FOR EACH ROW
  WHEN (NEW.status = 'COMPLETED')
  EXECUTE FUNCTION check_task_overdue();

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE cleaning_checklist_templates IS 'Mẫu checklist vệ sinh theo ca làm việc';
COMMENT ON TABLE cleaning_checklist_items IS 'Danh sách các công việc vệ sinh cụ thể';
COMMENT ON TABLE cleaning_checklist_logs IS 'Lịch sử hoàn thành công việc vệ sinh';
COMMENT ON TABLE shift_handover IS 'Bàn giao ca làm việc giữa các nhân viên';

-- =====================================================
-- COMPLETE
-- =====================================================

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '✅ Cleaning Checklist Migration Complete!';
  RAISE NOTICE '📋 Created 4 tables: templates, items, logs, shift_handover';
  RAISE NOTICE '🔒 RLS policies applied';
  RAISE NOTICE '📝 Default templates seeded';
END $$;
