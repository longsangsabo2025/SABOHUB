-- ============================================================================
-- SPRINT 2 TABLES MIGRATION
-- ============================================================================
-- Creates 4 new tables for Sprint 2 backend features:
-- 1. kpi_definitions - Define KPI metrics with targets
-- 2. kpi_tracking - Track actual KPI values against targets
-- 3. marketing_campaigns - Manage marketing campaigns with ROI tracking
-- 4. scheduled_posts - Schedule multi-platform social media posts
-- ============================================================================

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. KPI_DEFINITIONS - Define KPI metrics
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.kpi_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  
  -- KPI Details
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN (
    'REVENUE', 'CUSTOMER_SATISFACTION', 'OPERATIONAL_EFFICIENCY', 
    'STAFF_PERFORMANCE', 'TABLE_UTILIZATION', 'INVENTORY', 'MARKETING', 'OTHER'
  )),
  
  -- Target Configuration
  metric_type TEXT NOT NULL CHECK (metric_type IN ('NUMBER', 'PERCENTAGE', 'CURRENCY', 'RATIO')),
  target_value DECIMAL(15, 2) NOT NULL,
  target_period TEXT NOT NULL CHECK (target_period IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
  unit TEXT, -- e.g., 'VND', '%', 'hours', 'tables'
  
  -- Thresholds for alerts
  warning_threshold DECIMAL(15, 2), -- Below this = warning
  critical_threshold DECIMAL(15, 2), -- Below this = critical alert
  
  -- Calculation formula (for documentation)
  formula TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Metadata
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint
  UNIQUE(store_id, name, target_period)
);

-- Indexes for performance
CREATE INDEX idx_kpi_definitions_store_id ON public.kpi_definitions(store_id);
CREATE INDEX idx_kpi_definitions_category ON public.kpi_definitions(category);
CREATE INDEX idx_kpi_definitions_is_active ON public.kpi_definitions(is_active);

-- Row Level Security
ALTER TABLE public.kpi_definitions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view KPIs for their store
CREATE POLICY "Users can view store KPIs"
  ON public.kpi_definitions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND (
          u.store_id = kpi_definitions.store_id
          OR u.role IN ('CEO', 'MANAGER')
        )
    )
  );

-- Policy: Managers and CEO can manage KPIs
CREATE POLICY "Managers can manage KPIs"
  ON public.kpi_definitions
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.role IN ('CEO', 'MANAGER')
        AND (u.store_id = kpi_definitions.store_id OR u.role = 'CEO')
    )
  );

-- ============================================================================
-- 2. KPI_TRACKING - Track actual KPI values
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.kpi_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kpi_definition_id UUID NOT NULL REFERENCES public.kpi_definitions(id) ON DELETE CASCADE,
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  
  -- Tracking Period
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  period_label TEXT NOT NULL, -- e.g., 'Week 42, 2025', 'October 2025'
  
  -- Actual vs Target
  actual_value DECIMAL(15, 2) NOT NULL,
  target_value DECIMAL(15, 2) NOT NULL,
  achievement_rate DECIMAL(5, 2), -- Percentage: (actual / target) * 100
  
  -- Variance Analysis
  variance DECIMAL(15, 2), -- actual - target
  variance_percentage DECIMAL(5, 2), -- ((actual - target) / target) * 100
  
  -- Status
  status TEXT NOT NULL DEFAULT 'ON_TRACK' CHECK (status IN (
    'EXCEEDING', 'ON_TRACK', 'AT_RISK', 'CRITICAL'
  )),
  
  -- Alert tracking
  alert_triggered BOOLEAN DEFAULT false,
  alert_sent_at TIMESTAMPTZ,
  
  -- Notes and context
  notes TEXT,
  contributing_factors JSONB, -- Store additional context
  
  -- Metadata
  recorded_by UUID NOT NULL REFERENCES public.users(id),
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint
  UNIQUE(kpi_definition_id, period_start, period_end)
);

-- Indexes for performance
CREATE INDEX idx_kpi_tracking_kpi_definition_id ON public.kpi_tracking(kpi_definition_id);
CREATE INDEX idx_kpi_tracking_store_id ON public.kpi_tracking(store_id);
CREATE INDEX idx_kpi_tracking_period_start ON public.kpi_tracking(period_start);
CREATE INDEX idx_kpi_tracking_status ON public.kpi_tracking(status);
CREATE INDEX idx_kpi_tracking_alert_triggered ON public.kpi_tracking(alert_triggered);

-- Row Level Security
ALTER TABLE public.kpi_tracking ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view KPI tracking for their store
CREATE POLICY "Users can view store KPI tracking"
  ON public.kpi_tracking
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND (
          u.store_id = kpi_tracking.store_id
          OR u.role IN ('CEO', 'MANAGER')
        )
    )
  );

-- Policy: Staff can record KPI tracking
CREATE POLICY "Staff can record KPI tracking"
  ON public.kpi_tracking
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.role IN ('CEO', 'MANAGER', 'SHIFT_LEADER')
        AND (u.store_id = kpi_tracking.store_id OR u.role = 'CEO')
    )
  );

-- Policy: Managers can update KPI tracking
CREATE POLICY "Managers can update KPI tracking"
  ON public.kpi_tracking
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.role IN ('CEO', 'MANAGER')
        AND (u.store_id = kpi_tracking.store_id OR u.role = 'CEO')
    )
  );

-- ============================================================================
-- 3. MARKETING_CAMPAIGNS - Marketing campaign management
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.marketing_campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  
  -- Campaign Details
  name TEXT NOT NULL,
  description TEXT,
  campaign_type TEXT NOT NULL CHECK (campaign_type IN (
    'SOCIAL_MEDIA', 'EMAIL', 'SMS', 'PROMOTION', 'EVENT', 'REFERRAL', 'OTHER'
  )),
  
  -- Channels
  channels TEXT[] NOT NULL DEFAULT '{}', -- e.g., ['facebook', 'instagram', 'zalo']
  
  -- Budget & Investment
  budget DECIMAL(15, 2) DEFAULT 0,
  actual_spent DECIMAL(15, 2) DEFAULT 0,
  currency TEXT DEFAULT 'VND',
  
  -- Timeline
  start_date DATE NOT NULL,
  end_date DATE,
  
  -- Target Audience
  target_audience TEXT,
  target_reach INTEGER, -- Expected reach
  
  -- Performance Metrics
  impressions INTEGER DEFAULT 0, -- Total views
  clicks INTEGER DEFAULT 0, -- Total clicks
  conversions INTEGER DEFAULT 0, -- Total conversions (customers/sales)
  revenue_generated DECIMAL(15, 2) DEFAULT 0, -- Direct revenue from campaign
  
  -- Calculated Metrics (can be computed)
  click_through_rate DECIMAL(5, 2), -- (clicks / impressions) * 100
  conversion_rate DECIMAL(5, 2), -- (conversions / clicks) * 100
  roi DECIMAL(10, 2), -- ((revenue - spent) / spent) * 100
  cost_per_click DECIMAL(10, 2), -- spent / clicks
  cost_per_conversion DECIMAL(10, 2), -- spent / conversions
  
  -- Status
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN (
    'DRAFT', 'SCHEDULED', 'ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED'
  )),
  
  -- Creative Assets
  creative_urls TEXT[], -- URLs to campaign images/videos
  landing_page_url TEXT,
  promo_code TEXT,
  
  -- Notes
  notes TEXT,
  success_notes TEXT, -- What worked well
  
  -- Metadata
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Validation
  CONSTRAINT valid_dates CHECK (end_date IS NULL OR end_date >= start_date),
  CONSTRAINT valid_budget CHECK (budget >= 0),
  CONSTRAINT valid_metrics CHECK (
    impressions >= 0 AND clicks >= 0 AND conversions >= 0
  )
);

-- Indexes for performance
CREATE INDEX idx_marketing_campaigns_store_id ON public.marketing_campaigns(store_id);
CREATE INDEX idx_marketing_campaigns_status ON public.marketing_campaigns(status);
CREATE INDEX idx_marketing_campaigns_start_date ON public.marketing_campaigns(start_date);
CREATE INDEX idx_marketing_campaigns_end_date ON public.marketing_campaigns(end_date);
CREATE INDEX idx_marketing_campaigns_campaign_type ON public.marketing_campaigns(campaign_type);

-- Row Level Security
ALTER TABLE public.marketing_campaigns ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view campaigns for their store
CREATE POLICY "Users can view store campaigns"
  ON public.marketing_campaigns
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND (
          u.store_id = marketing_campaigns.store_id
          OR u.role IN ('CEO', 'MANAGER')
        )
    )
  );

-- Policy: Managers can manage campaigns
CREATE POLICY "Managers can manage campaigns"
  ON public.marketing_campaigns
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.role IN ('CEO', 'MANAGER')
        AND (u.store_id = marketing_campaigns.store_id OR u.role = 'CEO')
    )
  );

-- ============================================================================
-- 4. SCHEDULED_POSTS - Social media post scheduling
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scheduled_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  
  -- Post Content
  content TEXT NOT NULL,
  media_urls TEXT[] DEFAULT '{}', -- Image/video URLs
  hashtags TEXT[] DEFAULT '{}',
  
  -- Target Platforms
  platforms TEXT[] NOT NULL DEFAULT '{}', -- e.g., ['facebook', 'instagram', 'zalo', 'tiktok']
  
  -- Scheduling
  scheduled_time TIMESTAMPTZ NOT NULL,
  timezone TEXT DEFAULT 'Asia/Ho_Chi_Minh',
  
  -- Publishing Status
  status TEXT NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN (
    'DRAFT', 'SCHEDULED', 'PUBLISHING', 'PUBLISHED', 'FAILED', 'CANCELLED'
  )),
  
  -- Publishing Results (per platform)
  publishing_results JSONB DEFAULT '{}', 
  -- Example: {"facebook": {"status": "published", "post_id": "123", "url": "..."}}
  
  -- Error Handling
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  
  -- Published Info
  published_at TIMESTAMPTZ,
  published_by UUID REFERENCES public.users(id),
  
  -- Campaign Association
  campaign_id UUID REFERENCES public.marketing_campaigns(id) ON DELETE SET NULL,
  
  -- Approval Workflow
  requires_approval BOOLEAN DEFAULT false,
  approved_by UUID REFERENCES public.users(id),
  approved_at TIMESTAMPTZ,
  approval_notes TEXT,
  
  -- Metadata
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Validation
  CONSTRAINT valid_platforms CHECK (array_length(platforms, 1) > 0),
  CONSTRAINT valid_scheduled_time CHECK (scheduled_time > created_at)
);

-- Indexes for performance
CREATE INDEX idx_scheduled_posts_store_id ON public.scheduled_posts(store_id);
CREATE INDEX idx_scheduled_posts_status ON public.scheduled_posts(status);
CREATE INDEX idx_scheduled_posts_scheduled_time ON public.scheduled_posts(scheduled_time);
CREATE INDEX idx_scheduled_posts_campaign_id ON public.scheduled_posts(campaign_id);
CREATE INDEX idx_scheduled_posts_created_by ON public.scheduled_posts(created_by);

-- Row Level Security
ALTER TABLE public.scheduled_posts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view posts for their store
CREATE POLICY "Users can view store posts"
  ON public.scheduled_posts
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND (
          u.store_id = scheduled_posts.store_id
          OR u.role IN ('CEO', 'MANAGER')
        )
    )
  );

-- Policy: Staff can create posts (may require approval)
CREATE POLICY "Staff can create posts"
  ON public.scheduled_posts
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF')
        AND (u.store_id = scheduled_posts.store_id OR u.role IN ('CEO', 'MANAGER'))
    )
  );

-- Policy: Creators and managers can update their posts
CREATE POLICY "Users can update their posts"
  ON public.scheduled_posts
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND (
          u.id = scheduled_posts.created_by
          OR u.role IN ('CEO', 'MANAGER')
        )
        AND (u.store_id = scheduled_posts.store_id OR u.role IN ('CEO', 'MANAGER'))
    )
  );

-- ============================================================================
-- TRIGGERS - Auto-update timestamps
-- ============================================================================

-- Trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all new tables
CREATE TRIGGER update_kpi_definitions_updated_at
  BEFORE UPDATE ON public.kpi_definitions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kpi_tracking_updated_at
  BEFORE UPDATE ON public.kpi_tracking
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_marketing_campaigns_updated_at
  BEFORE UPDATE ON public.marketing_campaigns
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scheduled_posts_updated_at
  BEFORE UPDATE ON public.scheduled_posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS - Table documentation
-- ============================================================================

COMMENT ON TABLE public.kpi_definitions IS 'Defines KPI metrics with targets for tracking business performance';
COMMENT ON TABLE public.kpi_tracking IS 'Tracks actual KPI values against defined targets over time';
COMMENT ON TABLE public.marketing_campaigns IS 'Manages marketing campaigns with budget tracking and ROI calculation';
COMMENT ON TABLE public.scheduled_posts IS 'Schedules multi-platform social media posts with approval workflow';

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
-- Next steps:
-- 1. Run this migration in Supabase SQL Editor
-- 2. Verify tables are created: SELECT * FROM information_schema.tables WHERE table_schema = 'public';
-- 3. Test Sprint 2 endpoints with real data
-- 4. Create seed data for testing
-- ============================================================================
