-- ============================================
-- Migration: Create Orders & Sessions System
-- Author: Backend Expert  
-- Date: 2025-11-02
-- Description: Core transaction tables for billiards management
-- ============================================

BEGIN;

RAISE NOTICE '🚀 Starting Orders & Sessions System Migration...';

-- ============================================
-- PART 1: MENU ITEMS (Required for Orders)
-- ============================================

CREATE TABLE IF NOT EXISTS menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  
  -- Item Info
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('food', 'beverage', 'snack', 'equipment', 'other')),
  
  -- Pricing
  price DECIMAL(15,2) NOT NULL CHECK (price >= 0),
  cost_price DECIMAL(15,2) CHECK (cost_price >= 0),
  
  -- Stock Management
  has_stock BOOLEAN DEFAULT false,
  current_stock DECIMAL(15,2) DEFAULT 0 CHECK (current_stock >= 0),
  min_stock DECIMAL(15,2) DEFAULT 0 CHECK (min_stock >= 0),
  unit TEXT DEFAULT 'piece',
  
  -- Media
  image_url TEXT,
  
  -- Status
  is_available BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes for menu_items
CREATE INDEX IF NOT EXISTS idx_menu_items_company ON menu_items(company_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category) WHERE deleted_at IS NULL AND is_active = true;
CREATE INDEX IF NOT EXISTS idx_menu_items_available ON menu_items(is_available, company_id) WHERE deleted_at IS NULL;

RAISE NOTICE '✅ Created menu_items table';

-- ============================================
-- PART 2: ORDERS SYSTEM
-- ============================================

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- References
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  table_id UUID REFERENCES tables(id) ON DELETE SET NULL,
  session_id UUID,  -- Will add FK after sessions table created
  
  -- Order Number (unique per branch)
  order_number TEXT UNIQUE NOT NULL,
  
  -- Customer Info
  customer_name TEXT,
  customer_phone TEXT,
  
  -- Order Status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')
  ),
  
  -- Financial Details
  subtotal DECIMAL(15,2) DEFAULT 0 CHECK (subtotal >= 0),
  tax DECIMAL(15,2) DEFAULT 0 CHECK (tax >= 0),
  discount DECIMAL(15,2) DEFAULT 0 CHECK (discount >= 0),
  total DECIMAL(15,2) NOT NULL CHECK (total >= 0),
  
  -- Notes
  notes TEXT,
  cancellation_reason TEXT,
  
  -- Staff
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  served_by UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Timestamps
  ordered_at TIMESTAMPTZ DEFAULT NOW(),
  prepared_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes for orders
CREATE INDEX IF NOT EXISTS idx_orders_company ON orders(company_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_orders_branch ON orders(branch_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_orders_table ON orders(table_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_orders_session ON orders(session_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status, branch_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number) WHERE deleted_at IS NULL;

-- Function to generate order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
  new_number TEXT;
  counter INTEGER;
BEGIN
  -- Get today's date in YYYYMMDD format
  SELECT TO_CHAR(NOW(), 'YYYYMMDD') INTO new_number;
  
  -- Count today's orders
  SELECT COUNT(*) INTO counter
  FROM orders
  WHERE order_number LIKE new_number || '%';
  
  -- Increment counter
  counter := counter + 1;
  
  -- Format: YYYYMMDD-0001
  new_number := new_number || '-' || LPAD(counter::TEXT, 4, '0');
  
  RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate order number
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    NEW.order_number := generate_order_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_order_number
  BEFORE INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION set_order_number();

RAISE NOTICE '✅ Created orders table with auto-numbering';

-- Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- References
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE RESTRICT,
  
  -- Item Details (denormalized for historical record)
  item_name TEXT NOT NULL,
  item_category TEXT NOT NULL,
  
  -- Quantity & Pricing
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(15,2) NOT NULL CHECK (unit_price >= 0),
  total_price DECIMAL(15,2) NOT NULL CHECK (total_price >= 0),
  
  -- Discount (optional, per item)
  discount DECIMAL(15,2) DEFAULT 0 CHECK (discount >= 0),
  
  -- Notes
  notes TEXT,
  special_requests TEXT,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'preparing', 'ready', 'served')
  ),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for order_items
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item ON order_items(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_order_items_status ON order_items(status);

-- Function to update order total when items change
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE orders
  SET 
    subtotal = (
      SELECT COALESCE(SUM(total_price - discount), 0)
      FROM order_items
      WHERE order_id = COALESCE(NEW.order_id, OLD.order_id)
    ),
    total = subtotal + tax - discount,
    updated_at = NOW()
  WHERE id = COALESCE(NEW.order_id, OLD.order_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_total
  AFTER INSERT OR UPDATE OR DELETE ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION update_order_total();

RAISE NOTICE '✅ Created order_items table with auto-calculation';

-- ============================================
-- PART 3: TABLE SESSIONS SYSTEM
-- ============================================

CREATE TABLE IF NOT EXISTS table_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- References
  table_id UUID NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  
  -- Session Number
  session_number TEXT UNIQUE NOT NULL,
  
  -- Customer Info
  customer_name TEXT,
  customer_phone TEXT,
  customer_count INTEGER DEFAULT 1 CHECK (customer_count > 0),
  
  -- Time Tracking
  start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  pause_time TIMESTAMPTZ,
  resume_time TIMESTAMPTZ,
  total_paused_minutes INTEGER DEFAULT 0 CHECK (total_paused_minutes >= 0),
  
  -- Pricing
  hourly_rate DECIMAL(15,2) NOT NULL CHECK (hourly_rate >= 0),
  table_amount DECIMAL(15,2) DEFAULT 0 CHECK (table_amount >= 0),    -- Tiền bàn
  orders_amount DECIMAL(15,2) DEFAULT 0 CHECK (orders_amount >= 0),   -- Tiền đồ ăn/uống
  discount DECIMAL(15,2) DEFAULT 0 CHECK (discount >= 0),
  total_amount DECIMAL(15,2) DEFAULT 0 CHECK (total_amount >= 0),
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (
    status IN ('active', 'paused', 'completed', 'cancelled')
  ),
  
  -- Notes
  notes TEXT,
  cancellation_reason TEXT,
  
  -- Staff
  started_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ended_by UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes for table_sessions
CREATE INDEX IF NOT EXISTS idx_sessions_table ON table_sessions(table_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_branch ON table_sessions(branch_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_company ON table_sessions(company_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_status ON table_sessions(status, branch_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_active ON table_sessions(table_id, status) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_start ON table_sessions(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_number ON table_sessions(session_number) WHERE deleted_at IS NULL;

-- Function to generate session number
CREATE OR REPLACE FUNCTION generate_session_number()
RETURNS TEXT AS $$
DECLARE
  new_number TEXT;
  counter INTEGER;
BEGIN
  -- Get today's date in YYYYMMDD format
  SELECT TO_CHAR(NOW(), 'YYYYMMDD') INTO new_number;
  
  -- Count today's sessions
  SELECT COUNT(*) INTO counter
  FROM table_sessions
  WHERE session_number LIKE new_number || '%';
  
  -- Increment counter
  counter := counter + 1;
  
  -- Format: YYYYMMDD-S-0001
  new_number := new_number || '-S-' || LPAD(counter::TEXT, 4, '0');
  
  RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate session number
CREATE OR REPLACE FUNCTION set_session_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.session_number IS NULL OR NEW.session_number = '' THEN
    NEW.session_number := generate_session_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_session_number
  BEFORE INSERT ON table_sessions
  FOR EACH ROW
  EXECUTE FUNCTION set_session_number();

-- Function to calculate session amounts
CREATE OR REPLACE FUNCTION calculate_session_amounts()
RETURNS TRIGGER AS $$
DECLARE
  playing_minutes INTEGER;
  playing_hours DECIMAL(10,2);
BEGIN
  -- Only calculate for active or completed sessions
  IF NEW.status IN ('active', 'completed') THEN
    -- Calculate total playing time (excluding paused time)
    playing_minutes := EXTRACT(EPOCH FROM (
      COALESCE(NEW.end_time, NOW()) - NEW.start_time
    ))::INTEGER / 60 - COALESCE(NEW.total_paused_minutes, 0);
    
    -- Convert to hours
    playing_hours := playing_minutes::DECIMAL / 60.0;
    
    -- Calculate table amount
    NEW.table_amount := ROUND(playing_hours * NEW.hourly_rate, 2);
    
    -- Get orders total for this session
    SELECT COALESCE(SUM(total), 0) INTO NEW.orders_amount
    FROM orders
    WHERE session_id = NEW.id
      AND status = 'completed'
      AND deleted_at IS NULL;
    
    -- Calculate total
    NEW.total_amount := NEW.table_amount + NEW.orders_amount - COALESCE(NEW.discount, 0);
  END IF;
  
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_session_amounts
  BEFORE UPDATE ON table_sessions
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status OR 
        OLD.end_time IS DISTINCT FROM NEW.end_time OR
        OLD.total_paused_minutes IS DISTINCT FROM NEW.total_paused_minutes)
  EXECUTE FUNCTION calculate_session_amounts();

-- Function to update table status based on session
CREATE OR REPLACE FUNCTION update_table_status_from_session()
RETURNS TRIGGER AS $$
BEGIN
  -- When session becomes active, mark table as occupied
  IF NEW.status = 'active' THEN
    UPDATE tables 
    SET status = 'occupied', updated_at = NOW()
    WHERE id = NEW.table_id;
  
  -- When session ends or is cancelled, mark table as available
  ELSIF NEW.status IN ('completed', 'cancelled') AND 
        (OLD.status IS NULL OR OLD.status NOT IN ('completed', 'cancelled')) THEN
    UPDATE tables 
    SET status = 'available', updated_at = NOW()
    WHERE id = NEW.table_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_table_status
  AFTER INSERT OR UPDATE ON table_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_table_status_from_session();

RAISE NOTICE '✅ Created table_sessions with auto-calculation and table status sync';

-- ============================================
-- PART 4: ADD FOREIGN KEY FROM ORDERS TO SESSIONS
-- ============================================

ALTER TABLE orders
ADD CONSTRAINT orders_session_id_fkey
FOREIGN KEY (session_id) REFERENCES table_sessions(id) ON DELETE SET NULL;

RAISE NOTICE '✅ Linked orders to sessions';

-- ============================================
-- PART 5: CREATE HELPER VIEWS
-- ============================================

-- View: Active Sessions with Details
CREATE OR REPLACE VIEW v_active_sessions AS
SELECT 
  s.id,
  s.session_number,
  s.table_id,
  t.name as table_name,
  t.table_type,
  s.branch_id,
  b.name as branch_name,
  s.company_id,
  c.name as company_name,
  s.customer_name,
  s.start_time,
  s.pause_time,
  s.total_paused_minutes,
  -- Calculate playing duration in minutes
  EXTRACT(EPOCH FROM (NOW() - s.start_time))::INTEGER / 60 - s.total_paused_minutes as playing_minutes,
  s.hourly_rate,
  s.table_amount,
  s.orders_amount,
  s.total_amount,
  s.status,
  u.full_name as started_by_name
FROM table_sessions s
JOIN tables t ON t.id = s.table_id
JOIN branches b ON b.id = s.branch_id
JOIN companies c ON c.id = s.company_id
LEFT JOIN users u ON u.id = s.started_by
WHERE s.status = 'active' AND s.deleted_at IS NULL;

-- View: Order Summary
CREATE OR REPLACE VIEW v_order_summary AS
SELECT 
  o.id,
  o.order_number,
  o.branch_id,
  b.name as branch_name,
  o.table_id,
  t.name as table_name,
  o.session_id,
  o.status,
  o.total,
  COUNT(oi.id) as item_count,
  SUM(oi.quantity) as total_quantity,
  o.created_at,
  u.full_name as created_by_name
FROM orders o
JOIN branches b ON b.id = o.branch_id
LEFT JOIN tables t ON t.id = o.table_id
LEFT JOIN order_items oi ON oi.order_id = o.id
LEFT JOIN users u ON u.id = o.created_by
WHERE o.deleted_at IS NULL
GROUP BY o.id, b.name, t.name, u.full_name;

RAISE NOTICE '✅ Created helper views';

-- ============================================
-- PART 6: SEED SAMPLE DATA
-- ============================================

-- Sample Menu Items
INSERT INTO menu_items (company_id, name, category, price, cost_price, is_available)
SELECT 
  id as company_id,
  unnest(ARRAY['Coca Cola', 'Pepsi', 'Sting', 'Number 1', 'Trà xanh']) as name,
  'beverage' as category,
  unnest(ARRAY[15000, 15000, 15000, 15000, 12000]::DECIMAL[]) as price,
  unnest(ARRAY[10000, 10000, 10000, 10000, 8000]::DECIMAL[]) as cost_price,
  true as is_available
FROM companies
WHERE business_type = 'billiards'
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO menu_items (company_id, name, category, price, cost_price, is_available)
SELECT 
  id as company_id,
  unnest(ARRAY['Mì tôm', 'Xúc xích', 'Snack khoai tây', 'Bánh quy', 'Kẹo cao su']) as name,
  'snack' as category,
  unnest(ARRAY[10000, 15000, 12000, 8000, 5000]::DECIMAL[]) as price,
  unnest(ARRAY[7000, 10000, 8000, 5000, 3000]::DECIMAL[]) as cost_price,
  true as is_available
FROM companies
WHERE business_type = 'billiards'
LIMIT 1
ON CONFLICT DO NOTHING;

RAISE NOTICE '✅ Seeded sample menu items';

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
DECLARE
  menu_count INTEGER;
  orders_count INTEGER;
  sessions_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO menu_count FROM menu_items WHERE deleted_at IS NULL;
  SELECT COUNT(*) INTO orders_count FROM orders WHERE deleted_at IS NULL;
  SELECT COUNT(*) INTO sessions_count FROM table_sessions WHERE deleted_at IS NULL;
  
  RAISE NOTICE '';
  RAISE NOTICE '==================================================';
  RAISE NOTICE '✅ Orders & Sessions System Migration Complete!';
  RAISE NOTICE '==================================================';
  RAISE NOTICE 'Created Tables:';
  RAISE NOTICE '  ✅ menu_items';
  RAISE NOTICE '  ✅ orders';
  RAISE NOTICE '  ✅ order_items';
  RAISE NOTICE '  ✅ table_sessions';
  RAISE NOTICE '';
  RAISE NOTICE 'Current Data:';
  RAISE NOTICE '  - Menu Items: %', menu_count;
  RAISE NOTICE '  - Orders: %', orders_count;
  RAISE NOTICE '  - Sessions: %', sessions_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Features:';
  RAISE NOTICE '  ✅ Auto-numbering for orders & sessions';
  RAISE NOTICE '  ✅ Auto-calculation of totals';
  RAISE NOTICE '  ✅ Table status sync with sessions';
  RAISE NOTICE '  ✅ Helper views for queries';
  RAISE NOTICE '  ✅ Sample menu data';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  1. Create Flutter services for orders & sessions';
  RAISE NOTICE '  2. Test session start/pause/end flow';
  RAISE NOTICE '  3. Test order creation & item management';
  RAISE NOTICE '  4. Implement RLS policies';
  RAISE NOTICE '';
END $$;

COMMIT;
