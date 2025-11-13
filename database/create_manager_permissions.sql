-- =====================================================
-- MANAGER PERMISSIONS SYSTEM
-- =====================================================
-- Allows CEO to grant/revoke specific tab access for each Manager
-- Each Manager can have different permissions for company tabs

-- Create manager_permissions table
CREATE TABLE IF NOT EXISTS public.manager_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    manager_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    
    -- Tab permissions (boolean flags)
    can_view_overview BOOLEAN DEFAULT true,          -- Tổng quan
    can_view_employees BOOLEAN DEFAULT true,         -- Nhân viên
    can_view_tasks BOOLEAN DEFAULT true,             -- Công việc
    can_view_documents BOOLEAN DEFAULT false,        -- Tài liệu
    can_view_ai_assistant BOOLEAN DEFAULT false,     -- AI Assistant
    can_view_attendance BOOLEAN DEFAULT true,        -- Chấm công
    can_view_accounting BOOLEAN DEFAULT false,       -- Kế toán
    can_view_employee_docs BOOLEAN DEFAULT false,    -- Hồ sơ NV
    can_view_business_law BOOLEAN DEFAULT false,     -- Luật DN
    can_view_settings BOOLEAN DEFAULT false,         -- Cài đặt
    
    -- Action permissions
    can_create_employee BOOLEAN DEFAULT false,       -- Tạo nhân viên
    can_edit_employee BOOLEAN DEFAULT false,         -- Sửa nhân viên
    can_delete_employee BOOLEAN DEFAULT false,       -- Xóa nhân viên
    can_create_task BOOLEAN DEFAULT true,            -- Tạo công việc
    can_edit_task BOOLEAN DEFAULT true,              -- Sửa công việc
    can_delete_task BOOLEAN DEFAULT false,           -- Xóa công việc
    can_approve_attendance BOOLEAN DEFAULT true,     -- Duyệt chấm công
    can_edit_company_info BOOLEAN DEFAULT false,     -- Sửa thông tin công ty
    
    -- Metadata
    granted_by UUID REFERENCES public.users(id),     -- CEO who granted permissions
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    notes TEXT,                                       -- CEO's notes about permissions
    
    UNIQUE(manager_id, company_id)                   -- One permission set per manager per company
);

-- Create indexes
CREATE INDEX idx_manager_permissions_manager ON public.manager_permissions(manager_id);
CREATE INDEX idx_manager_permissions_company ON public.manager_permissions(company_id);

-- Enable RLS
ALTER TABLE public.manager_permissions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- CEO can view all manager permissions in their companies
CREATE POLICY "CEO can view manager permissions" ON public.manager_permissions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() 
            AND u.role = 'CEO' 
            AND u.company_id = manager_permissions.company_id
        )
    );

-- CEO can manage manager permissions
CREATE POLICY "CEO can manage manager permissions" ON public.manager_permissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() 
            AND u.role = 'CEO' 
            AND u.company_id = manager_permissions.company_id
        )
    );

-- Manager can view their own permissions
CREATE POLICY "Manager can view own permissions" ON public.manager_permissions
    FOR SELECT USING (manager_id = auth.uid());

-- Add comments
COMMENT ON TABLE public.manager_permissions IS 'Stores granular permissions for each Manager, allowing CEO to control tab and action access';
COMMENT ON COLUMN public.manager_permissions.can_view_overview IS 'Permission to view Overview tab';
COMMENT ON COLUMN public.manager_permissions.can_view_employees IS 'Permission to view Employees tab';
COMMENT ON COLUMN public.manager_permissions.can_view_tasks IS 'Permission to view Tasks tab';
COMMENT ON COLUMN public.manager_permissions.can_view_documents IS 'Permission to view Documents tab';
COMMENT ON COLUMN public.manager_permissions.can_view_ai_assistant IS 'Permission to view AI Assistant tab';
COMMENT ON COLUMN public.manager_permissions.can_view_attendance IS 'Permission to view Attendance tab';
COMMENT ON COLUMN public.manager_permissions.can_view_accounting IS 'Permission to view Accounting tab';
COMMENT ON COLUMN public.manager_permissions.can_view_employee_docs IS 'Permission to view Employee Documents tab';
COMMENT ON COLUMN public.manager_permissions.can_view_business_law IS 'Permission to view Business Law tab';
COMMENT ON COLUMN public.manager_permissions.can_view_settings IS 'Permission to view Settings tab';

-- Create function to automatically create default permissions for new managers
CREATE OR REPLACE FUNCTION create_default_manager_permissions()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create permissions if the new employee is a Manager
    IF NEW.role = 'MANAGER' AND NEW.company_id IS NOT NULL THEN
        INSERT INTO public.manager_permissions (
            manager_id,
            company_id,
            can_view_overview,
            can_view_employees,
            can_view_tasks,
            can_view_attendance,
            can_create_task,
            can_edit_task,
            can_approve_attendance
        ) VALUES (
            NEW.id,
            NEW.company_id,
            true,   -- Default: can view overview
            true,   -- Default: can view employees
            true,   -- Default: can view tasks
            true,   -- Default: can view attendance
            true,   -- Default: can create tasks
            true,   -- Default: can edit tasks
            true    -- Default: can approve attendance
        )
        ON CONFLICT (manager_id, company_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_create_manager_permissions ON public.employees;
CREATE TRIGGER trigger_create_manager_permissions
    AFTER INSERT ON public.employees
    FOR EACH ROW
    EXECUTE FUNCTION create_default_manager_permissions();

-- Update function for updated_at
CREATE OR REPLACE FUNCTION update_manager_permissions_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_manager_permissions_timestamp ON public.manager_permissions;
CREATE TRIGGER trigger_update_manager_permissions_timestamp
    BEFORE UPDATE ON public.manager_permissions
    FOR EACH ROW
    EXECUTE FUNCTION update_manager_permissions_timestamp();

-- Grant permissions
GRANT SELECT ON public.manager_permissions TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.manager_permissions TO authenticated;
