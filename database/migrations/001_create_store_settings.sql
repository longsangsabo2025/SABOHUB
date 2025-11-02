-- =====================================================
-- STORE SETTINGS TABLE - Central Configuration System
-- =====================================================
-- Run this in Supabase SQL Editor

-- Create store_settings table
CREATE TABLE IF NOT EXISTS public.store_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  
  -- ============ PRICING SETTINGS ============
  default_hourly_rate DECIMAL(10, 2) DEFAULT 50000,
  vip_hourly_rate DECIMAL(10, 2) DEFAULT 60000,
  snooker_hourly_rate DECIMAL(10, 2) DEFAULT 80000,
  carom_hourly_rate DECIMAL(10, 2) DEFAULT 60000,
  
  -- ============ TIME ROUNDING ============
  rounding_minutes INTEGER DEFAULT 15 CHECK (rounding_minutes IN (10, 15, 30, 60)),
  minimum_play_minutes INTEGER DEFAULT 30,
  grace_period_minutes INTEGER DEFAULT 5,
  
  -- ============ PAYMENT METHODS ============
  accept_cash BOOLEAN DEFAULT true,
  accept_card BOOLEAN DEFAULT true,
  accept_momo BOOLEAN DEFAULT true,
  accept_banking BOOLEAN DEFAULT true,
  accept_vnpay BOOLEAN DEFAULT false,
  accept_zalopay BOOLEAN DEFAULT false,
  
  -- ============ TAX & FEES ============
  vat_rate DECIMAL(5, 2) DEFAULT 0,
  service_charge_rate DECIMAL(5, 2) DEFAULT 0,
  apply_vat_to_table BOOLEAN DEFAULT false,
  apply_vat_to_products BOOLEAN DEFAULT false,
  
  -- ============ DISCOUNT RULES ============
  happy_hour_enabled BOOLEAN DEFAULT false,
  happy_hour_start TIME DEFAULT '14:00:00',
  happy_hour_end TIME DEFAULT '17:00:00',
  happy_hour_discount DECIMAL(5, 2) DEFAULT 20,
  
  member_discount_enabled BOOLEAN DEFAULT true,
  member_discount_rate DECIMAL(5, 2) DEFAULT 10,
  
  birthday_discount_enabled BOOLEAN DEFAULT true,
  birthday_discount_rate DECIMAL(5, 2) DEFAULT 15,
  
  group_discount_enabled BOOLEAN DEFAULT false,
  group_discount_threshold INTEGER DEFAULT 5,
  group_discount_rate DECIMAL(5, 2) DEFAULT 10,
  
  -- ============ BUSINESS HOURS ============
  opening_time TIME DEFAULT '08:00:00',
  closing_time TIME DEFAULT '02:00:00',
  is_24_hours BOOLEAN DEFAULT false,
  
  monday_open BOOLEAN DEFAULT true,
  tuesday_open BOOLEAN DEFAULT true,
  wednesday_open BOOLEAN DEFAULT true,
  thursday_open BOOLEAN DEFAULT true,
  friday_open BOOLEAN DEFAULT true,
  saturday_open BOOLEAN DEFAULT true,
  sunday_open BOOLEAN DEFAULT true,
  
  -- ============ SESSION RULES ============
  auto_pause_after_minutes INTEGER DEFAULT 30,
  max_session_hours INTEGER DEFAULT 12,
  allow_overnight_sessions BOOLEAN DEFAULT true,
  
  -- ============ INVENTORY ALERTS ============
  low_stock_threshold INTEGER DEFAULT 10,
  critical_stock_threshold INTEGER DEFAULT 5,
  send_stock_alerts BOOLEAN DEFAULT true,
  
  -- ============ NOTIFICATIONS ============
  send_daily_report BOOLEAN DEFAULT true,
  daily_report_time TIME DEFAULT '23:00:00',
  send_weekly_report BOOLEAN DEFAULT true,
  weekly_report_day INTEGER DEFAULT 1, -- Monday
  
  -- ============ UI PREFERENCES ============
  currency_symbol TEXT DEFAULT 'VND',
  currency_code TEXT DEFAULT 'VND',
  date_format TEXT DEFAULT 'DD/MM/YYYY',
  time_format TEXT DEFAULT '24h',
  language TEXT DEFAULT 'vi',
  timezone TEXT DEFAULT 'Asia/Ho_Chi_Minh',
  
  -- ============ ADVANCED FEATURES ============
  enable_qr_ordering BOOLEAN DEFAULT false,
  enable_table_transfer BOOLEAN DEFAULT true,
  enable_split_bill BOOLEAN DEFAULT true,
  enable_tips BOOLEAN DEFAULT false,
  default_tip_percentage DECIMAL(5, 2) DEFAULT 10,
  
  -- ============ METADATA ============
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id),
  
  UNIQUE(store_id)
);

-- Add comment to table
COMMENT ON TABLE public.store_settings IS 'Centralized configuration for each store';

-- Enable RLS
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their store settings" ON public.store_settings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND (store_id = store_settings.store_id OR role = 'CEO')
    )
  );

CREATE POLICY "Managers can update store settings" ON public.store_settings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() 
        AND store_id = store_settings.store_id 
        AND role IN ('CEO', 'MANAGER')
    )
  );

CREATE POLICY "Admins can insert store settings" ON public.store_settings
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role IN ('CEO', 'MANAGER')
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_store_settings_store_id ON public.store_settings(store_id);
CREATE INDEX IF NOT EXISTS idx_store_settings_updated_at ON public.store_settings(updated_at);

-- Trigger for updated_at
CREATE TRIGGER update_store_settings_updated_at 
  BEFORE UPDATE ON public.store_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SEED DEFAULT SETTINGS FOR EXISTING STORES
-- =====================================================

-- Insert default settings for all existing stores
INSERT INTO public.store_settings (
  store_id,
  default_hourly_rate,
  vip_hourly_rate,
  snooker_hourly_rate,
  carom_hourly_rate,
  rounding_minutes,
  minimum_play_minutes,
  accept_cash,
  accept_card,
  accept_momo,
  accept_banking,
  happy_hour_enabled,
  happy_hour_start,
  happy_hour_end,
  happy_hour_discount,
  member_discount_enabled,
  member_discount_rate,
  opening_time,
  closing_time,
  is_24_hours,
  currency_symbol,
  language
)
SELECT 
  id as store_id,
  50000 as default_hourly_rate,
  60000 as vip_hourly_rate,
  80000 as snooker_hourly_rate,
  60000 as carom_hourly_rate,
  15 as rounding_minutes,
  30 as minimum_play_minutes,
  true as accept_cash,
  true as accept_card,
  true as accept_momo,
  true as accept_banking,
  true as happy_hour_enabled,
  '14:00:00'::TIME as happy_hour_start,
  '17:00:00'::TIME as happy_hour_end,
  20 as happy_hour_discount,
  true as member_discount_enabled,
  10 as member_discount_rate,
  '08:00:00'::TIME as opening_time,
  '02:00:00'::TIME as closing_time,
  false as is_24_hours,
  'VND' as currency_symbol,
  'vi' as language
FROM public.stores
ON CONFLICT (store_id) DO NOTHING;

-- Verify insertion
SELECT 
  s.name as store_name,
  ss.default_hourly_rate,
  ss.rounding_minutes,
  ss.happy_hour_enabled,
  ss.opening_time,
  ss.closing_time
FROM public.store_settings ss
JOIN public.stores s ON s.id = ss.store_id
ORDER BY s.name;
