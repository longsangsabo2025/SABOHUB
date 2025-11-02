-- ============================================================================
-- MISSING TABLES SUPPLEMENT
-- ============================================================================
-- Creates 6 tables that were not in original schema files:
-- 1. order_items
-- 2. customers
-- 3. task_comments
-- 4. notifications
-- 5. analytics_events
-- 6. check_ins
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ORDER_ITEMS - Line items for orders
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  notes TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'preparing', 'ready', 'served', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_status ON order_items(status);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Staff can manage order items for their store
CREATE POLICY "Staff can manage order items"
  ON order_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM orders o
      JOIN tables t ON o.table_id = t.id
      JOIN users u ON u.id = auth.uid()
      WHERE o.id = order_items.order_id
        AND (
          u.role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF')
        )
    )
  );

-- ----------------------------------------------------------------------------
-- 2. CUSTOMERS - Customer information for analytics and loyalty
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(255),
  email VARCHAR(255),
  birthday DATE,
  gender VARCHAR(20) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  address TEXT,
  notes TEXT,
  total_visits INTEGER DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0,
  last_visit_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_last_visit ON customers(last_visit_at);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Staff can read customers
CREATE POLICY "Staff can read customers"
  ON customers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
        AND users.role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF')
    )
  );

-- MANAGER and CEO can manage customers
CREATE POLICY "Managers can manage customers"
  ON customers
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
        AND users.role IN ('CEO', 'MANAGER')
    )
  );

-- ----------------------------------------------------------------------------
-- 3. TASK_COMMENTS - Comments/updates on tasks
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS task_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX idx_task_comments_user_id ON task_comments(user_id);
CREATE INDEX idx_task_comments_created_at ON task_comments(created_at DESC);

ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

-- Users can read comments on tasks they can see
CREATE POLICY "Users can read task comments"
  ON task_comments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tasks t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = task_comments.task_id
        AND (
          u.role IN ('CEO', 'MANAGER', 'SHIFT_LEADER')
          OR t.assigned_to = u.id
        )
    )
  );

-- Users can create comments on tasks
CREATE POLICY "Users can create task comments"
  ON task_comments
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM tasks t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = task_comments.task_id
        AND (
          u.role IN ('CEO', 'MANAGER', 'SHIFT_LEADER')
          OR t.assigned_to = u.id
        )
    )
  );

-- Users can update their own comments
CREATE POLICY "Users can update own comments"
  ON task_comments
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 4. NOTIFICATIONS - Unified notifications table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN (
    'task_assigned', 'task_completed', 'task_overdue',
    'shift_reminder', 'shift_updated',
    'order_ready', 'table_request',
    'alert_triggered', 'maintenance_due',
    'purchase_request_approved', 'purchase_request_rejected',
    'system', 'other'
  )),
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_priority ON notifications(priority);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
CREATE POLICY "Users can read own notifications"
  ON notifications
  FOR SELECT
  USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- System can create notifications (via service role)
CREATE POLICY "Service role can manage notifications"
  ON notifications
  FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- 5. ANALYTICS_EVENTS - Event tracking for analytics
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  session_id UUID,
  properties JSONB,
  device_info JSONB,
  location VARCHAR(255),
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_analytics_events_event_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_events_session_id ON analytics_events(session_id);
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at DESC);
CREATE INDEX idx_analytics_events_properties ON analytics_events USING gin(properties);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- CEO and MANAGER can read analytics
CREATE POLICY "Managers can read analytics"
  ON analytics_events
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
        AND users.role IN ('CEO', 'MANAGER')
    )
  );

-- Service role can insert events
CREATE POLICY "Service role can insert analytics"
  ON analytics_events
  FOR INSERT
  WITH CHECK (auth.jwt()->>'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- 6. CHECK_INS - Staff attendance tracking
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES shifts(id) ON DELETE SET NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('check_in', 'check_out', 'break_start', 'break_end')),
  location JSONB,
  photo_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_check_ins_user_id ON check_ins(user_id);
CREATE INDEX idx_check_ins_shift_id ON check_ins(shift_id);
CREATE INDEX idx_check_ins_type ON check_ins(type);
CREATE INDEX idx_check_ins_created_at ON check_ins(created_at DESC);

ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

-- Users can read own check-ins
CREATE POLICY "Users can read own check-ins"
  ON check_ins
  FOR SELECT
  USING (user_id = auth.uid());

-- Users can create own check-ins
CREATE POLICY "Users can create own check-ins"
  ON check_ins
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Managers can read all check-ins
CREATE POLICY "Managers can read all check-ins"
  ON check_ins
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
        AND users.role IN ('CEO', 'MANAGER', 'SHIFT_LEADER')
    )
  );

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables with updated_at column
CREATE TRIGGER update_order_items_updated_at
  BEFORE UPDATE ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_task_comments_updated_at
  BEFORE UPDATE ON task_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE order_items IS 'Line items for customer orders - links orders to products';
COMMENT ON TABLE customers IS 'Customer information for loyalty program and analytics';
COMMENT ON TABLE task_comments IS 'Comments and updates on tasks for collaboration';
COMMENT ON TABLE notifications IS 'Unified notification system for all user alerts';
COMMENT ON TABLE analytics_events IS 'Event tracking for business analytics and insights';
COMMENT ON TABLE check_ins IS 'Staff attendance check-in/out records with location tracking';

-- ============================================================================
-- END OF MISSING TABLES
-- ============================================================================
