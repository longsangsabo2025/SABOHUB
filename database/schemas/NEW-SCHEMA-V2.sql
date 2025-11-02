-- ============================================
-- SABOHUB DATABASE SCHEMA v2.0
-- Complete Redesign for Consistency & Scalability
-- Author: Senior Database Architect
-- Date: 2025-11-02
-- ============================================

-- ==========================================
-- DESIGN PRINCIPLES
-- ==========================================
-- 1. Consistent naming: snake_case for all tables/columns
-- 2. Standardized columns: id, created_at, updated_at, deleted_at (soft delete)
-- 3. Clear hierarchy: company → branch → staff/orders/etc
-- 4. No redundancy: store_id removed, only branch_id
-- 5. UUID for all IDs (better for distributed systems)
-- 6. Proper foreign keys with ON DELETE CASCADE/SET NULL
-- 7. Indexes on all foreign keys and frequently queried columns

-- ==========================================
-- 1. CORE ENTITIES (Top Level)
-- ==========================================

-- Companies (Multi-tenant root)
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  logo_url TEXT,
  settings JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_companies_slug ON companies(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_companies_active ON companies(is_active) WHERE deleted_at IS NULL;

-- Branches (Physical locations under companies)
CREATE TABLE IF NOT EXISTS branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  code TEXT UNIQUE, -- Branch code for reporting (e.g., "HCM-01", "HN-01")
  email TEXT,
  phone TEXT,
  address TEXT,
  lat DECIMAL(10, 8),
  lng DECIMAL(11, 8),
  settings JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(company_id, slug)
);

CREATE INDEX idx_branches_company ON branches(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_branches_code ON branches(code) WHERE deleted_at IS NULL;
CREATE INDEX idx_branches_active ON branches(is_active, company_id) WHERE deleted_at IS NULL;

-- ==========================================
-- 2. USER MANAGEMENT
-- ==========================================

-- Users (Linked to Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  
  -- Role & Hierarchy
  role TEXT NOT NULL DEFAULT 'STAFF' CHECK (role IN ('CEO', 'BRANCH_MANAGER', 'SHIFT_LEADER', 'STAFF', 'TECHNICAL')),
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  
  -- Employment Info
  employee_code TEXT UNIQUE, -- e.g., "EMP001", "STF123"
  hired_date DATE,
  terminated_date DATE,
  
  -- Settings & Preferences
  settings JSONB DEFAULT '{}'::jsonb,
  notification_preferences JSONB DEFAULT '{}'::jsonb,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_company ON users(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_branch ON users(branch_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_code ON users(employee_code) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_active ON users(is_active, company_id, branch_id) WHERE deleted_at IS NULL;

-- User Sessions (Track login/activity)
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  device_info JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  login_at TIMESTAMPTZ DEFAULT NOW(),
  logout_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_user_sessions_user ON user_sessions(user_id, is_active);
CREATE INDEX idx_user_sessions_branch ON user_sessions(branch_id) WHERE is_active = true;

-- ==========================================
-- 3. TASK MANAGEMENT
-- ==========================================

-- Tasks (Work assignments)
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Basic Info
  title TEXT NOT NULL,
  description TEXT,
  
  -- Categorization
  category TEXT NOT NULL CHECK (category IN ('OPERATIONS', 'MAINTENANCE', 'INVENTORY', 'CUSTOMER_SERVICE', 'OTHER')),
  priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('URGENT', 'HIGH', 'MEDIUM', 'LOW')),
  status TEXT NOT NULL DEFAULT 'TODO' CHECK (status IN ('TODO', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  
  -- Assignment
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  assigned_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Timing
  due_date TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Metadata
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  attachments JSONB DEFAULT '[]'::jsonb,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_tasks_company ON tasks(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_branch ON tasks(branch_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_status ON tasks(status, branch_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_priority ON tasks(priority, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE deleted_at IS NULL AND status IN ('TODO', 'IN_PROGRESS');

-- Task Comments
CREATE TABLE IF NOT EXISTS task_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  attachments JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_task_comments_task ON task_comments(task_id) WHERE deleted_at IS NULL;

-- ==========================================
-- 4. PRODUCT & INVENTORY
-- ==========================================

-- Product Categories
CREATE TABLE IF NOT EXISTS product_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES product_categories(id) ON DELETE SET NULL,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(company_id, slug)
);

CREATE INDEX idx_product_categories_company ON product_categories(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_product_categories_parent ON product_categories(parent_id) WHERE deleted_at IS NULL;

-- Products (Master data at company level)
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  category_id UUID REFERENCES product_categories(id) ON DELETE SET NULL,
  
  -- Basic Info
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  sku TEXT UNIQUE, -- Stock Keeping Unit
  barcode TEXT UNIQUE,
  
  -- Pricing (base price, can be overridden per branch)
  cost_price DECIMAL(15, 2),
  sell_price DECIMAL(15, 2) NOT NULL,
  
  -- Inventory
  unit TEXT NOT NULL DEFAULT 'piece', -- piece, kg, liter, etc
  min_stock INT DEFAULT 0,
  
  -- Media & Details
  images JSONB DEFAULT '[]'::jsonb,
  description TEXT,
  
  -- Metadata
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  attributes JSONB DEFAULT '{}'::jsonb, -- size, color, etc
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(company_id, slug)
);

CREATE INDEX idx_products_company ON products(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_category ON products(category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_sku ON products(sku) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_barcode ON products(barcode) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_active ON products(is_active, company_id) WHERE deleted_at IS NULL;

-- Branch Inventory (Stock levels per branch)
CREATE TABLE IF NOT EXISTS branch_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  
  -- Stock
  quantity DECIMAL(15, 2) DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity DECIMAL(15, 2) DEFAULT 0 CHECK (reserved_quantity >= 0),
  
  -- Pricing override (optional)
  branch_sell_price DECIMAL(15, 2),
  
  -- Metadata
  last_stocked_at TIMESTAMPTZ,
  last_sold_at TIMESTAMPTZ,
  
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(branch_id, product_id)
);

CREATE INDEX idx_branch_inventory_branch ON branch_inventory(branch_id);
CREATE INDEX idx_branch_inventory_product ON branch_inventory(product_id);
CREATE INDEX idx_branch_inventory_low_stock ON branch_inventory(branch_id, quantity) WHERE quantity < 10;

-- Inventory Transactions (Stock movements)
CREATE TABLE IF NOT EXISTS inventory_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  
  -- Transaction Details
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('STOCK_IN', 'STOCK_OUT', 'TRANSFER', 'ADJUSTMENT', 'WASTE', 'RETURN')),
  quantity DECIMAL(15, 2) NOT NULL,
  unit_cost DECIMAL(15, 2),
  
  -- Reference
  reference_type TEXT, -- 'order', 'purchase', 'transfer', etc
  reference_id UUID,
  notes TEXT,
  
  -- Actor
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inventory_transactions_branch ON inventory_transactions(branch_id, created_at DESC);
CREATE INDEX idx_inventory_transactions_product ON inventory_transactions(product_id, created_at DESC);
CREATE INDEX idx_inventory_transactions_type ON inventory_transactions(transaction_type, branch_id);

-- ==========================================
-- 5. ORDERS & PAYMENTS
-- ==========================================

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  
  -- Order Info
  order_number TEXT UNIQUE NOT NULL, -- e.g., "ORD-20251102-001"
  
  -- Customer (optional)
  customer_name TEXT,
  customer_phone TEXT,
  customer_email TEXT,
  
  -- Amounts
  subtotal DECIMAL(15, 2) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(15, 2) DEFAULT 0,
  tax_amount DECIMAL(15, 2) DEFAULT 0,
  total_amount DECIMAL(15, 2) NOT NULL,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED')),
  payment_status TEXT NOT NULL DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID', 'PARTIAL', 'PAID', 'REFUNDED')),
  
  -- Staff
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  served_by UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Timing
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancel_reason TEXT,
  
  -- Metadata
  notes TEXT,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_orders_company ON orders(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_branch ON orders(branch_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_number ON orders(order_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_status ON orders(status, branch_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_date ON orders(created_at::DATE, branch_id) WHERE deleted_at IS NULL;

-- Order Items
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  
  -- Item Details
  product_name TEXT NOT NULL, -- Snapshot at order time
  quantity DECIMAL(15, 2) NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(15, 2) NOT NULL,
  discount_amount DECIMAL(15, 2) DEFAULT 0,
  total_amount DECIMAL(15, 2) NOT NULL,
  
  -- Metadata
  notes TEXT,
  attributes JSONB DEFAULT '{}'::jsonb, -- variants, customizations
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  
  -- Payment Details
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  payment_method TEXT NOT NULL CHECK (payment_method IN ('CASH', 'CARD', 'BANK_TRANSFER', 'E_WALLET', 'OTHER')),
  
  -- Transaction Info
  transaction_id TEXT, -- External payment gateway transaction ID
  reference_number TEXT,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
  
  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,
  notes TEXT,
  
  -- Actor
  processed_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  processed_at TIMESTAMPTZ DEFAULT NOW(),
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_branch ON payments(branch_id, processed_at DESC);
CREATE INDEX idx_payments_method ON payments(payment_method, branch_id);
CREATE INDEX idx_payments_status ON payments(status, branch_id);

-- ==========================================
-- SUMMARY OF CHANGES
-- ==========================================
/*
KEY IMPROVEMENTS:

1. NAMING CONSISTENCY:
   - All tables: snake_case plural
   - All columns: snake_case
   - Removed "store" terminology, unified to "branch"

2. STANDARD COLUMNS:
   - id: UUID (gen_random_uuid())
   - created_at, updated_at: TIMESTAMPTZ
   - deleted_at: Soft delete support
   - company_id, branch_id: Clear hierarchy

3. REMOVED REDUNDANCY:
   - No more store_id vs branch_id confusion
   - Single source of truth for locations

4. BETTER ORGANIZATION:
   - company (tenant) → branches (locations) → staff/orders
   - Clear foreign key relationships
   - Proper CASCADE rules

5. PERFORMANCE:
   - Indexes on all FKs
   - Composite indexes for common queries
   - Partial indexes with WHERE clauses

6. FLEXIBILITY:
   - JSONB for extensible data (settings, attributes)
   - TEXT[] for tags
   - Soft deletes with deleted_at

7. COMPLETENESS:
   - User sessions tracking
   - Task comments
   - Inventory transactions with full history
   - Order/payment lifecycle support
*/
