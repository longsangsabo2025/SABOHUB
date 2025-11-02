-- =============================================
-- PHASE 11: ANALYTICS & FORECAST SCHEMA
-- =============================================

-- Customer tracking for VIP analysis
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  phone VARCHAR(20),
  member_id VARCHAR(50),
  name VARCHAR(255),
  email VARCHAR(255),
  total_spent DECIMAL(12,2) DEFAULT 0,
  visit_count INTEGER DEFAULT 0,
  last_visit_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(venue_id, phone),
  UNIQUE(venue_id, member_id)
);

CREATE INDEX idx_customers_venue ON customers(venue_id);
CREATE INDEX idx_customers_total_spent ON customers(venue_id, total_spent DESC);
CREATE INDEX idx_customers_visit_count ON customers(venue_id, visit_count DESC);

-- Link invoices to customers
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);

-- Analytics cache for performance
CREATE TABLE IF NOT EXISTS analytics_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  metric_type VARCHAR(100) NOT NULL,
  time_period VARCHAR(50) NOT NULL,
  data JSONB NOT NULL,
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  UNIQUE(venue_id, metric_type, time_period)
);

CREATE INDEX idx_analytics_cache_venue ON analytics_cache(venue_id);
CREATE INDEX idx_analytics_cache_expires ON analytics_cache(expires_at);

-- Product sales tracking
CREATE TABLE IF NOT EXISTS product_sales_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  quantity_sold INTEGER DEFAULT 0,
  revenue DECIMAL(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(venue_id, product_id, date)
);

CREATE INDEX idx_product_sales_venue_date ON product_sales_stats(venue_id, date DESC);
CREATE INDEX idx_product_sales_product ON product_sales_stats(product_id, date DESC);

-- Table usage statistics
CREATE TABLE IF NOT EXISTS table_usage_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  table_id UUID NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  session_count INTEGER DEFAULT 0,
  total_duration_minutes INTEGER DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(venue_id, table_id, date)
);

CREATE INDEX idx_table_usage_venue_date ON table_usage_stats(venue_id, date DESC);
CREATE INDEX idx_table_usage_table ON table_usage_stats(table_id, date DESC);

-- Hourly revenue tracking
CREATE TABLE IF NOT EXISTS hourly_revenue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
  revenue DECIMAL(12,2) DEFAULT 0,
  invoice_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(venue_id, date, hour)
);

CREATE INDEX idx_hourly_revenue_venue_date ON hourly_revenue(venue_id, date DESC, hour);

-- Inventory consumption tracking
CREATE TABLE IF NOT EXISTS inventory_consumption (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES beverage_inventory(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  quantity_consumed DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(venue_id, item_id, date)
);

CREATE INDEX idx_inventory_consumption_venue_date ON inventory_consumption(venue_id, date DESC);
CREATE INDEX idx_inventory_consumption_item ON inventory_consumption(item_id, date DESC);

-- Function to update customer stats when invoice is paid
CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'paid' AND (OLD.status IS NULL OR OLD.status != 'paid') THEN
    IF NEW.customer_id IS NOT NULL THEN
      UPDATE customers
      SET 
        total_spent = total_spent + NEW.total_amount,
        visit_count = visit_count + 1,
        last_visit_at = NEW.created_at,
        updated_at = NOW()
      WHERE id = NEW.customer_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_stats
AFTER INSERT OR UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION update_customer_stats();

-- Function to track hourly revenue
CREATE OR REPLACE FUNCTION track_hourly_revenue()
RETURNS TRIGGER AS $$
DECLARE
  revenue_hour INTEGER;
  revenue_date DATE;
BEGIN
  IF NEW.status = 'paid' AND (OLD.status IS NULL OR OLD.status != 'paid') THEN
    revenue_hour := EXTRACT(HOUR FROM NEW.created_at);
    revenue_date := DATE(NEW.created_at);
    
    INSERT INTO hourly_revenue (venue_id, date, hour, revenue, invoice_count)
    VALUES (NEW.venue_id, revenue_date, revenue_hour, NEW.total_amount, 1)
    ON CONFLICT (venue_id, date, hour)
    DO UPDATE SET
      revenue = hourly_revenue.revenue + NEW.total_amount,
      invoice_count = hourly_revenue.invoice_count + 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_hourly_revenue
AFTER INSERT OR UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION track_hourly_revenue();

-- Function to track product sales
CREATE OR REPLACE FUNCTION track_product_sales()
RETURNS TRIGGER AS $$
DECLARE
  order_record RECORD;
  sale_date DATE;
BEGIN
  IF NEW.status = 'paid' AND (OLD.status IS NULL OR OLD.status != 'paid') THEN
    sale_date := DATE(NEW.created_at);
    
    FOR order_record IN 
      SELECT product_id, quantity, price
      FROM orders
      WHERE invoice_id = NEW.id
    LOOP
      INSERT INTO product_sales_stats (venue_id, product_id, date, quantity_sold, revenue)
      VALUES (NEW.venue_id, order_record.product_id, sale_date, order_record.quantity, order_record.price * order_record.quantity)
      ON CONFLICT (venue_id, product_id, date)
      DO UPDATE SET
        quantity_sold = product_sales_stats.quantity_sold + order_record.quantity,
        revenue = product_sales_stats.revenue + (order_record.price * order_record.quantity);
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_product_sales
AFTER INSERT OR UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION track_product_sales();

-- Function to track table usage
CREATE OR REPLACE FUNCTION track_table_usage()
RETURNS TRIGGER AS $$
DECLARE
  session_date DATE;
  duration_minutes INTEGER;
  session_revenue DECIMAL(12,2);
BEGIN
  IF NEW.status = 'ended' AND (OLD.status IS NULL OR OLD.status != 'ended') THEN
    session_date := DATE(NEW.started_at);
    duration_minutes := EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at)) / 60;
    
    SELECT COALESCE(SUM(total_amount), 0) INTO session_revenue
    FROM invoices
    WHERE session_id = NEW.id AND status = 'paid';
    
    INSERT INTO table_usage_stats (venue_id, table_id, date, session_count, total_duration_minutes, total_revenue)
    VALUES (NEW.venue_id, NEW.table_id, session_date, 1, duration_minutes, session_revenue)
    ON CONFLICT (venue_id, table_id, date)
    DO UPDATE SET
      session_count = table_usage_stats.session_count + 1,
      total_duration_minutes = table_usage_stats.total_duration_minutes + duration_minutes,
      total_revenue = table_usage_stats.total_revenue + session_revenue;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_table_usage
AFTER INSERT OR UPDATE ON table_sessions
FOR EACH ROW
EXECUTE FUNCTION track_table_usage();

-- Function to track inventory consumption
CREATE OR REPLACE FUNCTION track_inventory_consumption()
RETURNS TRIGGER AS $$
DECLARE
  consumption_date DATE;
BEGIN
  IF NEW.transaction_type = 'out' THEN
    consumption_date := DATE(NEW.created_at);
    
    INSERT INTO inventory_consumption (venue_id, item_id, date, quantity_consumed)
    VALUES (NEW.venue_id, NEW.item_id, consumption_date, NEW.quantity)
    ON CONFLICT (venue_id, item_id, date)
    DO UPDATE SET
      quantity_consumed = inventory_consumption.quantity_consumed + NEW.quantity;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_inventory_consumption
AFTER INSERT ON beverage_inventory_transactions
FOR EACH ROW
EXECUTE FUNCTION track_inventory_consumption();

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_sales_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE table_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE hourly_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_consumption ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY customers_policy ON customers
  FOR ALL USING (
    venue_id IN (
      SELECT venue_id FROM user_venues WHERE user_id = auth.uid()
    )
  );

CREATE POLICY analytics_cache_policy ON analytics_cache
  FOR ALL USING (
    venue_id IN (
      SELECT venue_id FROM user_venues WHERE user_id = auth.uid()
    )
  );

CREATE POLICY product_sales_stats_policy ON product_sales_stats
  FOR ALL USING (
    venue_id IN (
      SELECT venue_id FROM user_venues WHERE user_id = auth.uid()
    )
  );

CREATE POLICY table_usage_stats_policy ON table_usage_stats
  FOR ALL USING (
    venue_id IN (
      SELECT venue_id FROM user_venues WHERE user_id = auth.uid()
    )
  );

CREATE POLICY hourly_revenue_policy ON hourly_revenue
  FOR ALL USING (
    venue_id IN (
      SELECT venue_id FROM user_venues WHERE user_id = auth.uid()
    )
  );

CREATE POLICY inventory_consumption_policy ON inventory_consumption
  FOR ALL USING (
    venue_id IN (
      SELECT venue_id FROM user_venues WHERE user_id = auth.uid()
    )
  );

-- Cleanup old analytics cache (run daily)
CREATE OR REPLACE FUNCTION cleanup_expired_analytics_cache()
RETURNS void AS $$
BEGIN
  DELETE FROM analytics_cache WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;
