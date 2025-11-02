-- ============================================
-- Migration 002: Create Orders & Sessions (Simplified)
-- ============================================

-- Part 1: Menu Items
CREATE TABLE IF NOT EXISTS menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('food', 'beverage', 'snack', 'equipment', 'other')),
  price DECIMAL(15,2) NOT NULL CHECK (price >= 0),
  cost_price DECIMAL(15,2) CHECK (cost_price >= 0),
  has_stock BOOLEAN DEFAULT false,
  current_stock DECIMAL(15,2) DEFAULT 0 CHECK (current_stock >= 0),
  min_stock DECIMAL(15,2) DEFAULT 0 CHECK (min_stock >= 0),
  unit TEXT DEFAULT 'piece',
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_menu_items_company ON menu_items(company_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category);

-- Part 2: Table Sessions
CREATE TABLE IF NOT EXISTS table_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_id UUID NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  session_number TEXT UNIQUE NOT NULL,
  customer_name TEXT,
  customer_phone TEXT,
  customer_count INTEGER DEFAULT 1 CHECK (customer_count > 0),
  start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  pause_time TIMESTAMPTZ,
  resume_time TIMESTAMPTZ,
  total_paused_minutes INTEGER DEFAULT 0 CHECK (total_paused_minutes >= 0),
  hourly_rate DECIMAL(15,2) NOT NULL CHECK (hourly_rate >= 0),
  table_amount DECIMAL(15,2) DEFAULT 0 CHECK (table_amount >= 0),
  orders_amount DECIMAL(15,2) DEFAULT 0 CHECK (orders_amount >= 0),
  discount DECIMAL(15,2) DEFAULT 0 CHECK (discount >= 0),
  total_amount DECIMAL(15,2) DEFAULT 0 CHECK (total_amount >= 0),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
  notes TEXT,
  cancellation_reason TEXT,
  started_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ended_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_sessions_table ON table_sessions(table_id);
CREATE INDEX IF NOT EXISTS idx_sessions_store ON table_sessions(store_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON table_sessions(status);

-- Part 3: Orders
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  table_id UUID REFERENCES tables(id) ON DELETE SET NULL,
  session_id UUID REFERENCES table_sessions(id) ON DELETE SET NULL,
  order_number TEXT UNIQUE NOT NULL,
  customer_name TEXT,
  customer_phone TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')),
  subtotal DECIMAL(15,2) DEFAULT 0 CHECK (subtotal >= 0),
  tax DECIMAL(15,2) DEFAULT 0 CHECK (tax >= 0),
  discount DECIMAL(15,2) DEFAULT 0 CHECK (discount >= 0),
  total DECIMAL(15,2) NOT NULL CHECK (total >= 0),
  notes TEXT,
  cancellation_reason TEXT,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  served_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ordered_at TIMESTAMPTZ DEFAULT NOW(),
  prepared_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_orders_company ON orders(company_id);
CREATE INDEX IF NOT EXISTS idx_orders_store ON orders(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_table ON orders(table_id);
CREATE INDEX IF NOT EXISTS idx_orders_session ON orders(session_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Part 4: Order Items
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE RESTRICT,
  item_name TEXT NOT NULL,
  item_category TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(15,2) NOT NULL CHECK (unit_price >= 0),
  total_price DECIMAL(15,2) NOT NULL CHECK (total_price >= 0),
  discount DECIMAL(15,2) DEFAULT 0 CHECK (discount >= 0),
  notes TEXT,
  special_requests TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'preparing', 'ready', 'served')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item ON order_items(menu_item_id);

-- Part 5: Seed Sample Data
INSERT INTO menu_items (company_id, name, category, price, cost_price, is_available)
SELECT 
  id, 'Coca Cola', 'beverage', 15000, 10000, true
FROM companies LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO menu_items (company_id, name, category, price, cost_price, is_available)
SELECT 
  id, 'Pepsi', 'beverage', 15000, 10000, true
FROM companies LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO menu_items (company_id, name, category, price, cost_price, is_available)
SELECT 
  id, 'Sting', 'beverage', 15000, 10000, true
FROM companies LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO menu_items (company_id, name, category, price, cost_price, is_available)
SELECT 
  id, 'Mì tôm', 'snack', 10000, 7000, true
FROM companies LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO menu_items (company_id, name, category, price, cost_price, is_available)
SELECT 
  id, 'Snack khoai tây', 'snack', 12000, 8000, true
FROM companies LIMIT 1
ON CONFLICT DO NOTHING;
