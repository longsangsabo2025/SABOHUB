-- ============================================
-- Migration 012: Inventory Management System
-- ============================================

-- ==========================================
-- 1. PRODUCTS (Sản phẩm)
-- ==========================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  category VARCHAR(100),
  sku VARCHAR(50) UNIQUE,
  unit VARCHAR(20), -- kg, lít, chai, lon, gói
  price DECIMAL(10,2),
  cost DECIMAL(10,2),
  stock_quantity INT DEFAULT 0,
  min_stock_level INT DEFAULT 10,
  max_stock_level INT DEFAULT 1000,
  reorder_point INT DEFAULT 20,
  is_active BOOLEAN DEFAULT TRUE,
  image_url TEXT,
  description TEXT,
  barcode VARCHAR(100),
  supplier_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_low_stock ON products(stock_quantity) WHERE stock_quantity <= min_stock_level;

-- ==========================================
-- 2. SUPPLIERS (Nhà cung cấp)
-- ==========================================
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  contact_person VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(255),
  address TEXT,
  tax_code VARCHAR(50),
  payment_terms VARCHAR(100),
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_suppliers_active ON suppliers(is_active);
CREATE INDEX idx_suppliers_name ON suppliers(name);

-- Add foreign key to products
ALTER TABLE products ADD CONSTRAINT fk_products_supplier 
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;

-- ==========================================
-- 3. STOCK MOVEMENTS (Xuất nhập kho)
-- ==========================================
CREATE TABLE IF NOT EXISTS stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('in', 'out', 'adjustment', 'waste', 'return')),
  quantity INT NOT NULL,
  unit_cost DECIMAL(10,2),
  total_cost DECIMAL(10,2),
  reason TEXT,
  reference_number VARCHAR(100),
  purchase_order_id UUID,
  created_by UUID REFERENCES users(id),
  created_by_name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_type ON stock_movements(type);
CREATE INDEX idx_stock_movements_created_at ON stock_movements(created_at DESC);
CREATE INDEX idx_stock_movements_created_by ON stock_movements(created_by);

-- ==========================================
-- 4. PURCHASE ORDERS (Đơn đặt hàng)
-- ==========================================
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(50) UNIQUE,
  supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'received', 'cancelled')),
  total_amount DECIMAL(12,2) DEFAULT 0,
  expected_delivery DATE,
  actual_delivery DATE,
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_by_name VARCHAR(255),
  approved_by UUID REFERENCES users(id),
  approved_by_name VARCHAR(255),
  approved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_purchase_orders_supplier ON purchase_orders(supplier_id);
CREATE INDEX idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX idx_purchase_orders_created_at ON purchase_orders(created_at DESC);

-- Add foreign key to stock_movements
ALTER TABLE stock_movements ADD CONSTRAINT fk_stock_movements_po
  FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE SET NULL;

-- ==========================================
-- 5. PURCHASE ORDER ITEMS
-- ==========================================
CREATE TABLE IF NOT EXISTS purchase_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id UUID REFERENCES purchase_orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity INT NOT NULL,
  unit_cost DECIMAL(10,2) NOT NULL,
  total_cost DECIMAL(10,2) NOT NULL,
  received_quantity INT DEFAULT 0,
  notes TEXT
);

CREATE INDEX idx_po_items_po ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_po_items_product ON purchase_order_items(product_id);

-- ==========================================
-- SAMPLE DATA
-- ==========================================

-- Insert sample suppliers
INSERT INTO suppliers (name, contact_person, phone, email, is_active) VALUES
  ('Công ty TNHH Thực phẩm Sạch', 'Nguyễn Văn A', '0901234567', 'contact@thucphamsach.vn', TRUE),
  ('Nhà cung cấp Đồ uống', 'Trần Thị B', '0912345678', 'sales@douong.com', TRUE),
  ('Kho tổng Hà Nội', 'Lê Văn C', '0923456789', 'info@khohn.vn', TRUE)
ON CONFLICT DO NOTHING;

-- Insert sample products
INSERT INTO products (name, category, sku, unit, price, cost, stock_quantity, min_stock_level, supplier_id) VALUES
  ('Cà phê rang xay', 'Đồ uống', 'CF001', 'kg', 150000, 100000, 50, 10, (SELECT id FROM suppliers LIMIT 1)),
  ('Sữa tươi', 'Nguyên liệu', 'MILK001', 'lít', 35000, 25000, 30, 20, (SELECT id FROM suppliers LIMIT 1)),
  ('Đường trắng', 'Nguyên liệu', 'SUGAR001', 'kg', 20000, 15000, 100, 30, (SELECT id FROM suppliers LIMIT 1)),
  ('Ly nhựa', 'Vật dụng', 'CUP001', 'cái', 1000, 500, 500, 100, (SELECT id FROM suppliers LIMIT 1)),
  ('Ống hút', 'Vật dụng', 'STRAW001', 'cái', 200, 100, 1000, 200, (SELECT id FROM suppliers LIMIT 1))
ON CONFLICT (sku) DO NOTHING;

-- ==========================================
-- TRIGGERS
-- ==========================================

-- Auto-update stock quantity on stock movement
CREATE OR REPLACE FUNCTION update_product_stock()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'in' THEN
    UPDATE products 
    SET stock_quantity = stock_quantity + NEW.quantity
    WHERE id = NEW.product_id;
  ELSIF NEW.type IN ('out', 'waste') THEN
    UPDATE products 
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE id = NEW.product_id;
  ELSIF NEW.type = 'adjustment' THEN
    UPDATE products 
    SET stock_quantity = NEW.quantity
    WHERE id = NEW.product_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER stock_movement_trigger
AFTER INSERT ON stock_movements
FOR EACH ROW
EXECUTE FUNCTION update_product_stock();

-- ==========================================
-- RLS POLICIES
-- ==========================================

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;

-- All staff can view products
CREATE POLICY "Staff can view products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

-- Managers can manage products
CREATE POLICY "Managers can manage products"
  ON products FOR ALL
  USING (is_manager_or_above())
  WITH CHECK (is_manager_or_above());

-- Similar policies for other tables...
CREATE POLICY "Staff can view suppliers" ON suppliers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Managers can manage suppliers" ON suppliers FOR ALL USING (is_manager_or_above());

CREATE POLICY "Staff can view stock movements" ON stock_movements FOR SELECT TO authenticated USING (true);
CREATE POLICY "Staff can create stock movements" ON stock_movements FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Staff can view purchase orders" ON purchase_orders FOR SELECT TO authenticated USING (true);
CREATE POLICY "Managers can manage purchase orders" ON purchase_orders FOR ALL USING (is_manager_or_above());

CREATE POLICY "Staff can view PO items" ON purchase_order_items FOR SELECT TO authenticated USING (true);

