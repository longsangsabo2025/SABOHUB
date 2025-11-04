-- =====================================================
-- COMMISSION SYSTEM MIGRATION (NO RLS VERSION)
-- Hệ thống quản lý hoa hồng từ bill cho nhân viên
-- =====================================================

-- 1. Bảng Bills (Hóa đơn)
CREATE TABLE IF NOT EXISTS bills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    store_name TEXT, -- Tên cửa hàng (text đơn giản)
    bill_number TEXT NOT NULL,
    bill_date TIMESTAMPTZ NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL CHECK (total_amount >= 0),
    bill_image_url TEXT,
    ocr_data JSONB, -- Dữ liệu từ AI OCR
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
    uploaded_by UUID NOT NULL REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT unique_bill_number_per_company UNIQUE (company_id, bill_number)
);

COMMENT ON TABLE bills IS 'Bảng lưu trữ hóa đơn/bill được Manager upload';
COMMENT ON COLUMN bills.ocr_data IS 'Dữ liệu JSON từ AI OCR: {items: [], confidence: 0.95, raw_text: "..."}';
COMMENT ON COLUMN bills.status IS 'pending: chờ duyệt, approved: đã duyệt, rejected: từ chối, paid: đã thanh toán';

-- 2. Bảng Commission Rules (Quy tắc hoa hồng do CEO thiết lập)
CREATE TABLE IF NOT EXISTS commission_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    rule_name TEXT NOT NULL,
    description TEXT,
    applies_to TEXT NOT NULL DEFAULT 'all' CHECK (applies_to IN ('all', 'role', 'individual')),
    role TEXT, -- Nếu applies_to = 'role': 'ceo', 'manager', 'staff', etc.
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- Nếu applies_to = 'individual'
    commission_percentage DECIMAL(5,2) NOT NULL CHECK (commission_percentage >= 0 AND commission_percentage <= 100),
    min_bill_amount DECIMAL(15,2) DEFAULT 0 CHECK (min_bill_amount >= 0),
    max_bill_amount DECIMAL(15,2),
    is_active BOOLEAN NOT NULL DEFAULT true,
    priority INT DEFAULT 0, -- Số càng lớn càng ưu tiên
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CHECK (max_bill_amount IS NULL OR max_bill_amount > min_bill_amount),
    CHECK (effective_to IS NULL OR effective_to > effective_from)
);

COMMENT ON TABLE commission_rules IS 'Quy tắc hoa hồng do CEO thiết lập';
COMMENT ON COLUMN commission_rules.applies_to IS 'all: tất cả nhân viên, role: theo vai trò, individual: cá nhân cụ thể';
COMMENT ON COLUMN commission_rules.priority IS 'Quy tắc có priority cao hơn (số lớn hơn) sẽ được áp dụng trước';

-- 3. Bảng Bill Commissions (Hoa hồng từng nhân viên cho từng bill)
CREATE TABLE IF NOT EXISTS bill_commissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bill_id UUID NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    commission_rule_id UUID REFERENCES commission_rules(id) ON DELETE SET NULL,
    commission_percentage DECIMAL(5,2) NOT NULL,
    base_amount DECIMAL(15,2) NOT NULL, -- Số tiền được tính hoa hồng
    commission_amount DECIMAL(15,2) NOT NULL, -- Tiền hoa hồng thực tế
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    paid_by UUID REFERENCES users(id),
    paid_at TIMESTAMPTZ,
    payment_reference TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT unique_bill_employee_commission UNIQUE (bill_id, employee_id)
);

COMMENT ON TABLE bill_commissions IS 'Bảng lưu hoa hồng của từng nhân viên cho từng bill';
COMMENT ON COLUMN bill_commissions.base_amount IS 'Số tiền bill được tính hoa hồng (có thể khác total_amount nếu có quy tắc min/max)';

-- 4. Bảng Commission Rule History (Lịch sử thay đổi quy tắc - để audit)
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

COMMENT ON TABLE commission_rule_history IS 'Lưu lịch sử thay đổi quy tắc hoa hồng để audit';

-- =====================================================
-- INDEXES for Performance
-- =====================================================

-- Bills indexes
CREATE INDEX IF NOT EXISTS idx_bills_company_id ON bills(company_id);
CREATE INDEX IF NOT EXISTS idx_bills_store_name ON bills(store_name);
CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_bill_date ON bills(bill_date DESC);
CREATE INDEX IF NOT EXISTS idx_bills_uploaded_by ON bills(uploaded_by);

-- Commission Rules indexes
CREATE INDEX IF NOT EXISTS idx_commission_rules_company_id ON commission_rules(company_id);
CREATE INDEX IF NOT EXISTS idx_commission_rules_is_active ON commission_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_commission_rules_applies_to ON commission_rules(applies_to);
CREATE INDEX IF NOT EXISTS idx_commission_rules_user_id ON commission_rules(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_commission_rules_role ON commission_rules(role) WHERE role IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_commission_rules_effective_dates ON commission_rules(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_commission_rules_priority ON commission_rules(priority DESC);

-- Bill Commissions indexes
CREATE INDEX IF NOT EXISTS idx_bill_commissions_bill_id ON bill_commissions(bill_id);
CREATE INDEX IF NOT EXISTS idx_bill_commissions_employee_id ON bill_commissions(employee_id);
CREATE INDEX IF NOT EXISTS idx_bill_commissions_status ON bill_commissions(status);
CREATE INDEX IF NOT EXISTS idx_bill_commissions_created_at ON bill_commissions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bill_commissions_paid_at ON bill_commissions(paid_at DESC) WHERE paid_at IS NOT NULL;

-- Commission Rule History indexes
CREATE INDEX IF NOT EXISTS idx_commission_rule_history_rule_id ON commission_rule_history(rule_id);
CREATE INDEX IF NOT EXISTS idx_commission_rule_history_created_at ON commission_rule_history(created_at DESC);

-- =====================================================
-- TRIGGERS for Updated_at
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for each table
CREATE TRIGGER update_bills_updated_at BEFORE UPDATE ON bills
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_commission_rules_updated_at BEFORE UPDATE ON commission_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bill_commissions_updated_at BEFORE UPDATE ON bill_commissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTIONS for Business Logic
-- =====================================================

-- Function: Tính toán hoa hồng cho bill
CREATE OR REPLACE FUNCTION calculate_bill_commissions(
    p_bill_id UUID,
    p_employee_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
    employee_id UUID,
    commission_amount DECIMAL,
    commission_percentage DECIMAL,
    rule_applied TEXT
) AS $$
DECLARE
    v_bill RECORD;
    v_employee_id UUID;
    v_rule RECORD;
    v_base_amount DECIMAL;
    v_commission DECIMAL;
BEGIN
    -- Lấy thông tin bill
    SELECT * INTO v_bill FROM bills WHERE id = p_bill_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bill not found: %', p_bill_id;
    END IF;
    
    -- Nếu không chỉ định employee_ids, lấy tất cả nhân viên trong company
    IF p_employee_ids IS NULL THEN
        p_employee_ids := ARRAY(
            SELECT id FROM users 
            WHERE company_id = v_bill.company_id 
            AND is_active = true
        );
    END IF;
    
    -- Tính hoa hồng cho từng nhân viên
    FOREACH v_employee_id IN ARRAY p_employee_ids
    LOOP
        -- Tìm rule phù hợp (ưu tiên cao nhất, is_active = true, trong thời gian hiệu lực)
        SELECT * INTO v_rule
        FROM commission_rules
        WHERE company_id = v_bill.company_id
            AND is_active = true
            AND (effective_from <= v_bill.bill_date::DATE)
            AND (effective_to IS NULL OR effective_to >= v_bill.bill_date::DATE)
            AND (min_bill_amount <= v_bill.total_amount)
            AND (max_bill_amount IS NULL OR max_bill_amount >= v_bill.total_amount)
            AND (
                applies_to = 'all'
                OR (applies_to = 'role' AND role = (SELECT role FROM users WHERE id = v_employee_id))
                OR (applies_to = 'individual' AND user_id = v_employee_id)
            )
        ORDER BY priority DESC, created_at DESC
        LIMIT 1;
        
        IF FOUND THEN
            -- Tính base_amount (tuân theo min/max của rule)
            v_base_amount := v_bill.total_amount;
            
            IF v_rule.min_bill_amount > 0 AND v_base_amount < v_rule.min_bill_amount THEN
                v_base_amount := v_rule.min_bill_amount;
            END IF;
            
            IF v_rule.max_bill_amount IS NOT NULL AND v_base_amount > v_rule.max_bill_amount THEN
                v_base_amount := v_rule.max_bill_amount;
            END IF;
            
            -- Tính commission
            v_commission := ROUND(v_base_amount * v_rule.commission_percentage / 100, 2);
            
            -- Insert hoặc update bill_commissions
            INSERT INTO bill_commissions (
                bill_id, employee_id, commission_rule_id,
                commission_percentage, base_amount, commission_amount,
                status
            ) VALUES (
                p_bill_id, v_employee_id, v_rule.id,
                v_rule.commission_percentage, v_base_amount, v_commission,
                'pending'
            )
            ON CONFLICT (bill_id, employee_id) DO UPDATE
            SET commission_rule_id = EXCLUDED.commission_rule_id,
                commission_percentage = EXCLUDED.commission_percentage,
                base_amount = EXCLUDED.base_amount,
                commission_amount = EXCLUDED.commission_amount,
                updated_at = NOW();
            
            -- Return result
            employee_id := v_employee_id;
            commission_amount := v_commission;
            commission_percentage := v_rule.commission_percentage;
            rule_applied := v_rule.rule_name;
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_bill_commissions IS 'Tính toán và lưu hoa hồng cho bill. Nếu không truyền employee_ids thì tính cho tất cả nhân viên trong company.';

-- Function: Lấy tổng hợp hoa hồng của nhân viên
CREATE OR REPLACE FUNCTION get_employee_commission_summary(
    p_employee_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_commission DECIMAL,
    pending_commission DECIMAL,
    approved_commission DECIMAL,
    paid_commission DECIMAL,
    total_bills INT,
    pending_bills INT,
    approved_bills INT,
    paid_bills INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(bc.commission_amount), 0) as total_commission,
        COALESCE(SUM(CASE WHEN bc.status = 'pending' THEN bc.commission_amount ELSE 0 END), 0) as pending_commission,
        COALESCE(SUM(CASE WHEN bc.status = 'approved' THEN bc.commission_amount ELSE 0 END), 0) as approved_commission,
        COALESCE(SUM(CASE WHEN bc.status = 'paid' THEN bc.commission_amount ELSE 0 END), 0) as paid_commission,
        COUNT(*)::INT as total_bills,
        COUNT(CASE WHEN bc.status = 'pending' THEN 1 END)::INT as pending_bills,
        COUNT(CASE WHEN bc.status = 'approved' THEN 1 END)::INT as approved_bills,
        COUNT(CASE WHEN bc.status = 'paid' THEN 1 END)::INT as paid_bills
    FROM bill_commissions bc
    JOIN bills b ON bc.bill_id = b.id
    WHERE bc.employee_id = p_employee_id
        AND (p_start_date IS NULL OR b.bill_date >= p_start_date::TIMESTAMPTZ)
        AND (p_end_date IS NULL OR b.bill_date <= p_end_date::TIMESTAMPTZ);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_employee_commission_summary IS 'Lấy tổng hợp hoa hồng của nhân viên trong khoảng thời gian';

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
