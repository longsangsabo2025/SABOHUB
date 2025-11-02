-- ===================================
-- TABLE MANAGEMENT MIGRATION
-- Tables, Orders, Order Items for Restaurant POS
-- ===================================

-- Enable UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===================================
-- TABLES TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS public.tables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL,
  floor INTEGER DEFAULT 2,
  status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'reserved')),
  capacity INTEGER DEFAULT 4,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE
);

-- Index for tables
CREATE INDEX IF NOT EXISTS idx_tables_status ON public.tables(status);
CREATE INDEX IF NOT EXISTS idx_tables_floor ON public.tables(floor);
CREATE INDEX IF NOT EXISTS idx_tables_store_id ON public.tables(store_id);

-- ===================================
-- ORDERS TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_id UUID REFERENCES public.tables(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  total_amount DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE
);

-- Index for orders
CREATE INDEX IF NOT EXISTS idx_orders_table_id ON public.orders(table_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_store_id ON public.orders(store_id);

-- ===================================
-- ORDER ITEMS TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  item_name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  quantity INTEGER DEFAULT 1,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for order items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_item_name ON public.order_items(item_name);

-- ===================================
-- INSERT SAMPLE DATA
-- ===================================

-- Insert sample tables
INSERT INTO public.tables (name, floor, status, capacity) VALUES
  ('Bàn 1', 2, 'occupied', 4),
  ('Bàn 2', 2, 'occupied', 4),
  ('Bàn 3', 2, 'available', 4),
  ('Bàn 4', 2, 'available', 4),
  ('Bàn 5', 2, 'available', 4),
  ('Bàn 6', 2, 'available', 4),
  ('Bàn 7', 2, 'available', 4),
  ('Bàn 8', 2, 'available', 4),
  ('Bàn 9', 2, 'available', 4),
  ('Mang về', 0, 'available', 1),
  ('Giao đi', 0, 'available', 1)
ON CONFLICT DO NOTHING;

-- Insert sample orders
INSERT INTO public.orders (table_id, status, total_amount) VALUES
  ((SELECT id FROM public.tables WHERE name = 'Bàn 1'), 'active', 44000),
  ((SELECT id FROM public.tables WHERE name = 'Bàn 2'), 'active', 239000)
ON CONFLICT DO NOTHING;

-- Insert sample order items
INSERT INTO public.order_items (order_id, item_name, price, quantity) VALUES
  ((SELECT id FROM public.orders WHERE table_id = (SELECT id FROM public.tables WHERE name = 'Bàn 1')), 'Cà phê đen', 15000, 2),
  ((SELECT id FROM public.orders WHERE table_id = (SELECT id FROM public.tables WHERE name = 'Bàn 1')), 'Bánh mì thịt', 25000, 1),
  ((SELECT id FROM public.orders WHERE table_id = (SELECT id FROM public.tables WHERE name = 'Bàn 2')), 'Phở bò', 45000, 1),
  ((SELECT id FROM public.orders WHERE table_id = (SELECT id FROM public.tables WHERE name = 'Bàn 2')), 'Nước ngọt', 15000, 2)
ON CONFLICT DO NOTHING;

-- ===================================
-- TRIGGERS FOR AUTO-UPDATE
-- ===================================

-- Auto-update updated_at timestamp for tables
CREATE OR REPLACE FUNCTION update_tables_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tables_updated_at
BEFORE UPDATE ON public.tables
FOR EACH ROW
EXECUTE FUNCTION update_tables_updated_at();

-- Auto-update updated_at timestamp for orders
CREATE OR REPLACE FUNCTION update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION update_orders_updated_at();

-- ===================================
-- GRANT PERMISSIONS
-- ===================================
GRANT ALL ON public.tables TO authenticated;
GRANT ALL ON public.orders TO authenticated;
GRANT ALL ON public.order_items TO authenticated;

-- ===================================
-- COMMENTS FOR DOCUMENTATION
-- ===================================
COMMENT ON TABLE public.tables IS 'Restaurant tables management system';
COMMENT ON TABLE public.orders IS 'Customer orders for each table';
COMMENT ON TABLE public.order_items IS 'Individual items within each order';
COMMENT ON COLUMN public.tables.status IS 'Table status: available, occupied, reserved';
COMMENT ON COLUMN public.orders.status IS 'Order status: active, completed, cancelled';
