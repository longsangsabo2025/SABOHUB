-- Smart Alerts Schema
-- Phase 10: Smart Alerts System

-- Alert types enum
CREATE TYPE alert_type AS ENUM (
  'revenue_anomaly',
  'inventory_low',
  'inventory_expiring',
  'incident_emergency',
  'invoice_cancellation_suspicious',
  'suggestion_staffing',
  'suggestion_table_promotion',
  'suggestion_restock'
);

-- Alert severity enum
CREATE TYPE alert_severity AS ENUM (
  'info',
  'warning',
  'critical'
);

-- Smart alerts table
CREATE TABLE smart_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  alert_type alert_type NOT NULL,
  severity alert_severity NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT FALSE,
  is_dismissed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ
);

-- Alert recipients table (who should see this alert)
CREATE TABLE alert_recipients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alert_id UUID NOT NULL REFERENCES smart_alerts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alert actions table (track actions taken on alerts)
CREATE TABLE alert_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alert_id UUID NOT NULL REFERENCES smart_alerts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  action_data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Revenue anomaly tracking
CREATE TABLE revenue_anomaly_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  shift_type TEXT,
  actual_revenue DECIMAL(10, 2) NOT NULL,
  average_revenue DECIMAL(10, 2) NOT NULL,
  deviation_percentage DECIMAL(5, 2) NOT NULL,
  is_anomaly BOOLEAN DEFAULT FALSE,
  alert_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(venue_id, date, shift_type)
);

-- Inventory alert tracking
CREATE TABLE inventory_alert_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  item_id UUID NOT NULL,
  item_type TEXT NOT NULL,
  alert_type TEXT NOT NULL,
  current_quantity DECIMAL(10, 2) NOT NULL,
  threshold_quantity DECIMAL(10, 2),
  suggested_order_quantity DECIMAL(10, 2),
  alert_sent BOOLEAN DEFAULT FALSE,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invoice cancellation tracking
CREATE TABLE invoice_cancellation_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  cancellation_count INTEGER DEFAULT 1,
  alert_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(venue_id, user_id, date)
);

-- Indexes for performance
CREATE INDEX idx_smart_alerts_venue ON smart_alerts(venue_id);
CREATE INDEX idx_smart_alerts_type ON smart_alerts(alert_type);
CREATE INDEX idx_smart_alerts_severity ON smart_alerts(severity);
CREATE INDEX idx_smart_alerts_created ON smart_alerts(created_at DESC);
CREATE INDEX idx_smart_alerts_unread ON smart_alerts(venue_id, is_read) WHERE is_read = FALSE;

CREATE INDEX idx_alert_recipients_user ON alert_recipients(user_id);
CREATE INDEX idx_alert_recipients_alert ON alert_recipients(alert_id);
CREATE INDEX idx_alert_recipients_unread ON alert_recipients(user_id, is_read) WHERE is_read = FALSE;

CREATE INDEX idx_revenue_anomaly_venue_date ON revenue_anomaly_tracking(venue_id, date DESC);
CREATE INDEX idx_inventory_alert_venue ON inventory_alert_tracking(venue_id, created_at DESC);
CREATE INDEX idx_invoice_cancel_tracking ON invoice_cancellation_tracking(venue_id, user_id, date DESC);

-- RLS Policies
ALTER TABLE smart_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE revenue_anomaly_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_alert_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_cancellation_tracking ENABLE ROW LEVEL SECURITY;

-- Smart alerts policies
CREATE POLICY "Users can view alerts for their venue"
  ON smart_alerts FOR SELECT
  USING (
    venue_id IN (
      SELECT venue_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Managers can create alerts"
  ON smart_alerts FOR INSERT
  WITH CHECK (
    venue_id IN (
      SELECT venue_id FROM users 
      WHERE id = auth.uid() 
      AND role IN ('ceo', 'manager')
    )
  );

CREATE POLICY "Users can update their venue alerts"
  ON smart_alerts FOR UPDATE
  USING (
    venue_id IN (
      SELECT venue_id FROM users WHERE id = auth.uid()
    )
  );

-- Alert recipients policies
CREATE POLICY "Users can view their alert recipients"
  ON alert_recipients FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "System can create alert recipients"
  ON alert_recipients FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update their alert recipients"
  ON alert_recipients FOR UPDATE
  USING (user_id = auth.uid());

-- Alert actions policies
CREATE POLICY "Users can view alert actions for their venue"
  ON alert_actions FOR SELECT
  USING (
    alert_id IN (
      SELECT id FROM smart_alerts 
      WHERE venue_id IN (
        SELECT venue_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can create alert actions"
  ON alert_actions FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Revenue anomaly tracking policies
CREATE POLICY "Users can view revenue anomaly for their venue"
  ON revenue_anomaly_tracking FOR SELECT
  USING (
    venue_id IN (
      SELECT venue_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "System can manage revenue anomaly tracking"
  ON revenue_anomaly_tracking FOR ALL
  USING (true)
  WITH CHECK (true);

-- Inventory alert tracking policies
CREATE POLICY "Users can view inventory alerts for their venue"
  ON inventory_alert_tracking FOR SELECT
  USING (
    venue_id IN (
      SELECT venue_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "System can manage inventory alert tracking"
  ON inventory_alert_tracking FOR ALL
  USING (true)
  WITH CHECK (true);

-- Invoice cancellation tracking policies
CREATE POLICY "Managers can view invoice cancellation tracking"
  ON invoice_cancellation_tracking FOR SELECT
  USING (
    venue_id IN (
      SELECT venue_id FROM users 
      WHERE id = auth.uid() 
      AND role IN ('ceo', 'manager')
    )
  );

CREATE POLICY "System can manage invoice cancellation tracking"
  ON invoice_cancellation_tracking FOR ALL
  USING (true)
  WITH CHECK (true);
