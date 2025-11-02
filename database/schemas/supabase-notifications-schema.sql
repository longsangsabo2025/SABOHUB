-- PHASE 8: NOTIFICATIONS SCHEMA

-- Internal Notifications Table
CREATE TABLE IF NOT EXISTS internal_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  link TEXT,
  
  target_type TEXT NOT NULL CHECK (target_type IN ('all', 'role', 'individual')),
  target_role TEXT CHECK (target_role IN ('ceo', 'general_manager', 'shift_leader', 'staff', 'technical')),
  target_user_ids UUID[],
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification Read Status
CREATE TABLE IF NOT EXISTS notification_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES internal_notifications(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(notification_id, user_id)
);

-- Customer Notifications Table
CREATE TABLE IF NOT EXISTS customer_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('promotion', 'tournament', 'news')),
  
  target_type TEXT NOT NULL CHECK (target_type IN ('all', 'vip', 'inactive')),
  inactive_days INTEGER,
  
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  
  views_count INTEGER DEFAULT 0,
  clicks_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customer Notification Analytics
CREATE TABLE IF NOT EXISTS customer_notification_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES customer_notifications(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL,
  
  viewed_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_internal_notifications_store ON internal_notifications(store_id);
CREATE INDEX IF NOT EXISTS idx_internal_notifications_sender ON internal_notifications(sender_id);
CREATE INDEX IF NOT EXISTS idx_internal_notifications_created ON internal_notifications(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_reads_notification ON notification_reads(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_reads_user ON notification_reads(user_id);

CREATE INDEX IF NOT EXISTS idx_customer_notifications_store ON customer_notifications(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_notifications_type ON customer_notifications(type);
CREATE INDEX IF NOT EXISTS idx_customer_notifications_sent ON customer_notifications(sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_customer_notification_analytics_notification ON customer_notification_analytics(notification_id);
CREATE INDEX IF NOT EXISTS idx_customer_notification_analytics_customer ON customer_notification_analytics(customer_id);

-- RLS Policies
ALTER TABLE internal_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_notification_analytics ENABLE ROW LEVEL SECURITY;

-- Internal Notifications Policies
CREATE POLICY "Users can view notifications for their store"
  ON internal_notifications FOR SELECT
  USING (
    store_id IN (SELECT store_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Managers can create notifications"
  ON internal_notifications FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND store_id = internal_notifications.store_id
      AND role IN ('ceo', 'general_manager', 'shift_leader')
    )
  );

-- Notification Reads Policies
CREATE POLICY "Users can view their own read status"
  ON notification_reads FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can mark notifications as read"
  ON notification_reads FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Customer Notifications Policies
CREATE POLICY "Users can view customer notifications for their store"
  ON customer_notifications FOR SELECT
  USING (
    store_id IN (SELECT store_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Managers can create customer notifications"
  ON customer_notifications FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND store_id = customer_notifications.store_id
      AND role IN ('ceo', 'general_manager')
    )
  );

-- Customer Notification Analytics Policies
CREATE POLICY "Users can view analytics for their store notifications"
  ON customer_notification_analytics FOR SELECT
  USING (
    notification_id IN (
      SELECT id FROM customer_notifications 
      WHERE store_id IN (SELECT store_id FROM users WHERE id = auth.uid())
    )
  );

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_internal_notifications_updated_at
  BEFORE UPDATE ON internal_notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customer_notifications_updated_at
  BEFORE UPDATE ON customer_notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
