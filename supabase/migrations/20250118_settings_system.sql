-- =====================================================
-- SETTINGS-DRIVEN ARCHITECTURE - SABO Hub
-- Migration: Settings System
-- Date: 2025-01-18
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. ORGANIZATION SETTINGS
-- =====================================================

CREATE TABLE IF NOT EXISTS organization_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  
  -- Business Information
  business_name TEXT NOT NULL,
  business_type TEXT DEFAULT 'billiards', -- 'billiards', 'cafe', 'restaurant', 'mixed'
  timezone TEXT DEFAULT 'Asia/Ho_Chi_Minh',
  currency TEXT DEFAULT 'VND',
  locale TEXT DEFAULT 'vi-VN',
  
  -- Operating Hours (JSONB for flexibility)
  operating_hours JSONB DEFAULT '{
    "monday": {"open": "08:00", "close": "23:00", "closed": false},
    "tuesday": {"open": "08:00", "close": "23:00", "closed": false},
    "wednesday": {"open": "08:00", "close": "23:00", "closed": false},
    "thursday": {"open": "08:00", "close": "23:00", "closed": false},
    "friday": {"open": "08:00", "close": "23:00", "closed": false},
    "saturday": {"open": "08:00", "close": "00:00", "closed": false},
    "sunday": {"open": "08:00", "close": "00:00", "closed": false}
  }'::jsonb,
  
  -- Feature Flags (Enable/Disable features)
  features JSONB DEFAULT '{
    "shift_reports": true,
    "inventory": true,
    "tasks": true,
    "customer_loyalty": false,
    "online_booking": false,
    "analytics": true,
    "notifications": true,
    "multi_language": false
  }'::jsonb,
  
  -- Branding & UI Customization
  branding JSONB DEFAULT '{
    "primary_color": "#007AFF",
    "secondary_color": "#5856D6",
    "logo_url": null,
    "favicon_url": null,
    "theme": "light",
    "custom_css": null
  }'::jsonb,
  
  -- Contact Information
  contact_info JSONB DEFAULT '{
    "phone": null,
    "email": null,
    "address": null,
    "website": null,
    "social_media": {}
  }'::jsonb,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID,
  updated_by UUID,
  
  -- Ensure one setting per organization
  CONSTRAINT unique_org_settings UNIQUE (organization_id)
);

-- =====================================================
-- 2. STAFF CONFIGURATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS staff_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  
  -- Custom Role Definitions (Dynamic!)
  custom_roles JSONB DEFAULT '[
    {
      "id": "CEO",
      "name": "Giám đốc",
      "name_en": "CEO",
      "permissions": ["*"],
      "level": 1,
      "color": "#FF3B30"
    },
    {
      "id": "MANAGER",
      "name": "Quản lý",
      "name_en": "Manager",
      "permissions": ["manage_staff", "view_reports", "manage_tasks"],
      "level": 2,
      "color": "#FF9500"
    },
    {
      "id": "SHIFT_LEADER",
      "name": "Trưởng ca",
      "name_en": "Shift Leader",
      "permissions": ["manage_shift", "view_reports", "assign_tasks"],
      "level": 3,
      "color": "#FFCC00"
    },
    {
      "id": "STAFF",
      "name": "Nhân viên",
      "name_en": "Staff",
      "permissions": ["submit_reports", "view_tasks", "clock_in"],
      "level": 4,
      "color": "#34C759"
    }
  ]'::jsonb,
  
  -- Shift Types Configuration
  shift_types JSONB DEFAULT '[
    {
      "id": "morning",
      "name": "Ca sáng",
      "name_en": "Morning Shift",
      "start_time": "08:00",
      "end_time": "16:00",
      "color": "#FFD60A"
    },
    {
      "id": "afternoon",
      "name": "Ca chiều",
      "name_en": "Afternoon Shift",
      "start_time": "16:00",
      "end_time": "23:00",
      "color": "#FF9500"
    },
    {
      "id": "night",
      "name": "Ca đêm",
      "name_en": "Night Shift",
      "start_time": "23:00",
      "end_time": "08:00",
      "color": "#5856D6"
    }
  ]'::jsonb,
  
  -- Salary & Compensation Rules
  salary_rules JSONB DEFAULT '{
    "base_hourly_rate": 30000,
    "overtime_multiplier": 1.5,
    "weekend_multiplier": 1.3,
    "holiday_multiplier": 2.0,
    "bonus_rules": {
      "performance_bonus": true,
      "attendance_bonus": true,
      "sales_commission": false
    }
  }'::jsonb,
  
  -- Attendance Rules
  attendance_rules JSONB DEFAULT '{
    "late_threshold_minutes": 15,
    "early_leave_penalty": 50000,
    "required_check_in": true,
    "check_in_radius_meters": 100,
    "allow_remote_check_in": false,
    "break_time_minutes": 30
  }'::jsonb,
  
  -- Leave/PTO Policies
  leave_policies JSONB DEFAULT '{
    "annual_leave_days": 12,
    "sick_leave_days": 7,
    "requires_approval": true,
    "advance_notice_days": 3
  }'::jsonb,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID,
  updated_by UUID,
  
  CONSTRAINT unique_staff_config UNIQUE (organization_id)
);

-- =====================================================
-- 3. TASK CONFIGURATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS task_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  
  -- Task Categories (CEO defines)
  task_categories JSONB DEFAULT '[
    {
      "id": "cleaning",
      "name": "Vệ sinh",
      "name_en": "Cleaning",
      "color": "#FF6B6B",
      "icon": "broom"
    },
    {
      "id": "customer_service",
      "name": "Phục vụ khách",
      "name_en": "Customer Service",
      "color": "#4ECDC4",
      "icon": "users"
    },
    {
      "id": "inventory",
      "name": "Kiểm kho",
      "name_en": "Inventory Check",
      "color": "#FFE66D",
      "icon": "package"
    },
    {
      "id": "maintenance",
      "name": "Bảo trì",
      "name_en": "Maintenance",
      "color": "#95E1D3",
      "icon": "tool"
    }
  ]'::jsonb,
  
  -- Priority Levels
  priority_levels JSONB DEFAULT '[
    {
      "id": "urgent",
      "name": "Khẩn cấp",
      "name_en": "Urgent",
      "level": 1,
      "sla_hours": 1,
      "color": "#FF3B30"
    },
    {
      "id": "high",
      "name": "Cao",
      "name_en": "High",
      "level": 2,
      "sla_hours": 4,
      "color": "#FF9500"
    },
    {
      "id": "normal",
      "name": "Bình thường",
      "name_en": "Normal",
      "level": 3,
      "sla_hours": 24,
      "color": "#007AFF"
    },
    {
      "id": "low",
      "name": "Thấp",
      "name_en": "Low",
      "level": 4,
      "sla_hours": 72,
      "color": "#8E8E93"
    }
  ]'::jsonb,
  
  -- Task Templates (Reusable tasks)
  task_templates JSONB DEFAULT '[
    {
      "id": "daily_cleaning",
      "name": "Vệ sinh hàng ngày",
      "name_en": "Daily Cleaning",
      "category": "cleaning",
      "priority": "normal",
      "checklist": [
        "Lau bàn bi-a",
        "Hút bụi sàn nhà",
        "Rửa WC",
        "Đổ rác"
      ],
      "estimated_minutes": 30,
      "requires_photo": true
    },
    {
      "id": "inventory_check",
      "name": "Kiểm kho định kỳ",
      "name_en": "Periodic Inventory Check",
      "category": "inventory",
      "priority": "normal",
      "checklist": [
        "Đếm số lượng đồ uống",
        "Kiểm tra hạn sử dụng",
        "Ghi nhận hàng thiếu"
      ],
      "estimated_minutes": 45,
      "requires_photo": false
    }
  ]'::jsonb,
  
  -- Approval Workflow
  approval_workflow JSONB DEFAULT '{
    "requires_approval": true,
    "approvers": ["MANAGER", "CEO"],
    "auto_approve_threshold": null,
    "escalation_hours": 24
  }'::jsonb,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID,
  updated_by UUID,
  
  CONSTRAINT unique_task_config UNIQUE (organization_id)
);

-- =====================================================
-- 4. STORE CONFIGURATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS store_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  
  -- Table/Asset Types (Billiards specific)
  table_types JSONB DEFAULT '[
    {
      "id": "pool_8",
      "name": "Bi-a 8 lỗ",
      "name_en": "8-Ball Pool",
      "hourly_rate": 50000,
      "description": "Bàn bi-a 8 lỗ tiêu chuẩn",
      "capacity": 2
    },
    {
      "id": "pool_9",
      "name": "Bi-a 9 lỗ",
      "name_en": "9-Ball Pool",
      "hourly_rate": 60000,
      "description": "Bàn bi-a 9 lỗ chuyên nghiệp",
      "capacity": 2
    },
    {
      "id": "snooker",
      "name": "Snooker",
      "name_en": "Snooker",
      "hourly_rate": 80000,
      "description": "Bàn snooker cao cấp",
      "capacity": 2
    },
    {
      "id": "carom",
      "name": "Bi-a Carom",
      "name_en": "Carom Billiards",
      "hourly_rate": 70000,
      "description": "Bàn bi-a không lỗ",
      "capacity": 2
    }
  ]'::jsonb,
  
  -- Pricing Rules (Dynamic pricing)
  pricing_rules JSONB DEFAULT '{
    "peak_hours": {
      "enabled": true,
      "start_time": "18:00",
      "end_time": "22:00",
      "multiplier": 1.5
    },
    "happy_hours": {
      "enabled": true,
      "start_time": "14:00",
      "end_time": "16:00",
      "discount": 0.2
    },
    "member_discount": 0.1,
    "group_discount": {
      "min_tables": 3,
      "discount": 0.15
    },
    "minimum_charge": 30000
  }'::jsonb,
  
  -- Inventory Categories
  inventory_categories JSONB DEFAULT '[
    {
      "id": "beverages",
      "name": "Đồ uống",
      "name_en": "Beverages",
      "low_stock_threshold": 20,
      "unit": "chai/lon"
    },
    {
      "id": "snacks",
      "name": "Đồ ăn nhẹ",
      "name_en": "Snacks",
      "low_stock_threshold": 10,
      "unit": "gói"
    },
    {
      "id": "equipment",
      "name": "Dụng cụ",
      "name_en": "Equipment",
      "low_stock_threshold": 5,
      "unit": "cái"
    }
  ]'::jsonb,
  
  -- Payment Methods
  payment_methods JSONB DEFAULT '[
    {
      "id": "cash",
      "name": "Tiền mặt",
      "name_en": "Cash",
      "enabled": true,
      "icon": "dollar-sign"
    },
    {
      "id": "bank_transfer",
      "name": "Chuyển khoản",
      "name_en": "Bank Transfer",
      "enabled": true,
      "icon": "credit-card"
    },
    {
      "id": "e_wallet",
      "name": "Ví điện tử",
      "name_en": "E-Wallet",
      "enabled": true,
      "icon": "smartphone"
    }
  ]'::jsonb,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID,
  updated_by UUID,
  
  CONSTRAINT unique_store_config UNIQUE (organization_id)
);

-- =====================================================
-- 5. NOTIFICATION CONFIGURATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS notification_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  
  -- Notification Rules
  rules JSONB DEFAULT '[
    {
      "id": "shift_report_submitted",
      "event": "shift_report_submitted",
      "name": "Báo cáo ca mới",
      "notify_roles": ["MANAGER", "CEO"],
      "channels": ["push", "in_app"],
      "template": "{{staff_name}} đã nộp báo cáo ca {{shift_date}}",
      "enabled": true
    },
    {
      "id": "task_assigned",
      "event": "task_assigned",
      "name": "Công việc được giao",
      "notify_roles": ["assignee"],
      "channels": ["push", "in_app"],
      "template": "Bạn có công việc mới: {{task_title}}",
      "enabled": true
    },
    {
      "id": "task_overdue",
      "event": "task_overdue",
      "name": "Công việc quá hạn",
      "notify_roles": ["MANAGER", "assignee"],
      "channels": ["push", "in_app"],
      "template": "Công việc {{task_title}} đã quá hạn",
      "delay_minutes": 30,
      "enabled": true
    },
    {
      "id": "low_stock",
      "event": "low_stock",
      "name": "Hàng sắp hết",
      "notify_roles": ["MANAGER", "CEO"],
      "channels": ["push", "in_app"],
      "template": "{{item_name}} sắp hết (còn {{quantity}})",
      "enabled": true
    }
  ]'::jsonb,
  
  -- Notification Preferences
  preferences JSONB DEFAULT '{
    "quiet_hours": {
      "enabled": false,
      "start_time": "22:00",
      "end_time": "08:00"
    },
    "batch_notifications": false,
    "sound_enabled": true,
    "vibration_enabled": true
  }'::jsonb,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID,
  updated_by UUID,
  
  CONSTRAINT unique_notification_config UNIQUE (organization_id)
);

-- =====================================================
-- 6. FORM CONFIGURATIONS (Dynamic Forms!)
-- =====================================================

CREATE TABLE IF NOT EXISTS form_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  form_type TEXT NOT NULL, -- 'shift_report', 'task', 'inventory_check', etc.
  form_name TEXT NOT NULL,
  form_name_en TEXT,
  
  -- Dynamic Fields (CEO can add/remove/reorder)
  fields JSONB DEFAULT '[]'::jsonb,
  
  -- Example fields structure:
  -- [
  --   {
  --     "id": "revenue",
  --     "type": "number",
  --     "label": "Doanh thu",
  --     "label_en": "Revenue",
  --     "required": true,
  --     "placeholder": "Nhập doanh thu",
  --     "validation": {"min": 0, "max": 999999999},
  --     "default_value": null,
  --     "help_text": "Tổng doanh thu trong ca"
  --   },
  --   {
  --     "id": "customers",
  --     "type": "number",
  --     "label": "Số khách",
  --     "required": true,
  --     "validation": {"min": 0}
  --   },
  --   {
  --     "id": "notes",
  --     "type": "textarea",
  --     "label": "Ghi chú",
  --     "required": false,
  --     "rows": 4
  --   }
  -- ]
  
  -- Form Layout
  layout JSONB DEFAULT '{
    "sections": []
  }'::jsonb,
  
  -- Example layout structure:
  -- {
  --   "sections": [
  --     {
  --       "id": "basic_info",
  --       "title": "Thông tin cơ bản",
  --       "fields": ["revenue", "customers"]
  --     },
  --     {
  --       "id": "details",
  --       "title": "Chi tiết",
  --       "fields": ["notes"]
  --     }
  --   ]
  -- }
  
  -- Form Settings
  settings JSONB DEFAULT '{
    "allow_draft": true,
    "require_approval": false,
    "enable_attachments": true,
    "max_attachments": 5
  }'::jsonb,
  
  is_active BOOLEAN DEFAULT true,
  version INTEGER DEFAULT 1,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID,
  updated_by UUID,
  
  CONSTRAINT unique_form_type UNIQUE (organization_id, form_type)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_org_settings_org_id ON organization_settings(organization_id);
CREATE INDEX idx_staff_config_org_id ON staff_configurations(organization_id);
CREATE INDEX idx_task_config_org_id ON task_configurations(organization_id);
CREATE INDEX idx_store_config_org_id ON store_configurations(organization_id);
CREATE INDEX idx_notification_config_org_id ON notification_configurations(organization_id);
CREATE INDEX idx_form_config_org_id ON form_configurations(organization_id);
CREATE INDEX idx_form_config_type ON form_configurations(organization_id, form_type);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_org_settings_updated_at
    BEFORE UPDATE ON organization_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_staff_config_updated_at
    BEFORE UPDATE ON staff_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_task_config_updated_at
    BEFORE UPDATE ON task_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_store_config_updated_at
    BEFORE UPDATE ON store_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_notification_config_updated_at
    BEFORE UPDATE ON notification_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_form_config_updated_at
    BEFORE UPDATE ON form_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

ALTER TABLE organization_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_configurations ENABLE ROW LEVEL SECURITY;

-- CEO and MANAGER can view/edit all settings
CREATE POLICY ceo_manager_all_settings ON organization_settings
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = organization_settings.organization_id
      AND users.role IN ('CEO', 'MANAGER')
    )
  );

CREATE POLICY ceo_manager_staff_config ON staff_configurations
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = staff_configurations.organization_id
      AND users.role IN ('CEO', 'MANAGER')
    )
  );

CREATE POLICY ceo_manager_task_config ON task_configurations
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = task_configurations.organization_id
      AND users.role IN ('CEO', 'MANAGER')
    )
  );

CREATE POLICY ceo_manager_store_config ON store_configurations
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = store_configurations.organization_id
      AND users.role IN ('CEO', 'MANAGER')
    )
  );

CREATE POLICY ceo_manager_notification_config ON notification_configurations
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = notification_configurations.organization_id
      AND users.role IN ('CEO', 'MANAGER')
    )
  );

CREATE POLICY ceo_manager_form_config ON form_configurations
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = form_configurations.organization_id
      AND users.role IN ('CEO', 'MANAGER')
    )
  );

-- All authenticated users can READ settings (but only CEO/MANAGER can WRITE)
CREATE POLICY all_users_read_org_settings ON organization_settings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = organization_settings.organization_id
    )
  );

CREATE POLICY all_users_read_staff_config ON staff_configurations
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = staff_configurations.organization_id
    )
  );

CREATE POLICY all_users_read_task_config ON task_configurations
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = task_configurations.organization_id
    )
  );

CREATE POLICY all_users_read_store_config ON store_configurations
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = store_configurations.organization_id
    )
  );

CREATE POLICY all_users_read_form_config ON form_configurations
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.organization_id = form_configurations.organization_id
    )
  );

-- =====================================================
-- SEED DATA (Default settings for new organizations)
-- =====================================================

-- Insert default organization settings
-- (This will be done via app when creating new organization)

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE organization_settings IS 'Central configuration for organization business settings, features, and branding';
COMMENT ON TABLE staff_configurations IS 'Staff management settings including roles, shifts, salary rules, and attendance policies';
COMMENT ON TABLE task_configurations IS 'Task management settings including categories, priorities, templates, and workflows';
COMMENT ON TABLE store_configurations IS 'Store/branch settings including table types, pricing rules, and inventory categories';
COMMENT ON TABLE notification_configurations IS 'Notification rules and preferences for different events';
COMMENT ON TABLE form_configurations IS 'Dynamic form schemas that allow CEO to customize forms without code changes';

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- Next steps:
-- 1. Create tRPC routes for CRUD operations
-- 2. Build CEO Settings UI
-- 3. Create hooks for accessing settings
-- 4. Update existing features to use settings
-- =====================================================
