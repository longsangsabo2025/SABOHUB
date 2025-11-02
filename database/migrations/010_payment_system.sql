-- ============================================
-- Migration 010: Payment System
-- Created: ${new Date().toISOString()}
-- Purpose: Complete payment integration (VNPay, MoMo, Cash, Card)
-- ============================================

-- ==========================================
-- 1. PAYMENT METHODS
-- ==========================================
CREATE TABLE IF NOT EXISTS payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL, -- vnpay, momo, cash, card, transfer
  type VARCHAR(20) NOT NULL CHECK (type IN ('online', 'offline', 'ewallet', 'card')),
  provider VARCHAR(100), -- VNPay, MoMo, etc.
  icon VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  config JSONB DEFAULT '{}', -- API credentials, endpoints
  display_order INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payment_methods_active ON payment_methods(is_active);
CREATE INDEX idx_payment_methods_code ON payment_methods(code);

-- ==========================================
-- 2. PAYMENTS
-- ==========================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  method_id UUID REFERENCES payment_methods(id),
  method_code VARCHAR(50), -- Denormalized for quick lookup
  amount DECIMAL(12,2) NOT NULL,
  transaction_id VARCHAR(255), -- External transaction ID from provider
  reference_number VARCHAR(255), -- Internal reference
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'success', 'failed', 'refunded', 'cancelled')),
  payment_url TEXT, -- For QR code or redirect
  qr_code_data TEXT, -- QR code content
  paid_at TIMESTAMP WITH TIME ZONE,
  refunded_at TIMESTAMP WITH TIME ZONE,
  failed_reason TEXT,
  metadata JSONB DEFAULT '{}', -- Provider-specific data
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_transaction ON payments(transaction_id);
CREATE INDEX idx_payments_created_at ON payments(created_at DESC);
CREATE INDEX idx_payments_method ON payments(method_id);
CREATE INDEX idx_payments_pending ON payments(status, created_at DESC) WHERE status = 'pending';

-- ==========================================
-- 3. PAYMENT WEBHOOKS
-- ==========================================
CREATE TABLE IF NOT EXISTS payment_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  provider VARCHAR(50) NOT NULL, -- vnpay, momo
  event_type VARCHAR(100) NOT NULL, -- payment.success, payment.failed, refund.success
  payload JSONB NOT NULL, -- Full webhook payload
  signature TEXT, -- Webhook signature for verification
  is_valid BOOLEAN DEFAULT FALSE,
  processed BOOLEAN DEFAULT FALSE,
  processed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  retry_count INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_webhooks_payment ON payment_webhooks(payment_id);
CREATE INDEX idx_webhooks_provider ON payment_webhooks(provider);
CREATE INDEX idx_webhooks_processed ON payment_webhooks(processed);
CREATE INDEX idx_webhooks_unprocessed ON payment_webhooks(created_at DESC) WHERE processed = FALSE;

-- ==========================================
-- 4. PAYMENT SPLITS (for split bills)
-- ==========================================
CREATE TABLE IF NOT EXISTS payment_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES payments(id) ON DELETE CASCADE,
  split_number INT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  customer_name VARCHAR(255),
  customer_phone VARCHAR(20),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payment_splits_order ON payment_splits(order_id);
CREATE INDEX idx_payment_splits_payment ON payment_splits(payment_id);

-- ==========================================
-- 5. REFUNDS
-- ==========================================
CREATE TABLE IF NOT EXISTS refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID REFERENCES payments(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL,
  reason TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'success', 'failed')),
  transaction_id VARCHAR(255), -- Refund transaction ID from provider
  processed_at TIMESTAMP WITH TIME ZONE,
  requested_by UUID REFERENCES users(id),
  approved_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_refunds_payment ON refunds(payment_id);
CREATE INDEX idx_refunds_status ON refunds(status);

-- ==========================================
-- INSERT DEFAULT PAYMENT METHODS
-- ==========================================

INSERT INTO payment_methods (name, code, type, provider, icon, is_active, display_order) VALUES
  ('Tiền mặt', 'cash', 'offline', NULL, '💵', TRUE, 1),
  ('Thẻ', 'card', 'card', NULL, '💳', TRUE, 2),
  ('VNPay', 'vnpay', 'online', 'VNPay', '🏦', TRUE, 3),
  ('MoMo', 'momo', 'ewallet', 'MoMo', '📱', TRUE, 4),
  ('Chuyển khoản', 'transfer', 'offline', NULL, '🏧', TRUE, 5)
ON CONFLICT (code) DO NOTHING;

-- ==========================================
-- TRIGGERS
-- ==========================================

-- Auto-update payment status on order
CREATE OR REPLACE FUNCTION update_order_payment_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'success' THEN
    UPDATE orders 
    SET status = 'completed',
        completed_at = NOW()
    WHERE id = NEW.order_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payment_success_trigger
AFTER UPDATE ON payments
FOR EACH ROW
WHEN (NEW.status = 'success' AND OLD.status != 'success')
EXECUTE FUNCTION update_order_payment_status();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_payments_updated_at
BEFORE UPDATE ON payments
FOR EACH ROW
EXECUTE FUNCTION update_payments_updated_at();

-- ==========================================
-- RLS POLICIES
-- ==========================================

ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;

-- Payment methods: All users can view active methods
CREATE POLICY "Users can view active payment methods"
  ON payment_methods FOR SELECT
  USING (is_active = TRUE);

-- Payments: Users can view their own, managers can view all
CREATE POLICY "Users can view relevant payments"
  ON payments FOR SELECT
  USING (created_by = auth.uid() OR is_manager_or_above());

CREATE POLICY "Staff can create payments"
  ON payments FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

-- Webhooks: System only
CREATE POLICY "System can manage webhooks"
  ON payment_webhooks FOR ALL
  USING (true);

-- Payment splits: Follow payment permissions
CREATE POLICY "Users can view payment splits"
  ON payment_splits FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM payments
      WHERE payments.id = payment_splits.payment_id
      AND (payments.created_by = auth.uid() OR is_manager_or_above())
    )
  );

-- Refunds: Managers only
CREATE POLICY "Managers can manage refunds"
  ON refunds FOR ALL
  USING (is_manager_or_above())
  WITH CHECK (is_manager_or_above());

-- ==========================================
-- COMMENTS
-- ==========================================

COMMENT ON TABLE payment_methods IS 'Available payment methods (cash, card, VNPay, MoMo, etc.)';
COMMENT ON TABLE payments IS 'Payment transactions for orders';
COMMENT ON TABLE payment_webhooks IS 'Webhook events from payment providers';
COMMENT ON TABLE payment_splits IS 'Split bill payments for shared orders';
COMMENT ON TABLE refunds IS 'Payment refund requests and processing';

-- ==========================================
-- END OF MIGRATION
-- ==========================================

