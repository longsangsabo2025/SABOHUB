-- =====================================================
-- COMMISSION SYSTEM MIGRATION
-- Hệ thống quản lý hoa hồng từ bill cho nhân viên
-- =====================================================

-- 1. Bảng Bills (Hóa đơn)
CREATE TABLE IF NOT EXISTS bills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    store_id UUID REFERENCES stores(id) ON DELETE SET NULL,
    bill_number TEXT NOT NULL,
    bill_date TIMESTAMPTZ NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL CHECK (total_amount >= 0),
    bill_image_url TEXT,
    ocr_data JSONB, -- Dữ liệu từ AI OCR: {items: [], confidence: 0.95, raw_text: "..."}
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
    uploaded_by UUID NOT NULL REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT unique_bill_number_per_company UNIQUE (company_id, bill_number)
);

-- 2. Bảng Commission Rules (Quy tắc hoa hồng do CEO thiết lập)
CREATE TABLE IF NOT EXISTS commission_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    rule_name TEXT NOT NULL,
    description TEXT,
    applies_to TEXT NOT NULL DEFAULT 'all' CHECK (applies_to IN ('all', 'role', 'individual')),
    role TEXT, -- Nếu applies_to = 'role': 'staff', 'shift_leader', etc.
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- Nếu applies_to = 'individual'
    commission_percentage DECIMAL(5,2) NOT NULL CHECK (commission_percentage >= 0 AND commission_percentage <= 100),
    min_bill_amount DECIMAL(15,2) DEFAULT 0 CHECK (min_bill_amount >= 0),
    max_bill_amount DECIMAL(15,2), -- Null = không giới hạn
    is_active BOOLEAN NOT NULL DEFAULT true,
    priority INT DEFAULT 0, -- Ưu tiên cao hơn (số lớn hơn) được áp dụng trước
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CHECK (max_bill_amount IS NULL OR max_bill_amount > min_bill_amount),
    CHECK (effective_to IS NULL OR effective_to > effective_from)
);

-- 3. Bảng Bill Commissions (Hoa hồng cho từng nhân viên từ bill)
CREATE TABLE IF NOT EXISTS bill_commissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bill_id UUID NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    commission_rule_id UUID REFERENCES commission_rules(id) ON DELETE SET NULL,
    commission_percentage DECIMAL(5,2) NOT NULL CHECK (commission_percentage >= 0 AND commission_percentage <= 100),
    base_amount DECIMAL(15,2) NOT NULL, -- Số tiền tính commission (thường = total_amount)
    commission_amount DECIMAL(15,2) NOT NULL CHECK (commission_amount >= 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    paid_by UUID REFERENCES users(id),
    paid_at TIMESTAMPTZ,
    payment_reference TEXT, -- Mã tham chiếu thanh toán
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT unique_bill_employee UNIQUE (bill_id, employee_id)
);

-- 4. Bảng Commission History (Lịch sử thay đổi quy tắc)
CREATE TABLE IF NOT EXISTS commission_rule_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES commission_rules(id) ON DELETE CASCADE,
    changed_by UUID NOT NULL REFERENCES users(id),
    change_type TEXT NOT NULL CHECK (change_type IN ('created', 'updated', 'deactivated', 'reactivated', 'deleted')),
    old_values JSONB,
    new_values JSONB,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES for Performance
-- =====================================================

-- Bills indexes
CREATE INDEX IF NOT EXISTS idx_bills_company_id ON bills(company_id);
CREATE INDEX IF NOT EXISTS idx_bills_store_id ON bills(store_id);
CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_bill_date ON bills(bill_date DESC);
CREATE INDEX IF NOT EXISTS idx_bills_uploaded_by ON bills(uploaded_by);

-- Commission Rules indexes
CREATE INDEX IF NOT EXISTS idx_commission_rules_company_id ON commission_rules(company_id);
CREATE INDEX IF NOT EXISTS idx_commission_rules_is_active ON commission_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_commission_rules_applies_to ON commission_rules(applies_to);
CREATE INDEX IF NOT EXISTS idx_commission_rules_user_id ON commission_rules(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_commission_rules_effective_dates ON commission_rules(effective_from, effective_to);

-- Bill Commissions indexes
CREATE INDEX IF NOT EXISTS idx_bill_commissions_bill_id ON bill_commissions(bill_id);
CREATE INDEX IF NOT EXISTS idx_bill_commissions_employee_id ON bill_commissions(employee_id);
CREATE INDEX IF NOT EXISTS idx_bill_commissions_status ON bill_commissions(status);
CREATE INDEX IF NOT EXISTS idx_bill_commissions_paid_at ON bill_commissions(paid_at) WHERE paid_at IS NOT NULL;

-- Commission History indexes
CREATE INDEX IF NOT EXISTS idx_commission_rule_history_rule_id ON commission_rule_history(rule_id);
CREATE INDEX IF NOT EXISTS idx_commission_rule_history_created_at ON commission_rule_history(created_at DESC);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_bills_updated_at
    BEFORE UPDATE ON bills
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_commission_rules_updated_at
    BEFORE UPDATE ON commission_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bill_commissions_updated_at
    BEFORE UPDATE ON bill_commissions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Log commission rule changes
CREATE OR REPLACE FUNCTION log_commission_rule_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO commission_rule_history (rule_id, changed_by, change_type, old_values, new_values)
        VALUES (
            NEW.id,
            NEW.updated_by,
            'updated',
            row_to_json(OLD)::jsonb,
            row_to_json(NEW)::jsonb
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO commission_rule_history (rule_id, changed_by, change_type, old_values)
        VALUES (
            OLD.id,
            OLD.updated_by,
            'deleted',
            row_to_json(OLD)::jsonb
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: Need to add updated_by column tracking for this trigger to work properly
-- For now, we'll disable auto-logging and handle it in application layer

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_rule_history ENABLE ROW LEVEL SECURITY;

-- Bills Policies
-- CEO and Managers can see all bills in their company
CREATE POLICY "bills_select_ceo_manager" ON bills
    FOR SELECT
    USING (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid() OR manager_id = auth.uid()
        )
    );

-- Employees can see bills that they have commission on
CREATE POLICY "bills_select_employee" ON bills
    FOR SELECT
    USING (
        id IN (
            SELECT bill_id FROM bill_commissions 
            WHERE employee_id = auth.uid()
        )
    );

-- Managers can insert bills
CREATE POLICY "bills_insert_manager" ON bills
    FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT id FROM companies 
            WHERE manager_id = auth.uid()
        )
        OR
        company_id IN (
            SELECT company_id FROM users 
            WHERE id = auth.uid() AND role IN ('shift_leader', 'manager')
        )
    );

-- CEO and Managers can update bills
CREATE POLICY "bills_update_ceo_manager" ON bills
    FOR UPDATE
    USING (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid() OR manager_id = auth.uid()
        )
    );

-- Commission Rules Policies
-- CEO and Managers can manage rules
CREATE POLICY "commission_rules_select" ON commission_rules
    FOR SELECT
    USING (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid() OR manager_id = auth.uid()
        )
        OR
        -- Employees can see rules that apply to them
        (applies_to = 'individual' AND user_id = auth.uid())
        OR
        (applies_to = 'role' AND role = (SELECT role FROM users WHERE id = auth.uid()))
    );

-- Only CEO can insert/update rules
CREATE POLICY "commission_rules_insert_ceo" ON commission_rules
    FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid()
        )
    );

CREATE POLICY "commission_rules_update_ceo" ON commission_rules
    FOR UPDATE
    USING (
        company_id IN (
            SELECT id FROM companies 
            WHERE ceo_id = auth.uid()
        )
    );

-- Bill Commissions Policies
-- Employees can see their own commissions
CREATE POLICY "bill_commissions_select_employee" ON bill_commissions
    FOR SELECT
    USING (
        employee_id = auth.uid()
        OR
        bill_id IN (
            SELECT id FROM bills 
            WHERE company_id IN (
                SELECT id FROM companies 
                WHERE ceo_id = auth.uid() OR manager_id = auth.uid()
            )
        )
    );

-- System/Managers can insert commissions (usually automatic)
CREATE POLICY "bill_commissions_insert_manager" ON bill_commissions
    FOR INSERT
    WITH CHECK (
        bill_id IN (
            SELECT id FROM bills 
            WHERE company_id IN (
                SELECT id FROM companies 
                WHERE manager_id = auth.uid() OR ceo_id = auth.uid()
            )
        )
    );

-- CEO and Managers can update commission status (approve/pay)
CREATE POLICY "bill_commissions_update_ceo_manager" ON bill_commissions
    FOR UPDATE
    USING (
        bill_id IN (
            SELECT id FROM bills 
            WHERE company_id IN (
                SELECT id FROM companies 
                WHERE ceo_id = auth.uid() OR manager_id = auth.uid()
            )
        )
    );

-- Commission Rule History Policies
CREATE POLICY "commission_rule_history_select" ON commission_rule_history
    FOR SELECT
    USING (
        rule_id IN (
            SELECT id FROM commission_rules 
            WHERE company_id IN (
                SELECT id FROM companies 
                WHERE ceo_id = auth.uid()
            )
        )
    );

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function: Tự động tính commission cho bill
CREATE OR REPLACE FUNCTION calculate_bill_commissions(p_bill_id UUID, p_employee_ids UUID[])
RETURNS TABLE (
    employee_id UUID,
    commission_amount DECIMAL,
    commission_percentage DECIMAL,
    rule_id UUID
) AS $$
DECLARE
    v_bill_record RECORD;
    v_employee_id UUID;
    v_rule RECORD;
    v_commission_pct DECIMAL;
    v_commission_amt DECIMAL;
BEGIN
    -- Get bill details
    SELECT * INTO v_bill_record
    FROM bills
    WHERE id = p_bill_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bill not found';
    END IF;
    
    -- Loop through each employee
    FOREACH v_employee_id IN ARRAY p_employee_ids
    LOOP
        -- Find applicable commission rule (highest priority)
        SELECT cr.* INTO v_rule
        FROM commission_rules cr
        LEFT JOIN users u ON cr.user_id = u.id
        WHERE cr.company_id = v_bill_record.company_id
            AND cr.is_active = true
            AND v_bill_record.bill_date::DATE BETWEEN cr.effective_from AND COALESCE(cr.effective_to, '2100-12-31'::DATE)
            AND v_bill_record.total_amount >= cr.min_bill_amount
            AND (cr.max_bill_amount IS NULL OR v_bill_record.total_amount <= cr.max_bill_amount)
            AND (
                cr.applies_to = 'all'
                OR (cr.applies_to = 'individual' AND cr.user_id = v_employee_id)
                OR (cr.applies_to = 'role' AND cr.role = (SELECT role FROM users WHERE id = v_employee_id))
            )
        ORDER BY cr.priority DESC, cr.created_at DESC
        LIMIT 1;
        
        IF FOUND THEN
            v_commission_pct := v_rule.commission_percentage;
            v_commission_amt := v_bill_record.total_amount * v_commission_pct / 100;
            
            -- Insert commission record
            INSERT INTO bill_commissions (
                bill_id,
                employee_id,
                commission_rule_id,
                commission_percentage,
                base_amount,
                commission_amount,
                status
            ) VALUES (
                p_bill_id,
                v_employee_id,
                v_rule.id,
                v_commission_pct,
                v_bill_record.total_amount,
                v_commission_amt,
                'pending'
            )
            ON CONFLICT (bill_id, employee_id) DO UPDATE
            SET 
                commission_rule_id = v_rule.id,
                commission_percentage = v_commission_pct,
                base_amount = v_bill_record.total_amount,
                commission_amount = v_commission_amt;
            
            -- Return result
            employee_id := v_employee_id;
            commission_amount := v_commission_amt;
            commission_percentage := v_commission_pct;
            rule_id := v_rule.id;
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get commission summary for employee
CREATE OR REPLACE FUNCTION get_employee_commission_summary(
    p_employee_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_commissions DECIMAL,
    pending_commissions DECIMAL,
    approved_commissions DECIMAL,
    paid_commissions DECIMAL,
    bill_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(bc.commission_amount), 0) as total_commissions,
        COALESCE(SUM(CASE WHEN bc.status = 'pending' THEN bc.commission_amount ELSE 0 END), 0) as pending_commissions,
        COALESCE(SUM(CASE WHEN bc.status = 'approved' THEN bc.commission_amount ELSE 0 END), 0) as approved_commissions,
        COALESCE(SUM(CASE WHEN bc.status = 'paid' THEN bc.commission_amount ELSE 0 END), 0) as paid_commissions,
        COUNT(DISTINCT bc.bill_id) as bill_count
    FROM bill_commissions bc
    JOIN bills b ON bc.bill_id = b.id
    WHERE bc.employee_id = p_employee_id
        AND (p_start_date IS NULL OR b.bill_date >= p_start_date)
        AND (p_end_date IS NULL OR b.bill_date <= p_end_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Insert default commission rule for all employees (example: 5%)
-- This will be created by CEO through the UI
-- INSERT INTO commission_rules (company_id, rule_name, description, applies_to, commission_percentage, created_by)
-- SELECT id, 'Default Staff Commission', 'Default 5% commission for all staff', 'all', 5.00, ceo_id
-- FROM companies
-- WHERE ceo_id IS NOT NULL
-- LIMIT 1;

COMMENT ON TABLE bills IS 'Hóa đơn bán hàng được upload bởi quản lý';
COMMENT ON TABLE commission_rules IS 'Quy tắc hoa hồng do CEO thiết lập';
COMMENT ON TABLE bill_commissions IS 'Hoa hồng cụ thể cho từng nhân viên từ bill';
COMMENT ON TABLE commission_rule_history IS 'Lịch sử thay đổi quy tắc hoa hồng';
