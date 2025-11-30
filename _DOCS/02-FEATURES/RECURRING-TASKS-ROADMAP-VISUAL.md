# 🗺️ RECURRING TASKS - VISUAL ROADMAP

```
PHASE 1: Manual Templates          PHASE 2: Auto-Generation
[✅ COMPLETE]                       [📋 PLANNED]
     │                                    │
     ├─ Database Schema ✅                ├─ Week 1: Database + Edge Function
     ├─ Models & Services ✅              │  ├─ Add tracking columns
     ├─ Providers ✅                      │  ├─ Create generation logs table
     ├─ UI Integration ✅                 │  ├─ Write helper functions
     └─ Documentation ✅                  │  ├─ Implement Edge Function
                                          │  └─ Unit tests
                                          │
                                          ├─ Week 2: Cron + UI
                                          │  ├─ Enable pg_cron
                                          │  ├─ Schedule daily job
                                          │  ├─ Templates management page
                                          │  ├─ Generation logs viewer
                                          │  └─ Integration tests
                                          │
                                          └─ Week 3: Testing + Deployment
                                             ├─ Load testing
                                             ├─ Security audit
                                             ├─ Production deployment
                                             ├─ Enable cron job
                                             └─ Monitoring setup

════════════════════════════════════════════════════════════════════════

TIMELINE:

Month 1          Month 2          Month 3          Month 4
├───────────────┼───────────────┼───────────────┼──────────────►
│ Phase 1       │ Phase 2       │ Monitoring    │ Optimization
│ ✅ DONE       │ ⏳ 3 weeks    │ 📊 Ongoing    │ 🚀 Future
│               │               │               │
│ - Upload docs │ - Database    │ - Track       │ - ML predictions
│ - AI analyze  │ - Edge Func   │   success     │ - Smart scheduling
│ - Create      │ - Cron job    │ - Fix bugs    │ - Auto-adjust
│   templates   │ - UI polish   │ - User        │ - Advanced rules
│ - Manual      │ - Deploy      │   feedback    │
│   generation  │               │               │

════════════════════════════════════════════════════════════════════════

ARCHITECTURE OVERVIEW:

┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Create       │  │ Manage       │  │ View         │         │
│  │ Templates    │  │ Templates    │  │ Logs         │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                 │                 │                   │
└─────────┼─────────────────┼─────────────────┼───────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SUPABASE BACKEND                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   PostgreSQL Database                     │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │  │
│  │  │ Templates   │  │ Tasks        │  │ Generation     │  │  │
│  │  │ (22 cols)   │  │              │  │ Logs           │  │  │
│  │  └─────────────┘  └──────────────┘  └────────────────┘  │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                           │                                     │
│  ┌────────────────────────┴─────────────────────────────────┐  │
│  │                    pg_cron Extension                      │  │
│  │  ┌───────────────────────────────────────────────────┐   │  │
│  │  │ Schedule: Every day at 00:00 (midnight)           │   │  │
│  │  │ Action: Call Edge Function                        │   │  │
│  │  └───────────────────────────────────────────────────┘   │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                           │                                     │
│  ┌────────────────────────▼─────────────────────────────────┐  │
│  │              Edge Function (Deno Runtime)                │  │
│  │  ┌───────────────────────────────────────────────────┐   │  │
│  │  │ 1. Get active templates                           │   │  │
│  │  │ 2. Check if should generate today                 │   │  │
│  │  │ 3. Find best employee (role + shift + load)       │   │  │
│  │  │ 4. Create task                                    │   │  │
│  │  │ 5. Track instance                                 │   │  │
│  │  │ 6. Update template metadata                       │   │  │
│  │  │ 7. Log results                                    │   │  │
│  │  └───────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

════════════════════════════════════════════════════════════════════════

DATA FLOW:

1. USER ACTION (Phase 1 - Current)
   User clicks "Tạo Templates" → AI suggestions → Create templates
   ┌──────────┐     ┌──────────┐     ┌──────────────┐
   │  User    │ --> │   AI     │ --> │  Templates   │
   │  Action  │     │ Analysis │     │   Database   │
   └──────────┘     └──────────┘     └──────────────┘

2. AUTO GENERATION (Phase 2 - Planned)
   Cron → Edge Function → Find Employee → Create Task
   ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
   │  00:00   │ --> │  Check   │ --> │  Find    │ --> │  Create  │
   │  Daily   │     │ Template │     │ Employee │     │   Task   │
   └──────────┘     └──────────┘     └──────────┘     └──────────┘

════════════════════════════════════════════════════════════════════════

KEY DECISIONS:

✅ Use Supabase Edge Functions (not external Cloud Functions)
   Why: Native integration, no external dependencies, free tier

✅ Use pg_cron (not external cron services)
   Why: Database-level scheduling, reliable, no webhooks needed

✅ Smart employee assignment with load balancing
   Why: Fair distribution, consider shift schedules, productivity

✅ Comprehensive logging and monitoring
   Why: Debugging, accountability, performance tracking

✅ Gradual rollout strategy
   Why: Risk mitigation, learn from small scale first

════════════════════════════════════════════════════════════════════════

RISK MITIGATION:

🔴 HIGH RISK: Cron job fails silently
   ✅ Mitigation: Health check function runs hourly, alerts on failure

🟡 MEDIUM RISK: Wrong employee assignment
   ✅ Mitigation: Fallback to random selection, manual override option

🟡 MEDIUM RISK: Database overload with many templates
   ✅ Mitigation: Batch processing, rate limiting, indexes

🟢 LOW RISK: Duplicate task creation
   ✅ Mitigation: Database constraints, double-check before insert

🟢 LOW RISK: Time zone issues
   ✅ Mitigation: Store all times in UTC, convert in app

════════════════════════════════════════════════════════════════════════

ROLLOUT STRATEGY:

Week 1: Deploy to staging
├─ Test with 5 templates
├─ Verify cron execution
└─ Check task accuracy

Week 2: Production (disabled)
├─ Deploy code
├─ Manual testing
└─ Team training

Week 3: Soft launch (1 company)
├─ Enable for SABO Billiards only
├─ Monitor closely
└─ Gather feedback

Week 4: Gradual rollout
├─ Enable for 10 companies
├─ Measure performance
└─ Adjust as needed

Week 5+: Full deployment
├─ Enable for all companies
├─ Standard monitoring
└─ Continuous improvement

════════════════════════════════════════════════════════════════════════

MONITORING DASHBOARD (Planned):

┌────────────────────────────────────────────────────────────────┐
│                    RECURRING TASKS MONITOR                     │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Today's Generation:                                           │
│  ✅ 45 tasks created from 50 templates (90% success)          │
│  ⏱️  Execution time: 2.3s                                     │
│  ❌ 5 errors (see details)                                    │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Success Rate │  │ Avg Time     │  │ Active       │       │
│  │   99.2%      │  │   2.1s       │  │ Templates    │       │
│  │   ▲ 0.5%     │  │   ▼ 0.3s     │  │   127        │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                                │
│  Recent Errors:                                                │
│  ⚠️  Template #123: No employee with role 'manager'          │
│  ⚠️  Template #456: Branch not found                         │
│                                                                │
│  [View Full Logs]  [Manual Trigger]  [Settings]              │
└────────────────────────────────────────────────────────────────┘

════════════════════════════════════════════════════════════════════════

SUCCESS CRITERIA CHECKLIST:

Technical:
[ ] ✅ 100% test coverage
[ ] ✅ < 5 seconds execution time
[ ] ✅ 0% duplicate tasks
[ ] ✅ 99.9% uptime
[ ] ✅ Proper error handling
[ ] ✅ Comprehensive logging

Business:
[ ] ✅ 80% time savings confirmed
[ ] ✅ Positive user feedback (> 4.5/5)
[ ] ✅ No manual intervention needed
[ ] ✅ Scalable to 100+ companies
[ ] ✅ Cost within budget ($0 on free tier)

Quality:
[ ] ✅ Code reviewed and approved
[ ] ✅ Security audit passed
[ ] ✅ Documentation complete
[ ] ✅ Support team trained
[ ] ✅ Rollback plan tested

════════════════════════════════════════════════════════════════════════

FUTURE ENHANCEMENTS (Phase 3+):

🔮 Machine Learning Integration
   - Predict optimal task time based on completion patterns
   - Suggest new templates based on manual task patterns
   - Auto-adjust priorities based on workload

🔮 Advanced Scheduling
   - Holiday calendar integration
   - Weather-based scheduling (e.g., skip outdoor tasks when raining)
   - Event-based triggers (e.g., before tournaments)

🔮 Smart Notifications
   - Notify employees before task due time
   - Escalate overdue tasks automatically
   - Daily digest of assigned tasks

🔮 Analytics Dashboard
   - Task completion trends
   - Employee performance metrics
   - Template effectiveness scoring

🔮 Integration Features
   - Export to Google Calendar
   - Slack/Teams notifications
   - API for third-party integrations

════════════════════════════════════════════════════════════════════════

RESOURCES:

📚 Documentation:
   - Phase 2 Full Plan: RECURRING-TASKS-PHASE-2-PLAN.md
   - Phase 1 Complete: RECURRING-TASKS-COMPLETE.md
   - Quick Reference: RECURRING-TASKS-QUICK-REF.md
   - Progress Tracker: RECURRING-TASKS-PHASE-2-TRACKER.md

🔗 External Links:
   - Supabase Edge Functions: https://supabase.com/docs/guides/functions
   - pg_cron Extension: https://github.com/citusdata/pg_cron
   - Deno Deploy: https://deno.com/deploy

👥 Team:
   - Lead Developer: TBD
   - Backend Engineer: TBD
   - QA Engineer: TBD
   - Product Manager: TBD

════════════════════════════════════════════════════════════════════════
```

**Last Updated**: 2025-11-04  
**Status**: Phase 1 Complete ✅ | Phase 2 Planned 📋  
**Next Milestone**: Week 1 - Database Enhancements
