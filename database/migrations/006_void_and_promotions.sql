-- ============================================
-- Migration 006: Void Logs, Promotions, Customers
-- Created: ${new Date().toISOString()}
-- Purpose: Support void operations, promotions, and customer management
-- ============================================

-- ==========================================
-- 1. ORDER VOID LOGS
-- ==========================================
CREATE TABLE IF NOT EXISTS order_void_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  order_item_id UUID NULL, -- NULL means entire order was voided
  void_type VARCHAR(20) NOT NULL CHECK (void_type IN ('full_order', 'single_item')),
  reason VARCHAR(255) NOT NULL,
  notes TEXT,
  original_amount DECIMAL(10,2) NOT NULL,
  voided_by UUID NOT NULL, -- user_id who performed the void
  voided_by_name VARCHAR(255) NOT NULL,
  requires_approval BOOLEAN DEFAULT FALSE,
  approved_by UUID NULL,
  approved_by_name VARCHAR(255) NULL,
  approved_at TIMESTAMP WITH TIME ZONE NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_void_logs_order ON order_void_logs(order_id);
CREATE INDEX idx_void_logs_status ON order_void_logs(status);
CREATE INDEX idx_void_logs_created ON order_void_logs(created_at DESC);

-- ==========================================
-- 2. PROMOTIONS
-- ==========================================
CREATE TABLE IF NOT EXISTS promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(20) NOT NULL CHECK (type IN ('percentage', 'fixed_amount', 'buy_x_get_y')),
  value DECIMAL(10,2) NOT NULL,
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  max_discount_amount DECIMAL(10,2) NULL,
  conditions JSONB DEFAULT '{}',
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  usage_limit INT NULL,
  usage_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_promotions_code ON promotions(code);
CREATE INDEX idx_promotions_active ON promotions(is_active, start_date, end_date);

-- ==========================================
-- 3. ORDER PROMOTIONS (junction table)
-- ==========================================
CREATE TABLE IF NOT EXISTS order_promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  promotion_id UUID REFERENCES promotions(id) ON DELETE CASCADE,
  discount_amount DECIMAL(10,2) NOT NULL,
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  applied_by UUID NOT NULL,
  UNIQUE(order_id, promotion_id)
);

CREATE INDEX idx_order_promotions_order ON order_promotions(order_id);

-- ==========================================
-- 4. CUSTOMERS
-- ==========================================
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) UNIQUE,
  email VARCHAR(255) UNIQUE,
  address TEXT,
  date_of_birth DATE,
  gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
  loyalty_points INT DEFAULT 0,
  total_spent DECIMAL(12,2) DEFAULT 0,
  visit_count INT DEFAULT 0,
  last_visit_date TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_name ON customers(name);

-- ==========================================
-- 5. MENU CATEGORIES
-- ==========================================
CREATE TABLE IF NOT EXISTS menu_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  display_order INT DEFAULT 0,
  icon VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_menu_categories_order ON menu_categories(display_order);

-- ==========================================
-- 6. MENU ITEMS
-- ==========================================
CREATE TABLE IF NOT EXISTS menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES menu_categories(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  cost DECIMAL(10,2) DEFAULT 0,
  image_url TEXT,
  is_available BOOLEAN DEFAULT TRUE,
  preparation_time INT DEFAULT 0, -- in minutes
  calories INT,
  allergens TEXT[],
  tags TEXT[],
  display_order INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_menu_items_category ON menu_items(category_id);
CREATE INDEX idx_menu_items_available ON menu_items(is_available);
CREATE INDEX idx_menu_items_name ON menu_items(name);

-- ==========================================
-- 7. PRICE LISTS
-- ==========================================
CREATE TABLE IF NOT EXISTS price_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  type VARCHAR(20) CHECK (type IN ('default', 'vip', 'member', 'time_based', 'custom')),
  multiplier DECIMAL(5,2) DEFAULT 1.00,
  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  start_time TIME,
  end_time TIME,
  applicable_days INT[], -- 0=Sunday, 1=Monday, etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_price_lists_default ON price_lists(is_default);

-- ==========================================
-- 8. RECEIPTS
-- ==========================================
CREATE TABLE IF NOT EXISTS receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  receipt_number VARCHAR(50) UNIQUE NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('temporary', 'final', 'void')),
  content TEXT NOT NULL, -- Formatted receipt content
  format VARCHAR(10) CHECK (format IN ('text', 'html', 'pdf')),
  printed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  printed_by UUID NOT NULL,
  printed_by_name VARCHAR(255) NOT NULL,
  printer_name VARCHAR(100),
  print_count INT DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_receipts_order ON receipts(order_id);
CREATE INDEX idx_receipts_number ON receipts(receipt_number);
CREATE INDEX idx_receipts_type ON receipts(type);

-- ==========================================
-- ALTER EXISTING TABLES
-- ==========================================

-- Add customer reference to orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id) ON DELETE SET NULL;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS service_charge DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);

-- Add menu item reference to order_items
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS menu_item_id UUID REFERENCES menu_items(id) ON DELETE SET NULL;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS is_voided BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_order_items_menu ON order_items(menu_item_id);

-- ==========================================
-- SAMPLE DATA
-- ==========================================

-- Insert default price list
INSERT INTO price_lists (name, description, type, multiplier, is_default, is_active)
VALUES ('Bảng giá chung', 'Bảng giá mặc định cho tất cả khách hàng', 'default', 1.00, TRUE, TRUE)
ON CONFLICT DO NOTHING;

-- Insert menu categories
INSERT INTO menu_categories (id, name, description, display_order, icon, is_active) VALUES
  (gen_random_uuid(), 'Đồ uống', 'Các loại đồ uống nóng và lạnh', 1, '☕', TRUE),
  (gen_random_uuid(), 'Món ăn', 'Các món ăn chính', 2, '🍜', TRUE),
  (gen_random_uuid(), 'Tráng miệng', 'Món tráng miệng và chè', 3, '🍰', TRUE),
  (gen_random_uuid(), 'Khai vị', 'Món khai vị', 4, '🥗', TRUE),
  (gen_random_uuid(), 'Đặc biệt', 'Món đặc biệt của nhà hàng', 5, '⭐', TRUE)
ON CONFLICT DO NOTHING;

-- Insert sample menu items
WITH category_ids AS (
  SELECT id, name FROM menu_categories
)
INSERT INTO menu_items (category_id, name, description, price, is_available, preparation_time, display_order)
SELECT 
  c.id,
  items.name,
  items.description,
  items.price,
  TRUE,
  items.prep_time,
  items.display_order
FROM (VALUES
  -- Đồ uống
  ('Đồ uống', 'Cà phê đen', 'Cà phê đen truyền thống', 22000, 5, 1),
  ('Đồ uống', 'Cà phê sữa', 'Cà phê sữa đá', 25000, 5, 2),
  ('Đồ uống', 'Trà đá', 'Trà đá mát lạnh', 15000, 2, 3),
  ('Đồ uống', 'Nước cam', 'Nước cam tươi ép', 30000, 7, 4),
  ('Đồ uống', 'Coca Cola', 'Coca Cola lạnh', 20000, 2, 5),
  ('Đồ uống', 'Trà sữa trân châu', 'Trà sữa trân châu đường đen', 35000, 10, 6),
  
  -- Món ăn
  ('Món ăn', 'Phở bò', 'Phở bò Hà Nội truyền thống', 45000, 15, 1),
  ('Món ăn', 'Bún bò Huế', 'Bún bò Huế cay đặc trưng', 50000, 15, 2),
  ('Món ăn', 'Cơm tấm', 'Cơm tấm sườn nướng', 35000, 12, 3),
  ('Món ăn', 'Bánh mì thịt', 'Bánh mì thịt nướng đặc biệt', 25000, 8, 4),
  ('Món ăn', 'Gỏi cuốn', 'Gỏi cuốn tôm thịt', 30000, 10, 5),
  ('Món ăn', 'Cơm chiên dương châu', 'Cơm chiên dương châu hải sản', 40000, 15, 6),
  
  -- Tráng miệng
  ('Tráng miệng', 'Chè đậu đỏ', 'Chè đậu đỏ ngọt mát', 20000, 5, 1),
  ('Tráng miệng', 'Kem dừa', 'Kem dừa tươi mát lạnh', 25000, 7, 2),
  ('Tráng miệng', 'Chè thái', 'Chè thái đầy đủ topping', 30000, 10, 3),
  
  -- Khai vị
  ('Khai vị', 'Salad trộn', 'Salad rau củ trộn', 35000, 10, 1),
  ('Khai vị', 'Nem rán', 'Nem rán giòn rụm', 30000, 12, 2),
  
  -- Đặc biệt
  ('Đặc biệt', 'Lẩu thập cẩm', 'Lẩu thập cẩm cho 2-3 người', 199000, 25, 1),
  ('Đặc biệt', 'Gà nướng mật ong', 'Gà nướng mật ong nguyên con', 250000, 30, 2)
) AS items(cat_name, name, description, price, prep_time, display_order)
JOIN category_ids c ON c.name = items.cat_name
ON CONFLICT DO NOTHING;

-- Insert sample promotions
INSERT INTO promotions (code, name, description, type, value, min_order_amount, start_date, end_date, is_active) VALUES
  ('DISCOUNT10', 'Giảm 10%', 'Giảm giá 10% cho đơn hàng từ 100k', 'percentage', 10.00, 100000, NOW(), NOW() + INTERVAL '30 days', TRUE),
  ('FLAT50K', 'Giảm 50k', 'Giảm 50k cho đơn hàng từ 200k', 'fixed_amount', 50000, 200000, NOW(), NOW() + INTERVAL '30 days', TRUE),
  ('NEWCUSTOMER', 'Khách hàng mới', 'Giảm 20% cho khách hàng mới', 'percentage', 20.00, 0, NOW(), NOW() + INTERVAL '90 days', TRUE)
ON CONFLICT DO NOTHING;

-- Insert sample customers
INSERT INTO customers (name, phone, email, loyalty_points, total_spent, visit_count) VALUES
  ('Nguyễn Văn A', '0901234567', 'nguyenvana@email.com', 500, 1500000, 15),
  ('Trần Thị B', '0912345678', 'tranthib@email.com', 300, 900000, 10),
  ('Lê Văn C', '0923456789', 'levanc@email.com', 150, 450000, 5),
  ('Phạm Thị D', '0934567890', 'phamthid@email.com', 800, 2400000, 25)
ON CONFLICT DO NOTHING;

-- ==========================================
-- FUNCTIONS & TRIGGERS
-- ==========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER update_order_void_logs_updated_at BEFORE UPDATE ON order_void_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_promotions_updated_at BEFORE UPDATE ON promotions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menu_categories_updated_at BEFORE UPDATE ON menu_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON menu_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_price_lists_updated_at BEFORE UPDATE ON price_lists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- COMMENTS
-- ==========================================

COMMENT ON TABLE order_void_logs IS 'Logs of voided orders and order items';
COMMENT ON TABLE promotions IS 'Promotional discounts and offers';
COMMENT ON TABLE order_promotions IS 'Promotions applied to orders';
COMMENT ON TABLE customers IS 'Customer information and loyalty data';
COMMENT ON TABLE menu_categories IS 'Menu item categories';
COMMENT ON TABLE menu_items IS 'Menu items available for ordering';
COMMENT ON TABLE price_lists IS 'Price lists for different customer types and times';
COMMENT ON TABLE receipts IS 'Printed receipt records';

-- ==========================================
-- END OF MIGRATION
-- ==========================================

