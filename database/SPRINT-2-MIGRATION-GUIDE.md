# 🗄️ Sprint 2 Database Migration Guide

## 📋 Overview

This guide will help you deploy the 4 new database tables required for Sprint 2 backend features.

**New Tables:**
1. `kpi_definitions` - Define KPI metrics with targets
2. `kpi_tracking` - Track actual KPI values against targets  
3. `marketing_campaigns` - Manage marketing campaigns with ROI tracking
4. `scheduled_posts` - Schedule multi-platform social media posts

---

## ✅ Prerequisites

- ✅ Supabase project: `vuxuqvgkfjemthbdwsnh`
- ✅ Access to Supabase SQL Editor
- ✅ Service Role Key (for admin access)
- ✅ Existing tables: `stores`, `users` (already confirmed ✅)

---

## 🚀 Deployment Steps

### Step 1: Run Migration Script

1. Go to Supabase Dashboard: https://supabase.com/dashboard/project/vuxuqvgkfjemthbdwsnh
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy and paste the contents of `sprint-2-tables-migration.sql`
5. Click **Run** or press `Cmd/Ctrl + Enter`

**Expected Result:**
```
CREATE TABLE
CREATE INDEX
ALTER TABLE
CREATE POLICY
... (repeat for all 4 tables)
```

**Time:** ~10 seconds

---

### Step 2: Verify Tables Created

Run this query in SQL Editor:

```sql
SELECT 
  table_name,
  (SELECT COUNT(*) 
   FROM information_schema.columns 
   WHERE table_schema = 'public' 
     AND table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'kpi_definitions',
    'kpi_tracking',
    'marketing_campaigns',
    'scheduled_posts'
  )
ORDER BY table_name;
```

**Expected Output:**
```
table_name              | column_count
------------------------+-------------
kpi_definitions         | 16
kpi_tracking            | 17
marketing_campaigns     | 28
scheduled_posts         | 20
```

---

### Step 3: Load Seed Data (Optional)

For testing purposes, load sample data:

1. Open **SQL Editor** again
2. Copy contents of `sprint-2-seed-data.sql`
3. Click **Run**

**Expected Result:**
```
NOTICE: Created 9 KPI definitions
NOTICE: Created KPI tracking records
NOTICE: Created 3 marketing campaigns
NOTICE: Created 3 scheduled posts
```

**Verification Query:**
```sql
SELECT 'KPI Definitions' as table_name, COUNT(*) as count FROM kpi_definitions
UNION ALL
SELECT 'KPI Tracking', COUNT(*) FROM kpi_tracking
UNION ALL
SELECT 'Marketing Campaigns', COUNT(*) FROM marketing_campaigns
UNION ALL
SELECT 'Scheduled Posts', COUNT(*) FROM scheduled_posts;
```

---

### Step 4: Test Backend Endpoints

Use the following test script to verify endpoints work:

```bash
node scripts/test-sprint-2-endpoints.js
```

Or manually test with `curl`:

```bash
# Test Analytics API
curl -X POST http://localhost:8081/api/trpc/analytics.getRevenueStats \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"startDate":"2025-10-01","endDate":"2025-10-31"}'

# Test KPI Module
curl -X POST http://localhost:8081/api/trpc/kpiModule.getKpiDashboard \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test Marketing Module
curl -X POST http://localhost:8081/api/trpc/marketing.listCampaigns \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test Publishing Module
curl -X POST http://localhost:8081/api/trpc/publishingEnhanced.getPublishingCalendar \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"startDate":"2025-10-01","endDate":"2025-10-31"}'
```

---

## 📊 Database Schema Details

### 1. `kpi_definitions`

**Purpose:** Define business KPIs with targets and alert thresholds

**Key Columns:**
- `name`, `description`, `category`
- `target_value`, `target_period` (DAILY/WEEKLY/MONTHLY/QUARTERLY/YEARLY)
- `warning_threshold`, `critical_threshold`
- `is_active`

**Indexes:**
- `store_id`, `category`, `is_active`

**RLS Policies:**
- Users can view KPIs for their store
- Only CEO/Managers can create/update KPIs

---

### 2. `kpi_tracking`

**Purpose:** Track actual KPI performance over time

**Key Columns:**
- `kpi_definition_id` (FK)
- `period_start`, `period_end`, `period_label`
- `actual_value`, `target_value`
- `achievement_rate`, `variance`, `variance_percentage`
- `status` (EXCEEDING/ON_TRACK/AT_RISK/CRITICAL)
- `alert_triggered`

**Indexes:**
- `kpi_definition_id`, `store_id`, `period_start`, `status`, `alert_triggered`

**RLS Policies:**
- Users can view tracking for their store
- Shift Leaders+ can record KPI values
- Managers can update tracking records

---

### 3. `marketing_campaigns`

**Purpose:** Manage marketing campaigns with performance tracking

**Key Columns:**
- `name`, `description`, `campaign_type`
- `channels` (array: facebook, instagram, zalo, etc.)
- `budget`, `actual_spent`
- `start_date`, `end_date`
- `impressions`, `clicks`, `conversions`, `revenue_generated`
- `click_through_rate`, `conversion_rate`, `roi`
- `status` (DRAFT/SCHEDULED/ACTIVE/PAUSED/COMPLETED/CANCELLED)

**Calculated Metrics:**
- CTR = (clicks / impressions) × 100
- Conversion Rate = (conversions / clicks) × 100
- ROI = ((revenue - spent) / spent) × 100
- Cost per Click = spent / clicks
- Cost per Conversion = spent / conversions

**Indexes:**
- `store_id`, `status`, `start_date`, `end_date`, `campaign_type`

**RLS Policies:**
- Users can view campaigns for their store
- Only CEO/Managers can manage campaigns

---

### 4. `scheduled_posts`

**Purpose:** Schedule social media posts across multiple platforms

**Key Columns:**
- `content`, `media_urls` (array), `hashtags` (array)
- `platforms` (array: facebook, instagram, zalo, tiktok)
- `scheduled_time`, `timezone`
- `status` (DRAFT/SCHEDULED/PUBLISHING/PUBLISHED/FAILED/CANCELLED)
- `publishing_results` (JSONB - per-platform results)
- `campaign_id` (optional FK to marketing_campaigns)
- `requires_approval`, `approved_by`, `approved_at`

**Features:**
- Multi-platform publishing
- Approval workflow
- Retry mechanism (max 3 retries)
- Detailed publishing results per platform

**Indexes:**
- `store_id`, `status`, `scheduled_time`, `campaign_id`, `created_by`

**RLS Policies:**
- Users can view posts for their store
- All staff can create posts (may require approval)
- Creators and managers can update posts

---

## 🔐 Row Level Security (RLS)

All 4 tables have RLS enabled with policies:

**General Rules:**
- ✅ CEO can access ALL stores
- ✅ Managers can access their assigned store
- ✅ Staff can VIEW data for their store
- ✅ Only Managers+ can CREATE/UPDATE/DELETE

**Security Features:**
- Auto-check `auth.uid()` for authenticated user
- Join with `users` table to verify roles
- Store-level isolation (multi-tenant safe)

---

## 🎯 Testing Checklist

After migration, verify:

### Database Level
- [ ] All 4 tables created successfully
- [ ] All indexes created
- [ ] All RLS policies active
- [ ] All triggers working
- [ ] Seed data loaded (if applicable)

### API Level
- [ ] Analytics endpoints return data
- [ ] KPI Module endpoints work
- [ ] Marketing endpoints CRUD operations
- [ ] Publishing endpoints scheduling works

### Security Level
- [ ] RLS blocks unauthorized access
- [ ] CEO can access all stores
- [ ] Managers limited to their store
- [ ] Staff can only view, not modify

---

## 🐛 Troubleshooting

### Error: "relation already exists"

**Cause:** Table already created

**Solution:** Safe to ignore (migration uses `IF NOT EXISTS`)

---

### Error: "permission denied for table"

**Cause:** RLS blocking your query

**Solution:** 
1. Use service role key (bypasses RLS)
2. Or ensure user has correct role and store_id

---

### Error: "column does not exist"

**Cause:** Missing required columns in input

**Solution:** Check tRPC endpoint input schema, all required fields must be provided

---

### No data returned from endpoints

**Possible Causes:**
1. No data in database (run seed data)
2. User not associated with store (set `store_id` in users table)
3. Wrong date range filters

**Solution:**
```sql
-- Check if user has store_id
SELECT id, email, role, store_id FROM users WHERE id = 'YOUR_USER_ID';

-- If null, update:
UPDATE users 
SET store_id = (SELECT id FROM stores LIMIT 1)
WHERE id = 'YOUR_USER_ID';
```

---

## 📝 Rollback (Emergency)

If you need to undo the migration:

```sql
-- Drop tables (CASCADE will remove dependent objects)
DROP TABLE IF EXISTS public.scheduled_posts CASCADE;
DROP TABLE IF EXISTS public.marketing_campaigns CASCADE;
DROP TABLE IF EXISTS public.kpi_tracking CASCADE;
DROP TABLE IF EXISTS public.kpi_definitions CASCADE;

-- Note: This will DELETE ALL DATA in these tables!
```

---

## 🎉 Success Criteria

Migration is successful when:

✅ All 4 tables exist in Supabase  
✅ All indexes and policies created  
✅ Seed data loaded (9 KPIs, 3 campaigns, 3 posts)  
✅ All 19 Sprint 2 endpoints return valid responses  
✅ RLS properly restricts access by role and store  

---

## 📞 Support

**Issues?** Check:
1. Supabase Dashboard Logs
2. Backend server console output
3. Browser Network tab for API errors

**Questions?**
- Review Sprint 2 documentation: `SPRINT-2-SUMMARY.md`
- Check endpoint implementations: `backend/trpc/routes/`

---

## 🔄 Next Steps

After successful migration:

1. ✅ Update API documentation
2. ✅ Notify Dev A (frontend) that endpoints are ready
3. ✅ Set up monitoring/alerts for KPI tracking
4. ✅ Configure social media API keys for publishing
5. ✅ Train staff on new features

---

**Migration Created:** October 13, 2025  
**Developer:** Developer B  
**Sprint:** Sprint 2 - Advanced Features  
**Tables:** 4 new tables, 19 new endpoints
