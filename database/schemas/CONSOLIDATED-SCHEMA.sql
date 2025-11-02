-- ========================================
-- SABOHUB - CONSOLIDATED DATABASE SCHEMA
-- ========================================
-- Generated: 2025-10-12T02:22:37.908Z
-- Run this ENTIRE file in Supabase SQL Editor
--
-- This file combines all schema files:
--   1. supabase-setup.sql
--   2. supabase-tasks-schema.sql
--   3. supabase-notifications-schema.sql
--   4. supabase-analytics-schema.sql
--   5. supabase-marketing-schema.sql
--   6. supabase-smart-alerts-schema.sql
--   7. supabase-purchase-requests-update.sql
-- ========================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ========================================

-- ========================================
-- FROM: supabase-setup.sql
-- ========================================

-- SABOHUB Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Stores table (multi-store support)
CREATE TABLE IF NOT EXISTS public.stores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'STAFF' CHECK (role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF', 'TECHNICAL')),
  phone TEXT,
  avatar_url TEXT,
  store_id UUID REFERENCES public.stores(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Tables (billiard tables)
CREATE TABLE IF NOT EXISTS public.tables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_number INTEGER NOT NULL,
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  table_type TEXT NOT NULL DEFAULT 'POOL' CHECK (table_type IN ('POOL', 'LO', 'CAROM', 'SNOOKER')),
  hourly_rate DECIMAL(10, 2) NOT NULL DEFAULT 50000,
  status TEXT NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'OCCUPIED', 'RESERVED', 'MAINTENANCE')),
  current_session_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id),
  UNIQUE(store_id, table_number)
);

-- Shifts table (shift schedules)
CREATE TABLE IF NOT EXISTS public.shifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  shift_type TEXT NOT NULL CHECK (shift_type IN ('MORNING', 'AFTERNOON', 'EVENING', 'NIGHT')),
  shift_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id)
);

-- Shift assignments (many-to-many relationship between shifts and users)
CREATE TABLE IF NOT EXISTS public.shift_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shift_id UUID NOT NULL REFERENCES public.shifts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id),
  UNIQUE(shift_id, user_id)
);

-- Table sessions (playing sessions)
CREATE TABLE IF NOT EXISTS public.table_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_id UUID NOT NULL REFERENCES public.tables(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  pause_time TIMESTAMPTZ,
  total_paused_minutes INTEGER DEFAULT 0,
  hourly_rate DECIMAL(10, 2) NOT NULL,
  table_amount DECIMAL(10, 2) DEFAULT 0,
  orders_amount DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED')),
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products table
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('DRINKS', 'FOOD', 'EQUIPMENT', 'SUPPLIES', 'SERVICE')),
  price DECIMAL(10, 2) NOT NULL,
  cost DECIMAL(10, 2),
  unit TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id)
);

-- Staff table
CREATE TABLE IF NOT EXISTS public.staff (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  shift TEXT DEFAULT 'MORNING' CHECK (shift IN ('MORNING', 'AFTERNOON', 'EVENING', 'NIGHT')),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'ON_LEAVE')),
  kpi_score DECIMAL(5, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id)
);

-- Orders table
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES public.table_sessions(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  item_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inventory table
CREATE TABLE IF NOT EXISTS public.inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  item_name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('DRINKS', 'FOOD', 'EQUIPMENT', 'SUPPLIES')),
  quantity INTEGER NOT NULL DEFAULT 0,
  unit TEXT NOT NULL,
  min_threshold INTEGER DEFAULT 10,
  unit_price DECIMAL(10, 2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id)
);

-- Purchase requests table
CREATE TABLE IF NOT EXISTS public.purchase_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  item_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  requested_by UUID NOT NULL REFERENCES public.users(id),
  approved_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tasks table
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  assigned_to UUID REFERENCES public.users(id),
  assigned_by UUID NOT NULL REFERENCES public.users(id),
  deadline TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Alerts table (Smart Alerts)
CREATE TABLE IF NOT EXISTS public.alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('REVENUE_LOW', 'INVENTORY_LOW', 'INCIDENT', 'MAINTENANCE', 'STAFF', 'SYSTEM')),
  severity TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  action_suggestion TEXT,
  is_read BOOLEAN DEFAULT false,
  related_entity_type TEXT,
  related_entity_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ,
  read_by UUID REFERENCES public.users(id)
);

-- Maintenance logs table
CREATE TABLE IF NOT EXISTS public.maintenance_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  table_id UUID REFERENCES public.tables(id) ON DELETE SET NULL,
  issue_type TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'RESOLVED')),
  reported_by UUID NOT NULL REFERENCES public.users(id),
  resolved_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- Attendance table
CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  check_in TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  check_out TIMESTAMPTZ,
  check_in_location TEXT,
  check_out_location TEXT,
  check_in_photo_url TEXT,
  total_hours DECIMAL(5, 2),
  is_late BOOLEAN DEFAULT false,
  is_early_leave BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- KPI evaluations table
CREATE TABLE IF NOT EXISTS public.kpi_evaluations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  evaluation_period TEXT NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  upsell_revenue DECIMAL(10, 2) DEFAULT 0,
  on_time_shifts INTEGER DEFAULT 0,
  total_shifts INTEGER DEFAULT 0,
  customer_rating DECIMAL(3, 2) DEFAULT 0,
  manual_rating DECIMAL(3, 2),
  manual_rating_by UUID REFERENCES public.users(id),
  manual_rating_notes TEXT,
  total_score DECIMAL(5, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, month, year)
);

-- Shift reports table
CREATE TABLE IF NOT EXISTS public.shift_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  shift_id UUID NOT NULL REFERENCES public.shifts(id) ON DELETE CASCADE,
  total_revenue DECIMAL(10, 2) DEFAULT 0,
  total_tables_served INTEGER DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  incidents_count INTEGER DEFAULT 0,
  notes TEXT,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(shift_id)
);

-- Activity logs table (audit trail)
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.table_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kpi_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Stores: CEO can manage their stores
CREATE POLICY "CEO can manage own stores" ON public.stores
  FOR ALL USING (
    owner_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'CEO')
  );

-- Users can read their own data
CREATE POLICY "Users can read own data" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- CEO and MANAGER can read all users in their store
CREATE POLICY "CEO and MANAGER can read store users" ON public.users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() 
      AND u.role IN ('CEO', 'MANAGER')
      AND (u.store_id = users.store_id OR u.role = 'CEO')
    )
  );

-- CEO and MANAGER can update users in their store
CREATE POLICY "CEO and MANAGER can update store users" ON public.users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() 
      AND u.role IN ('CEO', 'MANAGER')
      AND (u.store_id = users.store_id OR u.role = 'CEO')
    )
  );

-- All authenticated users can read tables in their store
CREATE POLICY "Users can read store tables" ON public.tables
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = tables.store_id OR role = 'CEO')
    )
  );

-- Staff can update tables in their store
CREATE POLICY "Staff can update store tables" ON public.tables
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND store_id = tables.store_id
    )
  );

-- All authenticated users can manage sessions in their store
CREATE POLICY "Users can manage store sessions" ON public.table_sessions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.tables t ON t.id = table_sessions.table_id
      WHERE u.id = auth.uid() AND (u.store_id = t.store_id OR u.role = 'CEO')
    )
  );

-- Activity logs: Users can read their own logs, CEO/MANAGER can read all
CREATE POLICY "Users can read activity logs" ON public.activity_logs
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role IN ('CEO', 'MANAGER')
    )
  );

-- Invoices: Users can manage invoices in their store
CREATE POLICY "Users can manage store invoices" ON public.invoices
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = invoices.store_id OR role = 'CEO')
    )
  );

-- Payments: Users can manage payments in their store
CREATE POLICY "Users can manage store payments" ON public.payments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.invoices i ON i.id = payments.invoice_id
      WHERE u.id = auth.uid() AND (u.store_id = i.store_id OR u.role = 'CEO')
    )
  );

-- Products: Users can read products in their store
CREATE POLICY "Users can read store products" ON public.products
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = products.store_id OR role = 'CEO')
    )
  );

-- Orders: Users can manage orders in their store
CREATE POLICY "Users can manage store orders" ON public.orders
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.table_sessions ts ON ts.id = orders.session_id
      JOIN public.tables t ON t.id = ts.table_id
      WHERE u.id = auth.uid() AND (u.store_id = t.store_id OR u.role = 'CEO')
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_stores_owner_id ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS idx_stores_status ON public.stores(status);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_store_id ON public.users(store_id);
CREATE INDEX IF NOT EXISTS idx_shifts_store_id ON public.shifts(store_id);
CREATE INDEX IF NOT EXISTS idx_shifts_shift_date ON public.shifts(shift_date);
CREATE INDEX IF NOT EXISTS idx_shift_assignments_shift_id ON public.shift_assignments(shift_id);
CREATE INDEX IF NOT EXISTS idx_shift_assignments_user_id ON public.shift_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_kpi_evaluations_user_id ON public.kpi_evaluations(user_id);
CREATE INDEX IF NOT EXISTS idx_kpi_evaluations_period ON public.kpi_evaluations(month, year);
CREATE INDEX IF NOT EXISTS idx_shift_reports_shift_id ON public.shift_reports(shift_id);
CREATE INDEX IF NOT EXISTS idx_shift_reports_store_id ON public.shift_reports(store_id);
CREATE INDEX IF NOT EXISTS idx_products_store_id ON public.products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_tables_store_id ON public.tables(store_id);
CREATE INDEX IF NOT EXISTS idx_tables_status ON public.tables(status);
CREATE INDEX IF NOT EXISTS idx_table_sessions_table_id ON public.table_sessions(table_id);
CREATE INDEX IF NOT EXISTS idx_table_sessions_status ON public.table_sessions(status);
CREATE INDEX IF NOT EXISTS idx_staff_user_id ON public.staff(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_session_id ON public.orders(session_id);
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON public.orders(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_store_id ON public.inventory(store_id);
CREATE INDEX IF NOT EXISTS idx_inventory_category ON public.inventory(category);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_store_id ON public.purchase_requests(store_id);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_status ON public.purchase_requests(status);
CREATE INDEX IF NOT EXISTS idx_tasks_store_id ON public.tasks(store_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_alerts_store_id ON public.alerts(store_id);
CREATE INDEX IF NOT EXISTS idx_alerts_is_read ON public.alerts(is_read);
CREATE INDEX IF NOT EXISTS idx_alerts_type ON public.alerts(type);
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_store_id ON public.maintenance_logs(store_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_status ON public.maintenance_logs(status);
CREATE INDEX IF NOT EXISTS idx_attendance_store_id ON public.attendance(store_id);
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON public.attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_store_id ON public.activity_logs(store_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON public.activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON public.activity_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_invoices_store_id ON public.invoices(store_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON public.invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_payments_invoice_id ON public.payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);
CREATE INDEX IF NOT EXISTS idx_menu_categories_store_id ON public.menu_categories(store_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shifts_updated_at BEFORE UPDATE ON public.shifts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tables_updated_at BEFORE UPDATE ON public.tables
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_table_sessions_updated_at BEFORE UPDATE ON public.table_sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON public.staff
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON public.inventory
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchase_requests_updated_at BEFORE UPDATE ON public.purchase_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kpi_evaluations_updated_at BEFORE UPDATE ON public.kpi_evaluations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shift_reports_updated_at BEFORE UPDATE ON public.shift_reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menu_categories_updated_at BEFORE UPDATE ON public.menu_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Invoices table
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_number TEXT NOT NULL UNIQUE,
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  session_ids UUID[] NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0,
  discount_type TEXT CHECK (discount_type IN ('PERCENTAGE', 'FIXED')),
  discount_value DECIMAL(10, 2) DEFAULT 0,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'CANCELLED')),
  payment_method TEXT CHECK (payment_method IN ('CASH', 'VNPAY', 'MOMO', 'ZALOPAY')),
  payment_transaction_id TEXT,
  paid_at TIMESTAMPTZ,
  cancelled_reason TEXT,
  notes TEXT,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payments table (for tracking payment transactions)
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('CASH', 'VNPAY', 'MOMO', 'ZALOPAY')),
  amount DECIMAL(10, 2) NOT NULL,
  transaction_id TEXT,
  qr_code_url TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')),
  payment_data JSONB,
  customer_paid_amount DECIMAL(10, 2),
  change_amount DECIMAL(10, 2),
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Menu categories table (for organizing products)
CREATE TABLE IF NOT EXISTS public.menu_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, name)
);

-- Checklist templates table
CREATE TABLE IF NOT EXISTS public.checklist_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  shift_type TEXT CHECK (shift_type IN ('MORNING', 'AFTERNOON', 'EVENING', 'NIGHT', 'ALL')),
  is_active BOOLEAN DEFAULT true,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Checklist template items table
CREATE TABLE IF NOT EXISTS public.checklist_template_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID NOT NULL REFERENCES public.checklist_templates(id) ON DELETE CASCADE,
  task_name TEXT NOT NULL,
  description TEXT,
  requires_photo BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Checklist instances table (actual checklists being filled)
CREATE TABLE IF NOT EXISTS public.checklists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES public.checklist_templates(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  assigned_to UUID NOT NULL REFERENCES public.users(id),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'APPROVED', 'REJECTED')),
  completed_at TIMESTAMPTZ,
  approved_by UUID REFERENCES public.users(id),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Checklist item completions table
CREATE TABLE IF NOT EXISTS public.checklist_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  checklist_id UUID NOT NULL REFERENCES public.checklists(id) ON DELETE CASCADE,
  template_item_id UUID NOT NULL REFERENCES public.checklist_template_items(id) ON DELETE CASCADE,
  task_name TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  photo_url TEXT,
  notes TEXT,
  completed_by UUID REFERENCES public.users(id),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Incidents table (enhanced maintenance_logs)
CREATE TABLE IF NOT EXISTS public.incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('TABLE', 'EQUIPMENT', 'FACILITY', 'HVAC', 'PLUMBING', 'ELECTRICAL', 'OTHER')),
  priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  table_id UUID REFERENCES public.tables(id) ON DELETE SET NULL,
  reported_by UUID NOT NULL REFERENCES public.users(id),
  assigned_to UUID REFERENCES public.users(id),
  resolved_by UUID REFERENCES public.users(id),
  media_urls TEXT[],
  estimated_cost DECIMAL(10, 2),
  actual_cost DECIMAL(10, 2),
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- Maintenance schedules table (for periodic maintenance)
CREATE TABLE IF NOT EXISTS public.maintenance_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('TABLE', 'EQUIPMENT', 'FACILITY', 'HVAC', 'PLUMBING', 'ELECTRICAL', 'OTHER')),
  frequency TEXT NOT NULL CHECK (frequency IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
  next_due_date DATE NOT NULL,
  assigned_to UUID REFERENCES public.users(id),
  is_active BOOLEAN DEFAULT true,
  reminder_days_before INTEGER DEFAULT 3,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inventory items table (enhanced inventory with better tracking)
CREATE TABLE IF NOT EXISTS public.inventory_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('CUES', 'BALLS', 'CHALK', 'GLOVES', 'LIGHTS', 'CLOTH', 'CLEANING', 'OTHER')),
  unit TEXT NOT NULL,
  current_quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,
  min_threshold DECIMAL(10, 2) NOT NULL DEFAULT 10,
  unit_cost DECIMAL(10, 2),
  supplier_name TEXT,
  supplier_contact TEXT,
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inventory transactions table (track all inventory movements)
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  inventory_item_id UUID NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('IN', 'OUT', 'ADJUSTMENT')),
  quantity DECIMAL(10, 2) NOT NULL,
  unit_cost DECIMAL(10, 2),
  total_cost DECIMAL(10, 2),
  reason TEXT,
  reference_number TEXT,
  notes TEXT,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for new tables
ALTER TABLE public.checklist_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_template_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for new tables
CREATE POLICY "Users can manage store checklists" ON public.checklist_templates
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = checklist_templates.store_id OR role = 'CEO')
    )
  );

CREATE POLICY "Users can manage store checklist items" ON public.checklist_template_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.checklist_templates ct ON ct.id = checklist_template_items.template_id
      WHERE u.id = auth.uid() AND (u.store_id = ct.store_id OR u.role = 'CEO')
    )
  );

CREATE POLICY "Users can manage store checklist instances" ON public.checklists
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = checklists.store_id OR role = 'CEO')
    )
  );

CREATE POLICY "Users can manage checklist item completions" ON public.checklist_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.checklists c ON c.id = checklist_items.checklist_id
      WHERE u.id = auth.uid() AND (u.store_id = c.store_id OR u.role = 'CEO')
    )
  );

CREATE POLICY "Users can manage store incidents" ON public.incidents
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = incidents.store_id OR role = 'CEO')
    )
  );

CREATE POLICY "Users can manage maintenance schedules" ON public.maintenance_schedules
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = maintenance_schedules.store_id OR role = 'CEO')
    )
  );

CREATE POLICY "Users can manage store inventory items" ON public.inventory_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = inventory_items.store_id OR role = 'CEO')
    )
  );

CREATE POLICY "Users can manage inventory transactions" ON public.inventory_transactions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = inventory_transactions.store_id OR role = 'CEO')
    )
  );

-- Create indexes for new tables
CREATE INDEX IF NOT EXISTS idx_checklist_templates_store_id ON public.checklist_templates(store_id);
CREATE INDEX IF NOT EXISTS idx_checklist_template_items_template_id ON public.checklist_template_items(template_id);
CREATE INDEX IF NOT EXISTS idx_checklists_store_id ON public.checklists(store_id);
CREATE INDEX IF NOT EXISTS idx_checklists_status ON public.checklists(status);
CREATE INDEX IF NOT EXISTS idx_checklists_assigned_to ON public.checklists(assigned_to);
CREATE INDEX IF NOT EXISTS idx_checklist_items_checklist_id ON public.checklist_items(checklist_id);
CREATE INDEX IF NOT EXISTS idx_incidents_store_id ON public.incidents(store_id);
CREATE INDEX IF NOT EXISTS idx_incidents_status ON public.incidents(status);
CREATE INDEX IF NOT EXISTS idx_incidents_priority ON public.incidents(priority);
CREATE INDEX IF NOT EXISTS idx_incidents_assigned_to ON public.incidents(assigned_to);
CREATE INDEX IF NOT EXISTS idx_maintenance_schedules_store_id ON public.maintenance_schedules(store_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_schedules_next_due_date ON public.maintenance_schedules(next_due_date);
CREATE INDEX IF NOT EXISTS idx_inventory_items_store_id ON public.inventory_items(store_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_category ON public.inventory_items(category);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_store_id ON public.inventory_transactions(store_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item_id ON public.inventory_transactions(inventory_item_id);

-- Triggers for updated_at on new tables
CREATE TRIGGER update_checklist_templates_updated_at BEFORE UPDATE ON public.checklist_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_checklists_updated_at BEFORE UPDATE ON public.checklists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON public.incidents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_schedules_updated_at BEFORE UPDATE ON public.maintenance_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_items_updated_at BEFORE UPDATE ON public.inventory_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Beverage/Food inventory table (with expiry tracking)
CREATE TABLE IF NOT EXISTS public.beverage_inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('SOFT_DRINKS', 'BEER', 'WINE', 'SPIRITS', 'SNACKS', 'FOOD', 'OTHER')),
  unit TEXT NOT NULL,
  current_quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,
  min_threshold DECIMAL(10, 2) NOT NULL DEFAULT 10,
  unit_cost DECIMAL(10, 2),
  expiry_date DATE,
  batch_number TEXT,
  supplier_name TEXT,
  supplier_contact TEXT,
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Beverage/Food inventory transactions table
CREATE TABLE IF NOT EXISTS public.beverage_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  beverage_inventory_id UUID NOT NULL REFERENCES public.beverage_inventory(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('IN', 'OUT', 'ADJUSTMENT', 'EXPIRED', 'DAMAGED')),
  quantity DECIMAL(10, 2) NOT NULL,
  unit_cost DECIMAL(10, 2),
  total_cost DECIMAL(10, 2),
  reason TEXT,
  reference_number TEXT,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  notes TEXT,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Maintenance completions table (for tracking completed maintenance with photos)
CREATE TABLE IF NOT EXISTS public.maintenance_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  schedule_id UUID REFERENCES public.maintenance_schedules(id) ON DELETE SET NULL,
  incident_id UUID REFERENCES public.incidents(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('TABLE', 'EQUIPMENT', 'FACILITY', 'HVAC', 'PLUMBING', 'ELECTRICAL', 'OTHER')),
  completed_by UUID NOT NULL REFERENCES public.users(id),
  completion_date DATE NOT NULL,
  photo_urls TEXT[],
  notes TEXT,
  cost DECIMAL(10, 2),
  next_maintenance_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for new tables
ALTER TABLE public.beverage_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.beverage_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_completions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for beverage inventory
CREATE POLICY "Users can manage store beverage inventory" ON public.beverage_inventory
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = beverage_inventory.store_id OR role = 'CEO')
    )
  );

CREATE POLICY "Users can manage beverage transactions" ON public.beverage_transactions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = beverage_transactions.store_id OR role = 'CEO')
    )
  );

CREATE POLICY "Users can manage maintenance completions" ON public.maintenance_completions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = maintenance_completions.store_id OR role = 'CEO')
    )
  );

-- Create indexes for new tables
CREATE INDEX IF NOT EXISTS idx_beverage_inventory_store_id ON public.beverage_inventory(store_id);
CREATE INDEX IF NOT EXISTS idx_beverage_inventory_category ON public.beverage_inventory(category);
CREATE INDEX IF NOT EXISTS idx_beverage_inventory_expiry_date ON public.beverage_inventory(expiry_date);
CREATE INDEX IF NOT EXISTS idx_beverage_inventory_product_id ON public.beverage_inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_beverage_transactions_store_id ON public.beverage_transactions(store_id);
CREATE INDEX IF NOT EXISTS idx_beverage_transactions_beverage_id ON public.beverage_transactions(beverage_inventory_id);
CREATE INDEX IF NOT EXISTS idx_beverage_transactions_order_id ON public.beverage_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_completions_store_id ON public.maintenance_completions(store_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_completions_schedule_id ON public.maintenance_completions(schedule_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_completions_completion_date ON public.maintenance_completions(completion_date);

-- Triggers for updated_at on new tables
CREATE TRIGGER update_beverage_inventory_updated_at BEFORE UPDATE ON public.beverage_inventory
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_completions_updated_at BEFORE UPDATE ON public.maintenance_completions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data (optional)
-- Note: You need to create a store first, then use its ID for other tables
-- Sample store (will be created when CEO signs up)
-- Sample tables, inventory, etc. should reference the store_id



-- ========================================
-- FROM: supabase-tasks-schema.sql
-- ========================================

-- Tasks Management Schema
-- Phase 9: Task Assignment System

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'cancelled')),
  deadline TIMESTAMPTZ,
  assigned_to UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

-- Task attachments
CREATE TABLE IF NOT EXISTS task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Task progress notes
CREATE TABLE IF NOT EXISTS task_progress_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  note TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Task reminders log
CREATE TABLE IF NOT EXISTS task_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('before_deadline', 'overdue', 'completed')),
  sent_to UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_store_id ON tasks(store_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_by ON tasks(assigned_by);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON tasks(deadline);
CREATE INDEX IF NOT EXISTS idx_task_attachments_task_id ON task_attachments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_progress_notes_task_id ON task_progress_notes(task_id);
CREATE INDEX IF NOT EXISTS idx_task_reminders_task_id ON task_reminders(task_id);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_tasks_updated_at();

-- RLS Policies
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_progress_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_reminders ENABLE ROW LEVEL SECURITY;

-- Tasks policies
CREATE POLICY "Users can view tasks in their store"
  ON tasks FOR SELECT
  USING (
    store_id IN (
      SELECT store_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Managers can create tasks"
  ON tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND store_id = tasks.store_id
      AND role IN ('ceo', 'general_manager', 'shift_leader')
    )
  );

CREATE POLICY "Assigned users and managers can update tasks"
  ON tasks FOR UPDATE
  USING (
    assigned_to = auth.uid()
    OR EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND store_id = tasks.store_id
      AND role IN ('ceo', 'general_manager', 'shift_leader')
    )
  );

CREATE POLICY "Managers can delete tasks"
  ON tasks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND store_id = tasks.store_id
      AND role IN ('ceo', 'general_manager')
    )
  );

-- Task attachments policies
CREATE POLICY "Users can view attachments of tasks they can see"
  ON task_attachments FOR SELECT
  USING (
    task_id IN (
      SELECT id FROM tasks
      WHERE store_id IN (
        SELECT store_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can add attachments to tasks"
  ON task_attachments FOR INSERT
  WITH CHECK (
    task_id IN (
      SELECT id FROM tasks
      WHERE store_id IN (
        SELECT store_id FROM users WHERE id = auth.uid()
      )
    )
  );

-- Task progress notes policies
CREATE POLICY "Users can view notes of tasks they can see"
  ON task_progress_notes FOR SELECT
  USING (
    task_id IN (
      SELECT id FROM tasks
      WHERE store_id IN (
        SELECT store_id FROM users WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can add notes to tasks"
  ON task_progress_notes FOR INSERT
  WITH CHECK (
    task_id IN (
      SELECT id FROM tasks
      WHERE store_id IN (
        SELECT store_id FROM users WHERE id = auth.uid()
      )
    )
  );

-- Task reminders policies
CREATE POLICY "Users can view their reminders"
  ON task_reminders FOR SELECT
  USING (sent_to = auth.uid());

CREATE POLICY "System can create reminders"
  ON task_reminders FOR INSERT
  WITH CHECK (true);



-- ========================================
-- FROM: supabase-notifications-schema.sql
-- ========================================

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



-- ========================================
-- FROM: supabase-analytics-schema.sql
-- ========================================

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



-- ========================================
-- FROM: supabase-marketing-schema.sql
-- ========================================

-- Marketing & Content Creator Schema

-- Media Library
CREATE TABLE IF NOT EXISTS media_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id),
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN ('image', 'video')),
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  folder TEXT DEFAULT 'general',
  width INTEGER,
  height INTEGER,
  duration INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_library_store ON media_library(store_id);
CREATE INDEX idx_media_library_folder ON media_library(store_id, folder);
CREATE INDEX idx_media_library_type ON media_library(store_id, file_type);

-- Post Templates
CREATE TABLE IF NOT EXISTS post_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  content TEXT NOT NULL,
  thumbnail_url TEXT,
  is_system BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_post_templates_store ON post_templates(store_id);
CREATE INDEX idx_post_templates_category ON post_templates(category);

-- Posts
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'published', 'scheduled')),
  channels TEXT[] DEFAULT '{}',
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  rejected_reason TEXT,
  template_id UUID REFERENCES post_templates(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_store ON posts(store_id);
CREATE INDEX idx_posts_status ON posts(store_id, status);
CREATE INDEX idx_posts_created_by ON posts(created_by);
CREATE INDEX idx_posts_scheduled ON posts(scheduled_at) WHERE status = 'scheduled';

-- Post Media (junction table)
CREATE TABLE IF NOT EXISTS post_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  media_id UUID NOT NULL REFERENCES media_library(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_post_media_post ON post_media(post_id);
CREATE INDEX idx_post_media_media ON post_media(media_id);

-- Published Posts Log
CREATE TABLE IF NOT EXISTS published_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  channel TEXT NOT NULL,
  external_id TEXT,
  external_url TEXT,
  status TEXT NOT NULL CHECK (status IN ('success', 'failed')),
  error_message TEXT,
  published_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_published_posts_post ON published_posts(post_id);
CREATE INDEX idx_published_posts_channel ON published_posts(channel);

-- Social Media Accounts
CREATE TABLE IF NOT EXISTS social_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('facebook', 'instagram', 'sabo_arena')),
  account_name TEXT NOT NULL,
  account_id TEXT,
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, platform)
);

CREATE INDEX idx_social_accounts_store ON social_accounts(store_id);
CREATE INDEX idx_social_accounts_platform ON social_accounts(platform);

-- Insert default templates
INSERT INTO post_templates (name, description, category, content, is_system) VALUES
('Happy Hour', 'Khuyến mãi giờ vàng', 'promotion', '🎉 HAPPY HOUR - GIẢM GIÁ ĐẶC BIỆT! 🎉

⏰ Thời gian: [Thời gian]
💰 Ưu đãi: [Mô tả ưu đãi]
📍 Địa điểm: [Tên quán]

Nhanh tay đặt bàn ngay! ☎️ [SĐT]', TRUE),

('Sinh nhật', 'Khuyến mãi sinh nhật', 'promotion', '🎂 CHƯƠNG TRÌNH ƯU ĐÃI SINH NHẬT! 🎂

🎁 Giảm [X]% cho khách có sinh nhật trong tháng
🎈 Tặng kèm [Quà tặng]
📅 Áp dụng: [Thời gian]

Mang theo CMND để nhận ưu đãi nhé! 🎉', TRUE),

('Giải đấu', 'Thông báo giải đấu', 'event', '🏆 GIẢI ĐẤU BI-A [TÊN GIẢI] 🏆

📅 Thời gian: [Ngày giờ]
💰 Giải thưởng: [Giá trị giải]
👥 Số lượng: [Số người]
💵 Lệ phí: [Phí tham gia]

Đăng ký ngay: [Link/SĐT] 🎱', TRUE),

('Khai trương', 'Thông báo khai trương', 'event', '🎊 KHAI TRƯƠNG CHI NHÁNH MỚI! 🎊

📍 Địa chỉ: [Địa chỉ]
📅 Ngày: [Ngày khai trương]
🎁 Ưu đãi: [Khuyến mãi khai trương]

Hân hạnh được phục vụ quý khách! 🙏', TRUE),

('Bảo trì', 'Thông báo bảo trì', 'announcement', '⚠️ THÔNG BÁO BẢO TRÌ ⚠️

🔧 Nội dung: [Mô tả bảo trì]
⏰ Thời gian: [Thời gian bảo trì]
📍 Khu vực: [Khu vực ảnh hưởng]

Xin lỗi quý khách vì sự bất tiện này! 🙏', TRUE),

('Tuyển dụng', 'Thông báo tuyển dụng', 'recruitment', '💼 TUYỂN DỤNG NHÂN VIÊN 💼

📋 Vị trí: [Vị trí tuyển dụng]
👥 Số lượng: [Số lượng]
💰 Lương: [Mức lương]
📍 Làm việc tại: [Địa điểm]

Yêu cầu:
- [Yêu cầu 1]
- [Yêu cầu 2]

Liên hệ: [SĐT/Email] 📞', TRUE),

('Combo đặc biệt', 'Giới thiệu combo', 'promotion', '🍻 COMBO ĐẶC BIỆT - SIÊU TIẾT KIỆM! 🍻

📦 Combo bao gồm:
- [Item 1]
- [Item 2]
- [Item 3]

💰 Giá chỉ: [Giá] (Tiết kiệm [X]%)
⏰ Áp dụng: [Thời gian]

Đặt ngay kẻo lỡ! 🎯', TRUE),

('Thông báo nghỉ lễ', 'Thông báo lịch nghỉ lễ', 'announcement', '📢 THÔNG BÁO LỊCH LÀM VIỆC LỄ 📢

🎊 Dịp: [Tên lễ]
📅 Thời gian: [Thời gian nghỉ/làm việc]

Quán [Đóng cửa/Mở cửa] vào [Thời gian]

Chúc quý khách một kỳ nghỉ vui vẻ! 🎉', TRUE),

('Khách hàng thân thiết', 'Chương trình khách hàng thân thiết', 'promotion', '⭐ CHƯƠNG TRÌNH KHÁCH HÀNG THÂN THIẾT ⭐

🎁 Ưu đãi:
- Tích điểm mỗi lần chơi
- Đổi quà hấp dẫn
- Giảm giá đặc biệt

📱 Đăng ký ngay: [Link/SĐT]

Tri ân khách hàng - Ưu đãi bất tận! 💝', TRUE),

('Giới thiệu bàn mới', 'Giới thiệu bàn bi-a mới', 'announcement', '✨ RA MẮT BÀN BI-A MỚI! ✨

🎱 Loại bàn: [Loại bàn]
🌟 Đặc điểm: [Mô tả đặc điểm]
💰 Giá: [Giá chơi]

Trải nghiệm ngay hôm nay! 🎯', TRUE);

-- Enable RLS
ALTER TABLE media_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE published_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for media_library
CREATE POLICY "Users can view media from their store"
  ON media_library FOR SELECT
  USING (store_id IN (SELECT store_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can upload media to their store"
  ON media_library FOR INSERT
  WITH CHECK (
    store_id IN (SELECT store_id FROM users WHERE id = auth.uid())
    AND uploaded_by = auth.uid()
  );

CREATE POLICY "Users can delete their own media"
  ON media_library FOR DELETE
  USING (uploaded_by = auth.uid());

-- RLS Policies for post_templates
CREATE POLICY "Users can view templates"
  ON post_templates FOR SELECT
  USING (is_system = TRUE OR store_id IN (SELECT store_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Managers can create templates"
  ON post_templates FOR INSERT
  WITH CHECK (
    store_id IN (
      SELECT u.store_id FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name IN ('CEO', 'Quản lý tổng', 'Trưởng ca')
    )
  );

-- RLS Policies for posts
CREATE POLICY "Users can view posts from their store"
  ON posts FOR SELECT
  USING (store_id IN (SELECT store_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can create posts"
  ON posts FOR INSERT
  WITH CHECK (
    store_id IN (SELECT store_id FROM users WHERE id = auth.uid())
    AND created_by = auth.uid()
  );

CREATE POLICY "Users can update their own posts"
  ON posts FOR UPDATE
  USING (created_by = auth.uid() OR store_id IN (
    SELECT u.store_id FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name IN ('CEO', 'Quản lý tổng')
  ));

-- RLS Policies for post_media
CREATE POLICY "Users can view post media"
  ON post_media FOR SELECT
  USING (post_id IN (SELECT id FROM posts WHERE store_id IN (SELECT store_id FROM users WHERE id = auth.uid())));

CREATE POLICY "Users can manage post media"
  ON post_media FOR ALL
  USING (post_id IN (SELECT id FROM posts WHERE created_by = auth.uid()));

-- RLS Policies for published_posts
CREATE POLICY "Users can view published posts from their store"
  ON published_posts FOR SELECT
  USING (post_id IN (SELECT id FROM posts WHERE store_id IN (SELECT store_id FROM users WHERE id = auth.uid())));

-- RLS Policies for social_accounts
CREATE POLICY "Users can view social accounts from their store"
  ON social_accounts FOR SELECT
  USING (store_id IN (SELECT store_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Managers can manage social accounts"
  ON social_accounts FOR ALL
  USING (store_id IN (
    SELECT u.store_id FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name IN ('CEO', 'Quản lý tổng')
  ));



-- ========================================
-- FROM: supabase-smart-alerts-schema.sql
-- ========================================

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



-- ========================================
-- FROM: supabase-purchase-requests-update.sql
-- ========================================

-- Update purchase_requests table to add new fields for Phase 6
ALTER TABLE public.purchase_requests 
ADD COLUMN IF NOT EXISTS estimated_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS actual_quantity INTEGER,
ADD COLUMN IF NOT EXISTS actual_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS total_cost DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS photo_urls TEXT[],
ADD COLUMN IF NOT EXISTS receipt_photo_urls TEXT[],
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS approval_notes TEXT,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS completed_by UUID REFERENCES public.users(id),
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS completion_notes TEXT;

-- Update status enum to include PURCHASING and COMPLETED
ALTER TABLE public.purchase_requests 
DROP CONSTRAINT IF EXISTS purchase_requests_status_check;

ALTER TABLE public.purchase_requests 
ADD CONSTRAINT purchase_requests_status_check 
CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'PURCHASING', 'COMPLETED'));

-- Create RLS policy for purchase requests
DROP POLICY IF EXISTS "Users can manage store purchase requests" ON public.purchase_requests;

CREATE POLICY "Users can manage store purchase requests" ON public.purchase_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = purchase_requests.store_id OR role = 'CEO')
    )
  );

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_purchase_requests_requested_by ON public.purchase_requests(requested_by);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_approved_by ON public.purchase_requests(approved_by);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_completed_by ON public.purchase_requests(completed_by);

-- Create functions for inventory management
CREATE OR REPLACE FUNCTION add_inventory_stock(
  p_item_id UUID,
  p_quantity DECIMAL,
  p_unit_cost DECIMAL,
  p_user_id UUID,
  p_reference TEXT
)
RETURNS void AS $$
DECLARE
  v_store_id UUID;
BEGIN
  SELECT store_id INTO v_store_id FROM public.inventory_items WHERE id = p_item_id;
  
  UPDATE public.inventory_items
  SET current_quantity = current_quantity + p_quantity,
      updated_at = NOW()
  WHERE id = p_item_id;
  
  INSERT INTO public.inventory_transactions (
    store_id,
    inventory_item_id,
    transaction_type,
    quantity,
    unit_cost,
    total_cost,
    reference_number,
    created_by
  ) VALUES (
    v_store_id,
    p_item_id,
    'IN',
    p_quantity,
    p_unit_cost,
    p_quantity * p_unit_cost,
    p_reference,
    p_user_id
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_beverage_stock(
  p_beverage_id UUID,
  p_quantity DECIMAL,
  p_unit_cost DECIMAL,
  p_user_id UUID,
  p_reference TEXT
)
RETURNS void AS $$
DECLARE
  v_store_id UUID;
BEGIN
  SELECT store_id INTO v_store_id FROM public.beverage_inventory WHERE id = p_beverage_id;
  
  UPDATE public.beverage_inventory
  SET current_quantity = current_quantity + p_quantity,
      updated_at = NOW()
  WHERE id = p_beverage_id;
  
  INSERT INTO public.beverage_transactions (
    store_id,
    beverage_inventory_id,
    transaction_type,
    quantity,
    unit_cost,
    total_cost,
    reference_number,
    created_by
  ) VALUES (
    v_store_id,
    p_beverage_id,
    'IN',
    p_quantity,
    p_unit_cost,
    p_quantity * p_unit_cost,
    p_reference,
    p_user_id
  );
END;
$$ LANGUAGE plpgsql;



-- ========================================
-- END OF CONSOLIDATED SCHEMA
-- ========================================
-- 
-- Verification:
-- Run this query to check all tables exist:
-- 
-- SELECT table_name 
-- FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- ORDER BY table_name;
--
-- Expected: 22+ tables
-- ========================================


-- ========================================
-- SPRINT 2 TABLES (October 2025)
-- ========================================

-- KPI_DEFINITIONS - Define KPI metrics with targets
CREATE TABLE IF NOT EXISTS public.kpi_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN (
    'REVENUE', 'CUSTOMER_SATISFACTION', 'OPERATIONAL_EFFICIENCY', 
    'STAFF_PERFORMANCE', 'TABLE_UTILIZATION', 'INVENTORY', 'MARKETING', 'OTHER'
  )),
  metric_type TEXT NOT NULL CHECK (metric_type IN ('NUMBER', 'PERCENTAGE', 'CURRENCY', 'RATIO')),
  target_value DECIMAL(15, 2) NOT NULL,
  target_period TEXT NOT NULL CHECK (target_period IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
  unit TEXT,
  warning_threshold DECIMAL(15, 2),
  critical_threshold DECIMAL(15, 2),
  formula TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, name, target_period)
);

CREATE INDEX idx_kpi_definitions_store_id ON public.kpi_definitions(store_id);
CREATE INDEX idx_kpi_definitions_category ON public.kpi_definitions(category);
CREATE INDEX idx_kpi_definitions_is_active ON public.kpi_definitions(is_active);

