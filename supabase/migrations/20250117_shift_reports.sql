-- =====================================================
-- SHIFT REPORTS TABLE
-- For STAFF and SHIFT_LEADER to create end-of-shift reports
-- =====================================================

-- Create shift_reports table
CREATE TABLE IF NOT EXISTS shift_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Shift Info
  shift_id UUID REFERENCES shifts(id) ON DELETE SET NULL,
  shift_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  
  -- Revenue & Operations
  total_revenue DECIMAL(10, 2) NOT NULL DEFAULT 0,
  total_customers INTEGER NOT NULL DEFAULT 0,
  total_tables_served INTEGER NOT NULL DEFAULT 0,
  
  -- Equipment Status (JSONB array)
  equipment_status JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Example: [{"item": "Bàn 1", "condition": "good", "notes": "OK"}]
  
  -- Inventory Check (JSONB array)
  inventory_check JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Example: [{"item": "Bi xanh", "current_stock": 50, "unit": "viên", "needs_restock": false}]
  
  -- Low Stock Items
  low_stock_items TEXT[] DEFAULT ARRAY[]::TEXT[],
  
  -- Incidents (JSONB array)
  incidents JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"type": "equipment", "severity": "medium", "description": "Cơ hỏng bàn 3", "action_taken": "Đã báo kỹ thuật"}]
  
  -- Staff on Duty (JSONB array)
  staff_on_duty JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"id": "uuid", "name": "Nguyễn Văn A", "role": "STAFF", "performance": "good"}]
  
  -- Notes
  additional_notes TEXT,
  handover_notes TEXT,
  
  -- Status & Review
  status VARCHAR(20) NOT NULL DEFAULT 'submitted' CHECK (status IN ('draft', 'submitted', 'reviewed', 'approved')),
  reviewer_notes TEXT,
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  store_id UUID REFERENCES stores(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_shift_reports_shift_date ON shift_reports(shift_date DESC);
CREATE INDEX IF NOT EXISTS idx_shift_reports_created_by ON shift_reports(created_by);
CREATE INDEX IF NOT EXISTS idx_shift_reports_store_id ON shift_reports(store_id);
CREATE INDEX IF NOT EXISTS idx_shift_reports_status ON shift_reports(status);
CREATE INDEX IF NOT EXISTS idx_shift_reports_shift_id ON shift_reports(shift_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_shift_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_shift_reports_updated_at
  BEFORE UPDATE ON shift_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_shift_reports_updated_at();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE shift_reports ENABLE ROW LEVEL SECURITY;

-- STAFF can only view and create their own reports
CREATE POLICY "staff_own_reports" ON shift_reports
  FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('STAFF') 
    AND created_by = (auth.jwt() ->> 'sub')::uuid
  )
  WITH CHECK (
    auth.jwt() ->> 'role' IN ('STAFF')
    AND created_by = (auth.jwt() ->> 'sub')::uuid
  );

-- SHIFT_LEADER can view all reports in their store and update status
CREATE POLICY "shift_leader_store_reports" ON shift_reports
  FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    AND (
      store_id = (auth.jwt() ->> 'store_id')::uuid
      OR store_id IS NULL
    )
  );

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Insert sample shift report (uncomment to use)
/*
INSERT INTO shift_reports (
  shift_date,
  start_time,
  end_time,
  total_revenue,
  total_customers,
  total_tables_served,
  equipment_status,
  inventory_check,
  low_stock_items,
  additional_notes,
  status,
  created_by,
  store_id
) VALUES (
  CURRENT_DATE,
  '08:00:00',
  '16:00:00',
  5500000,
  45,
  12,
  '[
    {"item": "Bàn 1", "condition": "good", "notes": "Hoạt động tốt"},
    {"item": "Bàn 2", "condition": "minor_issue", "notes": "Cơ hơi lỏng"},
    {"item": "Máy tính tiền", "condition": "good", "notes": "OK"}
  ]'::jsonb,
  '[
    {"item": "Bi xanh", "current_stock": 50, "unit": "viên", "needs_restock": false},
    {"item": "Bi đỏ", "current_stock": 15, "unit": "viên", "needs_restock": true},
    {"item": "Phấn", "current_stock": 5, "unit": "hộp", "needs_restock": true}
  ]'::jsonb,
  ARRAY['Bi đỏ', 'Phấn'],
  'Ca làm việc suôn sẻ, khách đông vào buổi chiều',
  'submitted',
  (SELECT id FROM users WHERE role = 'STAFF' LIMIT 1),
  (SELECT id FROM stores LIMIT 1)
);
*/

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE shift_reports IS 'Shift reports created by staff at end of shift';
COMMENT ON COLUMN shift_reports.equipment_status IS 'JSONB array of equipment status checks';
COMMENT ON COLUMN shift_reports.inventory_check IS 'JSONB array of inventory counts';
COMMENT ON COLUMN shift_reports.incidents IS 'JSONB array of incidents during shift';
COMMENT ON COLUMN shift_reports.staff_on_duty IS 'JSONB array of staff working during shift';
