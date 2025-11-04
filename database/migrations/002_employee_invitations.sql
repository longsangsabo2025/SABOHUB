-- Employee Invitations Table Migration
-- This creates the table for managing employee invitations

CREATE TABLE IF NOT EXISTS employee_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invitation_code VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255),
    role_type VARCHAR(50) NOT NULL DEFAULT 'staff',
    max_uses INTEGER DEFAULT 1,
    used_count INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_employee_invitations_code ON employee_invitations(invitation_code);
CREATE INDEX IF NOT EXISTS idx_employee_invitations_company ON employee_invitations(company_id);
CREATE INDEX IF NOT EXISTS idx_employee_invitations_creator ON employee_invitations(created_by);
CREATE INDEX IF NOT EXISTS idx_employee_invitations_expires ON employee_invitations(expires_at);

-- Add constraints
ALTER TABLE employee_invitations 
ADD CONSTRAINT chk_used_count_positive CHECK (used_count >= 0);

ALTER TABLE employee_invitations 
ADD CONSTRAINT chk_max_uses_positive CHECK (max_uses > 0);

ALTER TABLE employee_invitations 
ADD CONSTRAINT chk_used_not_exceed_max CHECK (used_count <= max_uses);

ALTER TABLE employee_invitations 
ADD CONSTRAINT chk_valid_role_type CHECK (role_type IN ('staff', 'shift_leader', 'manager'));

-- Enable RLS
ALTER TABLE employee_invitations ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- CEOs can manage all invitations for their companies
CREATE POLICY "CEOs can manage company invitations" ON employee_invitations
    FOR ALL USING (
        company_id IN (
            SELECT company_id FROM users 
            WHERE id = auth.uid() 
            AND role = 'ceo'
        )
    );

-- Managers can view and create invitations for their companies (but not delete)
CREATE POLICY "Managers can view company invitations" ON employee_invitations
    FOR SELECT USING (
        company_id IN (
            SELECT company_id FROM users 
            WHERE id = auth.uid() 
            AND role = 'manager'
        )
    );

CREATE POLICY "Managers can create invitations" ON employee_invitations
    FOR INSERT WITH CHECK (
        company_id IN (
            SELECT company_id FROM users 
            WHERE id = auth.uid() 
            AND role = 'manager'
        )
        AND created_by = auth.uid()
    );

-- Public can read invitation details for registration (only when valid)
CREATE POLICY "Public can read valid invitations" ON employee_invitations
    FOR SELECT USING (
        is_active = true 
        AND expires_at > NOW() 
        AND used_count < max_uses
    );

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_employee_invitations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_employee_invitations_updated_at
    BEFORE UPDATE ON employee_invitations
    FOR EACH ROW
    EXECUTE FUNCTION update_employee_invitations_updated_at();

-- Comments for documentation
COMMENT ON TABLE employee_invitations IS 'Stores invitation codes for employees to join companies';
COMMENT ON COLUMN employee_invitations.invitation_code IS 'Unique code used for invitation link';
COMMENT ON COLUMN employee_invitations.role_type IS 'Role that will be assigned to the employee upon registration';
COMMENT ON COLUMN employee_invitations.max_uses IS 'Maximum number of times this invitation can be used';
COMMENT ON COLUMN employee_invitations.used_count IS 'Number of times this invitation has been used';
COMMENT ON COLUMN employee_invitations.expires_at IS 'When this invitation expires';