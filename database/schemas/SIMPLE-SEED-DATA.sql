-- ============================================================================
-- SIMPLE SPRINT 2 SEED DATA
-- Copy and paste this into Supabase SQL Editor
-- ============================================================================

-- Get existing IDs
DO $$
DECLARE
  v_store_id UUID;
  v_user_id UUID;
BEGIN
  -- Get first store
  SELECT id INTO v_store_id FROM public.stores LIMIT 1;
  
  -- Get any user
  SELECT id INTO v_user_id FROM public.users LIMIT 1;
  
  IF v_store_id IS NULL THEN
    RAISE EXCEPTION 'No stores found! Please create a store first.';
  END IF;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No users found! Please create a user first.';
  END IF;
  
  RAISE NOTICE 'Using store_id: %', v_store_id;
  RAISE NOTICE 'Using user_id: %', v_user_id;
  
  -- ============================================================================
  -- 1. KPI DEFINITIONS (5 examples)
  -- ============================================================================
  INSERT INTO public.kpi_definitions 
    (store_id, name, description, category, metric_type, target_value, target_period, unit, created_by)
  VALUES
    (v_store_id, 'Monthly Revenue', 'Total monthly revenue', 'REVENUE', 'CURRENCY', 50000000, 'MONTHLY', 'VND', v_user_id),
    (v_store_id, 'Table Occupancy', 'Table occupancy rate', 'TABLE_UTILIZATION', 'PERCENTAGE', 70, 'DAILY', '%', v_user_id),
    (v_store_id, 'Customer Satisfaction', 'Customer rating', 'CUSTOMER_SATISFACTION', 'NUMBER', 4.5, 'MONTHLY', 'stars', v_user_id),
    (v_store_id, 'Daily Revenue', 'Daily revenue target', 'REVENUE', 'CURRENCY', 2000000, 'DAILY', 'VND', v_user_id),
    (v_store_id, 'Session Duration', 'Avg session time', 'TABLE_UTILIZATION', 'NUMBER', 90, 'DAILY', 'minutes', v_user_id)
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'KPI definitions inserted';
  
  -- ============================================================================
  -- 2. MARKETING CAMPAIGNS (3 examples)
  -- ============================================================================
  INSERT INTO public.marketing_campaigns 
    (store_id, name, description, campaign_type, status, start_date, end_date, budget, actual_spent, channels, created_by)
  VALUES
    (v_store_id, 'Weekend Happy Hour', 'Special weekend discounts', 'PROMOTION', 'ACTIVE', '2025-10-11', '2025-12-31', 5000000, 1200000, ARRAY['facebook', 'instagram'], v_user_id),
    (v_store_id, 'Christmas Season 2025', 'Holiday events and promotions', 'EVENT', 'SCHEDULED', '2025-12-20', '2025-12-31', 15000000, 0, ARRAY['facebook', 'instagram', 'zalo'], v_user_id),
    (v_store_id, 'Grand Opening Anniversary', '1 year celebration', 'EVENT', 'COMPLETED', '2025-09-01', '2025-09-30', 10000000, 9500000, ARRAY['facebook', 'email'], v_user_id)
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'Marketing campaigns inserted';
  
  -- ============================================================================
  -- 3. SCHEDULED POSTS (3 examples)
  -- ============================================================================
  INSERT INTO public.scheduled_posts 
    (store_id, platform, content, scheduled_time, status, post_type, created_by)
  VALUES
    (v_store_id, 'FACEBOOK', '🎱 Happy Hour! 20% off all tables this weekend!', NOW() + INTERVAL '2 hours', 'SCHEDULED', 'PROMOTIONAL', v_user_id),
    (v_store_id, 'INSTAGRAM', '✨ Weekend vibes at the tables! Come join us!', NOW() + INTERVAL '1 day', 'APPROVED', 'GENERAL', v_user_id),
    (v_store_id, 'FACEBOOK', 'Thank you for an amazing weekend! 🎉', NOW() - INTERVAL '3 days', 'PUBLISHED', 'ENGAGEMENT', v_user_id)
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'Scheduled posts inserted';
  
  -- ============================================================================
  -- VERIFICATION
  -- ============================================================================
  RAISE NOTICE '✅ Seed data inserted successfully!';
  RAISE NOTICE 'KPI Definitions: % rows', (SELECT COUNT(*) FROM public.kpi_definitions WHERE store_id = v_store_id);
  RAISE NOTICE 'Marketing Campaigns: % rows', (SELECT COUNT(*) FROM public.marketing_campaigns WHERE store_id = v_store_id);
  RAISE NOTICE 'Scheduled Posts: % rows', (SELECT COUNT(*) FROM public.scheduled_posts WHERE store_id = v_store_id);
  
END $$;

-- Final verification query
SELECT 
  'kpi_definitions' as table_name, 
  COUNT(*) as row_count 
FROM public.kpi_definitions
UNION ALL
SELECT 
  'marketing_campaigns' as table_name, 
  COUNT(*) as row_count 
FROM public.marketing_campaigns
UNION ALL
SELECT 
  'scheduled_posts' as table_name, 
  COUNT(*) as row_count 
FROM public.scheduled_posts;
