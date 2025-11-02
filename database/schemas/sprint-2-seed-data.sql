-- ============================================================================
-- SPRINT 2 SEED DATA
-- ============================================================================
-- Sample data for testing Sprint 2 features
-- Run this AFTER sprint-2-tables-migration.sql
-- ============================================================================

-- Note: Replace UUIDs with actual IDs from your database
-- Get store_id: SELECT id FROM stores LIMIT 1;
-- Get user_id: SELECT id FROM users WHERE role = 'MANAGER' LIMIT 1;

-- ============================================================================
-- 1. KPI DEFINITIONS - Sample KPIs
-- ============================================================================

-- Assuming we have a store and user (replace with actual IDs)
DO $$
DECLARE
  v_store_id UUID;
  v_user_id UUID;
BEGIN
  -- Get first store
  SELECT id INTO v_store_id FROM public.stores LIMIT 1;
  
  -- Get first manager/CEO
  SELECT id INTO v_user_id FROM public.users WHERE role IN ('MANAGER', 'CEO') LIMIT 1;
  
  IF v_store_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    
    -- Revenue KPIs
    INSERT INTO public.kpi_definitions (store_id, name, description, category, metric_type, target_value, target_period, unit, warning_threshold, critical_threshold, formula, created_by)
    VALUES
      (v_store_id, 'Monthly Revenue', 'Total monthly revenue from all sources', 'REVENUE', 'CURRENCY', 50000000, 'MONTHLY', 'VND', 40000000, 30000000, 'SUM(table_sessions.total_amount + orders.total)', v_user_id),
      (v_store_id, 'Daily Revenue', 'Average daily revenue', 'REVENUE', 'CURRENCY', 2000000, 'DAILY', 'VND', 1500000, 1000000, 'SUM(revenue) / DAY', v_user_id),
      (v_store_id, 'Revenue per Table', 'Average revenue per table per day', 'REVENUE', 'CURRENCY', 500000, 'DAILY', 'VND', 400000, 300000, 'SUM(revenue) / COUNT(tables)', v_user_id);
    
    -- Table Utilization KPIs
    INSERT INTO public.kpi_definitions (store_id, name, description, category, metric_type, target_value, target_period, unit, warning_threshold, critical_threshold, formula, created_by)
    VALUES
      (v_store_id, 'Table Occupancy Rate', 'Percentage of time tables are occupied', 'TABLE_UTILIZATION', 'PERCENTAGE', 70, 'DAILY', '%', 60, 50, '(occupied_hours / total_available_hours) * 100', v_user_id),
      (v_store_id, 'Average Session Duration', 'Average playing time per session', 'TABLE_UTILIZATION', 'NUMBER', 90, 'DAILY', 'minutes', 75, 60, 'AVG(end_time - start_time)', v_user_id);
    
    -- Staff Performance KPIs
    INSERT INTO public.kpi_definitions (store_id, name, description, category, metric_type, target_value, target_period, unit, warning_threshold, critical_threshold, formula, created_by)
    VALUES
      (v_store_id, 'Staff Attendance Rate', 'Percentage of staff showing up on time', 'STAFF_PERFORMANCE', 'PERCENTAGE', 95, 'MONTHLY', '%', 90, 85, '(on_time_count / total_shifts) * 100', v_user_id),
      (v_store_id, 'Customer Satisfaction Score', 'Average customer rating', 'CUSTOMER_SATISFACTION', 'NUMBER', 4.5, 'MONTHLY', 'stars', 4.0, 3.5, 'AVG(customer_ratings)', v_user_id);
    
    -- Operational Efficiency KPIs
    INSERT INTO public.kpi_definitions (store_id, name, description, category, metric_type, target_value, target_period, unit, warning_threshold, critical_threshold, formula, created_by)
    VALUES
      (v_store_id, 'Order Fulfillment Time', 'Average time to fulfill an order', 'OPERATIONAL_EFFICIENCY', 'NUMBER', 10, 'DAILY', 'minutes', 15, 20, 'AVG(fulfilled_time - created_time)', v_user_id),
      (v_store_id, 'Inventory Turnover', 'Number of times inventory is sold and replaced', 'INVENTORY', 'NUMBER', 8, 'MONTHLY', 'times', 6, 4, 'COGS / average_inventory', v_user_id);
    
    RAISE NOTICE 'Created 9 KPI definitions';
  ELSE
    RAISE NOTICE 'Store or User not found. Please create store and users first.';
  END IF;
END $$;

-- ============================================================================
-- 2. KPI TRACKING - Sample tracking data
-- ============================================================================

DO $$
DECLARE
  v_store_id UUID;
  v_user_id UUID;
  v_kpi_id UUID;
  v_actual DECIMAL;
  v_target DECIMAL;
BEGIN
  SELECT id INTO v_store_id FROM public.stores LIMIT 1;
  SELECT id INTO v_user_id FROM public.users WHERE role IN ('MANAGER', 'CEO') LIMIT 1;
  
  IF v_store_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    
    -- Track Monthly Revenue (October 2025)
    SELECT id, target_value INTO v_kpi_id, v_target 
    FROM public.kpi_definitions 
    WHERE name = 'Monthly Revenue' AND store_id = v_store_id 
    LIMIT 1;
    
    IF v_kpi_id IS NOT NULL THEN
      v_actual := 45000000; -- 45M VND (below target of 50M)
      
      INSERT INTO public.kpi_tracking (
        kpi_definition_id, store_id, period_start, period_end, period_label,
        actual_value, target_value, achievement_rate, variance, variance_percentage,
        status, alert_triggered, notes, recorded_by
      ) VALUES (
        v_kpi_id, v_store_id, '2025-10-01', '2025-10-31', 'October 2025',
        v_actual, v_target, 
        ROUND((v_actual / v_target) * 100, 2), -- 90%
        v_actual - v_target, -- -5M
        ROUND(((v_actual - v_target) / v_target) * 100, 2), -- -10%
        'AT_RISK', true, 
        'Revenue slightly below target due to rainy weather affecting customer traffic',
        v_user_id
      );
    END IF;
    
    -- Track Table Occupancy (Today)
    SELECT id, target_value INTO v_kpi_id, v_target 
    FROM public.kpi_definitions 
    WHERE name = 'Table Occupancy Rate' AND store_id = v_store_id 
    LIMIT 1;
    
    IF v_kpi_id IS NOT NULL THEN
      v_actual := 75; -- 75% (above target)
      
      INSERT INTO public.kpi_tracking (
        kpi_definition_id, store_id, period_start, period_end, period_label,
        actual_value, target_value, achievement_rate, variance, variance_percentage,
        status, alert_triggered, notes, recorded_by
      ) VALUES (
        v_kpi_id, v_store_id, CURRENT_DATE, CURRENT_DATE, 'Today',
        v_actual, v_target,
        ROUND((v_actual / v_target) * 100, 2), -- 107%
        v_actual - v_target, -- +5%
        ROUND(((v_actual - v_target) / v_target) * 100, 2),
        'EXCEEDING', false,
        'Great performance today! Weekend peak traffic',
        v_user_id
      );
    END IF;
    
    -- Track Customer Satisfaction (October)
    SELECT id, target_value INTO v_kpi_id, v_target 
    FROM public.kpi_definitions 
    WHERE name = 'Customer Satisfaction Score' AND store_id = v_store_id 
    LIMIT 1;
    
    IF v_kpi_id IS NOT NULL THEN
      v_actual := 4.2;
      
      INSERT INTO public.kpi_tracking (
        kpi_definition_id, store_id, period_start, period_end, period_label,
        actual_value, target_value, achievement_rate, variance, variance_percentage,
        status, alert_triggered, notes, recorded_by
      ) VALUES (
        v_kpi_id, v_store_id, '2025-10-01', '2025-10-31', 'October 2025',
        v_actual, v_target,
        ROUND((v_actual / v_target) * 100, 2),
        v_actual - v_target,
        ROUND(((v_actual - v_target) / v_target) * 100, 2),
        'AT_RISK', true,
        'Slightly below target. Need to improve service quality',
        v_user_id
      );
    END IF;
    
    RAISE NOTICE 'Created KPI tracking records';
  END IF;
END $$;

-- ============================================================================
-- 3. MARKETING CAMPAIGNS - Sample campaigns
-- ============================================================================

DO $$
DECLARE
  v_store_id UUID;
  v_user_id UUID;
  v_campaign_id UUID;
BEGIN
  SELECT id INTO v_store_id FROM public.stores LIMIT 1;
  SELECT id INTO v_user_id FROM public.users WHERE role IN ('MANAGER', 'CEO') LIMIT 1;
  
  IF v_store_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    
    -- Active Social Media Campaign
    INSERT INTO public.marketing_campaigns (
      store_id, name, description, campaign_type, channels,
      budget, actual_spent, start_date, end_date,
      target_audience, target_reach,
      impressions, clicks, conversions, revenue_generated,
      click_through_rate, conversion_rate, roi,
      status, creative_urls, landing_page_url, promo_code,
      notes, created_by
    ) VALUES (
      v_store_id,
      'Weekend Happy Hour Promotion',
      'Special pricing for weekend evening sessions',
      'SOCIAL_MEDIA',
      ARRAY['facebook', 'instagram', 'zalo'],
      5000000, -- 5M budget
      3200000, -- 3.2M spent
      '2025-10-01',
      '2025-10-31',
      'Young adults 18-35, local area',
      50000, -- Target 50k reach
      45000, -- 45k impressions
      2500, -- 2.5k clicks
      180, -- 180 conversions
      12000000, -- 12M revenue generated
      ROUND((2500::DECIMAL / 45000) * 100, 2), -- 5.56% CTR
      ROUND((180::DECIMAL / 2500) * 100, 2), -- 7.2% conversion
      ROUND(((12000000 - 3200000)::DECIMAL / 3200000) * 100, 2), -- 275% ROI
      'ACTIVE',
      ARRAY['https://example.com/campaign1.jpg'],
      'https://sabohub.com/happy-hour',
      'WEEKEND20',
      'Campaign performing well, consider extending',
      v_user_id
    ) RETURNING id INTO v_campaign_id;
    
    -- Completed Email Campaign
    INSERT INTO public.marketing_campaigns (
      store_id, name, description, campaign_type, channels,
      budget, actual_spent, start_date, end_date,
      target_audience, target_reach,
      impressions, clicks, conversions, revenue_generated,
      click_through_rate, conversion_rate, roi,
      status, landing_page_url, promo_code,
      success_notes, created_by
    ) VALUES (
      v_store_id,
      'Grand Opening Anniversary',
      'Celebrate 1 year anniversary with special offers',
      'EMAIL',
      ARRAY['email', 'sms'],
      2000000,
      1800000,
      '2025-09-01',
      '2025-09-15',
      'Existing customers',
      10000,
      8500, -- 8.5k emails sent
      1200, -- 1.2k clicks
      95, -- 95 conversions
      6500000, -- 6.5M revenue
      ROUND((1200::DECIMAL / 8500) * 100, 2),
      ROUND((95::DECIMAL / 1200) * 100, 2),
      ROUND(((6500000 - 1800000)::DECIMAL / 1800000) * 100, 2),
      'COMPLETED',
      'https://sabohub.com/anniversary',
      'BDAY1YEAR',
      'Very successful campaign. High customer engagement. Repeat for next year.',
      v_user_id
    );
    
    -- Scheduled Promotion
    INSERT INTO public.marketing_campaigns (
      store_id, name, description, campaign_type, channels,
      budget, start_date, end_date,
      target_audience, status, created_by
    ) VALUES (
      v_store_id,
      'Christmas Season 2025',
      'Holiday special events and pricing',
      'PROMOTION',
      ARRAY['facebook', 'instagram', 'tiktok', 'zalo'],
      10000000,
      '2025-12-15',
      '2025-12-31',
      'All customers, families, groups',
      'SCHEDULED',
      v_user_id
    );
    
    RAISE NOTICE 'Created 3 marketing campaigns';
    
    -- ========================================================================
    -- 4. SCHEDULED POSTS - Sample scheduled posts
    -- ========================================================================
    
    -- Upcoming post for the active campaign
    INSERT INTO public.scheduled_posts (
      store_id, content, media_urls, hashtags, platforms,
      scheduled_time, status, campaign_id,
      requires_approval, created_by
    ) VALUES (
      v_store_id,
      'Cuối tuần này đến SABOHUB! 🎱✨
      
Happy Hour đặc biệt:
🕐 18:00 - 22:00 thứ 6, 7, CN
💰 Giảm 20% tất cả các bàn
🍹 Đồ uống miễn phí cho nhóm 4+

Dùng code: WEEKEND20

#SaboHub #Billiards #HappyHour #Weekend #HoChiMinh',
      ARRAY['https://example.com/promo-image.jpg'],
      ARRAY['SaboHub', 'Billiards', 'HappyHour', 'Weekend', 'HoChiMinh', 'Promotion'],
      ARRAY['facebook', 'instagram', 'zalo'],
      NOW() + INTERVAL '2 hours',
      'SCHEDULED',
      v_campaign_id,
      false, -- Auto-approved
      v_user_id
    );
    
    -- Post for tomorrow
    INSERT INTO public.scheduled_posts (
      store_id, content, media_urls, hashtags, platforms,
      scheduled_time, status, campaign_id,
      requires_approval, approved_by, approved_at, created_by
    ) VALUES (
      v_store_id,
      'Thứ 7 này, ai chưa có kế hoạch? 🎯
      
Đến SABOHUB trải nghiệm:
✅ Bàn bi-a chuẩn quốc tế
✅ Không gian thoáng mát
✅ Nhân viên chuyên nghiệp
✅ Đồ uống phong phú

Book bàn ngay! ☎️ 0123456789

#Billiards #WeekendVibes #SaboHub',
      ARRAY['https://example.com/table-photo.jpg', 'https://example.com/atmosphere.jpg'],
      ARRAY['Billiards', 'WeekendVibes', 'SaboHub', 'Entertainment'],
      ARRAY['facebook', 'tiktok'],
      NOW() + INTERVAL '1 day',
      'SCHEDULED',
      v_campaign_id,
      true, -- Requires approval
      v_user_id, -- Pre-approved
      NOW(),
      v_user_id
    );
    
    -- Published post (historical)
    INSERT INTO public.scheduled_posts (
      store_id, content, media_urls, hashtags, platforms,
      scheduled_time, status, 
      published_at, published_by,
      publishing_results,
      created_by
    ) VALUES (
      v_store_id,
      'Cảm ơn các bạn đã ủng hộ SABOHUB! 🙏
      
Tuần này chúng tôi đã phục vụ hơn 500 khách hàng! 🎉
      
Hẹn gặp lại cuối tuần này! 💪

#ThankYou #SaboHub #Billiards',
      ARRAY['https://example.com/thankyou.jpg'],
      ARRAY['ThankYou', 'SaboHub', 'Billiards', 'Grateful'],
      ARRAY['facebook', 'instagram'],
      NOW() - INTERVAL '3 days',
      'PUBLISHED',
      NOW() - INTERVAL '3 days' + INTERVAL '5 minutes',
      v_user_id,
      jsonb_build_object(
        'facebook', jsonb_build_object(
          'status', 'published',
          'post_id', 'fb_123456789',
          'url', 'https://facebook.com/sabohub/posts/123456789',
          'published_at', NOW() - INTERVAL '3 days'
        ),
        'instagram', jsonb_build_object(
          'status', 'published',
          'post_id', 'ig_987654321',
          'url', 'https://instagram.com/p/ABC123',
          'published_at', NOW() - INTERVAL '3 days'
        )
      ),
      v_user_id
    );
    
    RAISE NOTICE 'Created 3 scheduled posts';
    
  END IF;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check created data
SELECT 'KPI Definitions' as table_name, COUNT(*) as count FROM public.kpi_definitions
UNION ALL
SELECT 'KPI Tracking', COUNT(*) FROM public.kpi_tracking
UNION ALL
SELECT 'Marketing Campaigns', COUNT(*) FROM public.marketing_campaigns
UNION ALL
SELECT 'Scheduled Posts', COUNT(*) FROM public.scheduled_posts;

-- ============================================================================
-- END OF SEED DATA
-- ============================================================================
