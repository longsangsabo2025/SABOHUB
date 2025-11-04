# 🚀 RECURRING TASKS - PHASE 2 IMPLEMENTATION PLAN

**Status**: 📋 Planning Complete | ⏳ Implementation TODO  
**Target Date**: Q1 2025  
**Estimated Time**: 2-3 weeks  
**Complexity**: Medium-High

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture Decision](#architecture-decision)
3. [Implementation Steps](#implementation-steps)
4. [Database Changes](#database-changes)
5. [Backend Logic](#backend-logic)
6. [Testing Strategy](#testing-strategy)
7. [Deployment Plan](#deployment-plan)
8. [Monitoring & Maintenance](#monitoring--maintenance)

---

## 🎯 Overview

### Goal
Automatically generate daily tasks from active templates without manual intervention.

### Key Requirements
- ✅ Run every day at 00:00 (midnight)
- ✅ Generate tasks from active templates
- ✅ Smart employee assignment based on role & shift
- ✅ Prevent duplicate generation
- ✅ Track all generated instances
- ✅ Handle errors gracefully
- ✅ Logging & monitoring

### Success Metrics
- 100% task generation accuracy
- < 5 seconds execution time
- 0% duplicate tasks
- 99.9% uptime
- Clear audit trail

---

## 🏗️ Architecture Decision

### Option A: Supabase Edge Function + pg_cron ⭐ RECOMMENDED

**Pros:**
- Native Supabase integration
- No external dependencies
- Built-in connection pooling
- Automatic retries
- Easy deployment

**Cons:**
- Limited to Supabase ecosystem
- Deno runtime (not Node.js)

**Cost:** Free tier: 500,000 invocations/month

### Option B: Cloud Function (Firebase/AWS Lambda)

**Pros:**
- More flexible runtime
- Better monitoring tools
- Can integrate with other services

**Cons:**
- Need connection pooler setup
- Additional costs
- More complex deployment

### Option C: Background Job Service (Celery/Bull)

**Pros:**
- Full control
- Rich ecosystem
- Advanced scheduling

**Cons:**
- Need server infrastructure
- Higher maintenance
- More complex

### ✅ Decision: **Option A - Supabase Edge Function + pg_cron**

**Rationale:**
- Project already on Supabase
- Simplest to implement & maintain
- Free tier sufficient
- Best integration with existing RLS

---

## 📝 Implementation Steps

### Phase 2.1: Database Enhancements (Week 1, Days 1-2)

#### Step 1.1: Add Tracking Columns
```sql
-- Add generation metadata to task_templates
ALTER TABLE task_templates 
ADD COLUMN last_generated_at TIMESTAMPTZ,
ADD COLUMN next_generation_at TIMESTAMPTZ,
ADD COLUMN generation_count INTEGER DEFAULT 0,
ADD COLUMN generation_errors INTEGER DEFAULT 0,
ADD COLUMN last_error TEXT;

-- Add indexes for performance
CREATE INDEX idx_templates_next_gen 
ON task_templates(next_generation_at) 
WHERE is_active = true;

CREATE INDEX idx_instances_date 
ON recurring_task_instances(generated_date);
```

#### Step 1.2: Add Generation Log Table
```sql
-- Track all generation attempts
CREATE TABLE task_generation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_date DATE NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'running', -- running/success/failed
  templates_processed INTEGER DEFAULT 0,
  tasks_created INTEGER DEFAULT 0,
  errors_count INTEGER DEFAULT 0,
  error_details JSONB,
  execution_time_ms INTEGER,
  triggered_by TEXT DEFAULT 'cron',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_generation_logs_date 
ON task_generation_logs(run_date DESC);
```

#### Step 1.3: Create Helper Functions
```sql
-- Function to check if task should be generated today
CREATE OR REPLACE FUNCTION should_generate_today(
  p_template task_templates
) RETURNS BOOLEAN AS $$
BEGIN
  -- Check if already generated today
  IF EXISTS (
    SELECT 1 FROM recurring_task_instances
    WHERE template_id = p_template.id
      AND generated_date = CURRENT_DATE
  ) THEN
    RETURN FALSE;
  END IF;
  
  -- Check recurrence pattern
  CASE p_template.recurrence_pattern
    WHEN 'daily' THEN
      RETURN TRUE;
    WHEN 'weekly' THEN
      -- Check if today is in scheduled_days (1=Monday, 7=Sunday)
      RETURN EXTRACT(ISODOW FROM CURRENT_DATE) = ANY(p_template.scheduled_days);
    WHEN 'monthly' THEN
      -- Generate on specific days of month
      RETURN EXTRACT(DAY FROM CURRENT_DATE) = ANY(p_template.scheduled_days);
    ELSE
      RETURN FALSE;
  END CASE;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to calculate next generation date
CREATE OR REPLACE FUNCTION calculate_next_generation(
  p_pattern TEXT,
  p_scheduled_days INTEGER[]
) RETURNS DATE AS $$
DECLARE
  v_next_date DATE;
BEGIN
  CASE p_pattern
    WHEN 'daily' THEN
      v_next_date := CURRENT_DATE + INTERVAL '1 day';
    WHEN 'weekly' THEN
      -- Find next scheduled day
      v_next_date := CURRENT_DATE + INTERVAL '1 day';
      WHILE EXTRACT(ISODOW FROM v_next_date) != ANY(p_scheduled_days) LOOP
        v_next_date := v_next_date + INTERVAL '1 day';
      END LOOP;
    WHEN 'monthly' THEN
      -- Find next scheduled day of month
      v_next_date := CURRENT_DATE + INTERVAL '1 day';
      WHILE EXTRACT(DAY FROM v_next_date) != ANY(p_scheduled_days) LOOP
        v_next_date := v_next_date + INTERVAL '1 day';
      END LOOP;
    ELSE
      v_next_date := NULL;
  END CASE;
  
  RETURN v_next_date;
END;
$$ LANGUAGE plpgsql STABLE;
```

### Phase 2.2: Edge Function Development (Week 1, Days 3-5)

#### Step 2.1: Create Edge Function Structure
```bash
# In Supabase project
supabase functions new generate_daily_tasks
```

#### Step 2.2: Implement Main Function
```typescript
// supabase/functions/generate_daily_tasks/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface TaskTemplate {
  id: string
  company_id: string
  branch_id: string
  title: string
  description: string
  category: string
  priority: string
  recurrence_pattern: string
  scheduled_time: string
  assigned_role: string
  auto_assign: boolean
}

interface Employee {
  id: string
  user_id: string
  role: string
  shift: string
}

serve(async (req) => {
  const startTime = Date.now()
  
  try {
    // Initialize Supabase client with service role
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Create generation log
    const { data: log } = await supabase
      .from('task_generation_logs')
      .insert({
        run_date: new Date().toISOString().split('T')[0],
        status: 'running',
      })
      .select()
      .single()

    console.log(`[${new Date().toISOString()}] Starting daily task generation...`)

    // Get all active templates that should generate today
    const { data: templates, error: templatesError } = await supabase
      .from('task_templates')
      .select('*')
      .eq('is_active', true)

    if (templatesError) throw templatesError

    console.log(`Found ${templates.length} active templates`)

    let tasksCreated = 0
    let errorsCount = 0
    const errorDetails: any[] = []

    // Process each template
    for (const template of templates) {
      try {
        // Check if should generate today (using DB function)
        const { data: shouldGenerate } = await supabase.rpc(
          'should_generate_today',
          { p_template: template }
        )

        if (!shouldGenerate) {
          console.log(`Skipping template ${template.id} - already generated or not scheduled`)
          continue
        }

        // Generate task
        const result = await generateTaskFromTemplate(supabase, template)
        
        if (result.success) {
          tasksCreated++
          console.log(`✓ Created task from template ${template.id}`)
        } else {
          errorsCount++
          errorDetails.push({
            template_id: template.id,
            error: result.error
          })
          console.error(`✗ Failed to create task from template ${template.id}:`, result.error)
        }

      } catch (error) {
        errorsCount++
        errorDetails.push({
          template_id: template.id,
          error: error.message
        })
        console.error(`Error processing template ${template.id}:`, error)
      }
    }

    const executionTime = Date.now() - startTime

    // Update log
    await supabase
      .from('task_generation_logs')
      .update({
        completed_at: new Date().toISOString(),
        status: errorsCount > 0 ? 'partial_success' : 'success',
        templates_processed: templates.length,
        tasks_created: tasksCreated,
        errors_count: errorsCount,
        error_details: errorsCount > 0 ? errorDetails : null,
        execution_time_ms: executionTime,
      })
      .eq('id', log.id)

    console.log(`Generation complete: ${tasksCreated} tasks created, ${errorsCount} errors, ${executionTime}ms`)

    return new Response(
      JSON.stringify({
        success: true,
        templates_processed: templates.length,
        tasks_created: tasksCreated,
        errors_count: errorsCount,
        execution_time_ms: executionTime,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Fatal error:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})
```

#### Step 2.3: Implement Task Generation Logic
```typescript
// supabase/functions/generate_daily_tasks/task-generator.ts
async function generateTaskFromTemplate(
  supabase: any,
  template: TaskTemplate
): Promise<{ success: boolean; error?: string }> {
  try {
    // 1. Find employee by role
    const employee = await findBestEmployee(supabase, {
      companyId: template.company_id,
      branchId: template.branch_id,
      role: template.assigned_role,
      autoAssign: template.auto_assign,
    })

    if (!employee) {
      return { 
        success: false, 
        error: `No available employee with role ${template.assigned_role}` 
      }
    }

    // 2. Calculate due date
    const dueDate = calculateDueDate(template.scheduled_time)

    // 3. Create task
    const { data: task, error: taskError } = await supabase
      .from('tasks')
      .insert({
        company_id: template.company_id,
        branch_id: template.branch_id,
        title: template.title,
        description: template.description,
        category: template.category,
        priority: template.priority,
        assigned_to: employee.user_id,
        due_date: dueDate,
        status: 'pending',
        created_from_template: true,
        template_id: template.id,
      })
      .select()
      .single()

    if (taskError) throw taskError

    // 4. Track instance
    await supabase
      .from('recurring_task_instances')
      .insert({
        template_id: template.id,
        task_id: task.id,
        generated_date: new Date().toISOString().split('T')[0],
        status: 'generated',
      })

    // 5. Update template metadata
    await supabase
      .from('task_templates')
      .update({
        last_generated_at: new Date().toISOString(),
        generation_count: template.generation_count + 1,
        next_generation_at: calculateNextGeneration(
          template.recurrence_pattern,
          template.scheduled_days
        ),
      })
      .eq('id', template.id)

    return { success: true }

  } catch (error) {
    return { 
      success: false, 
      error: error.message 
    }
  }
}

// Smart employee assignment
async function findBestEmployee(
  supabase: any,
  params: {
    companyId: string
    branchId: string
    role: string
    autoAssign: boolean
  }
): Promise<Employee | null> {
  // 1. Get employees with matching role
  const { data: employees } = await supabase
    .from('employees')
    .select('*')
    .eq('company_id', params.companyId)
    .eq('role', params.role)
    .eq('status', 'active')

  if (!employees || employees.length === 0) {
    return null
  }

  // 2. Filter by current shift
  const currentShift = getCurrentShift()
  let onShiftEmployees = employees.filter(e => e.shift === currentShift)

  // 3. If no one on current shift, use all employees
  if (onShiftEmployees.length === 0) {
    onShiftEmployees = employees
  }

  // 4. Load balancing - find employee with least pending tasks
  const employeeLoads = await Promise.all(
    onShiftEmployees.map(async (e) => {
      const { count } = await supabase
        .from('tasks')
        .select('*', { count: 'exact', head: true })
        .eq('assigned_to', e.user_id)
        .in('status', ['pending', 'in_progress'])

      return { employee: e, taskCount: count ?? 0 }
    })
  )

  // 5. Return employee with least tasks
  employeeLoads.sort((a, b) => a.taskCount - b.taskCount)
  return employeeLoads[0].employee
}

function getCurrentShift(): string {
  const hour = new Date().getHours()
  
  if (hour >= 6 && hour < 14) return 'morning'
  if (hour >= 14 && hour < 22) return 'afternoon'
  return 'night'
}

function calculateDueDate(scheduledTime: string): string {
  const today = new Date()
  const [hours, minutes] = scheduledTime.split(':').map(Number)
  
  today.setHours(hours, minutes, 0, 0)
  
  return today.toISOString()
}

function calculateNextGeneration(pattern: string, scheduledDays: number[]): string {
  // Implementation matches SQL function
  let nextDate = new Date()
  nextDate.setDate(nextDate.getDate() + 1)
  
  switch (pattern) {
    case 'daily':
      break
    case 'weekly':
      while (!scheduledDays.includes(nextDate.getDay() || 7)) {
        nextDate.setDate(nextDate.getDate() + 1)
      }
      break
    case 'monthly':
      while (!scheduledDays.includes(nextDate.getDate())) {
        nextDate.setDate(nextDate.getDate() + 1)
      }
      break
  }
  
  return nextDate.toISOString()
}
```

### Phase 2.3: Cron Job Setup (Week 2, Days 1-2)

#### Step 3.1: Enable pg_cron Extension
```sql
-- In Supabase SQL Editor
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant permissions
GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;
```

#### Step 3.2: Create Cron Job
```sql
-- Schedule to run daily at 00:00 (midnight)
SELECT cron.schedule(
  'generate-daily-tasks',
  '0 0 * * *',  -- Every day at midnight
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate_daily_tasks',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    )
  ) as request_id;
  $$
);

-- Verify cron job created
SELECT * FROM cron.job;

-- View cron job history
SELECT * FROM cron.job_run_details 
ORDER BY start_time DESC 
LIMIT 10;
```

#### Step 3.3: Create Manual Trigger Function (for testing)
```sql
-- Function to manually trigger generation
CREATE OR REPLACE FUNCTION trigger_task_generation()
RETURNS JSONB AS $$
DECLARE
  v_response JSONB;
BEGIN
  SELECT content::JSONB INTO v_response
  FROM net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate_daily_tasks',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  
  RETURN v_response;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Usage: SELECT trigger_task_generation();
```

### Phase 2.4: UI Enhancements (Week 2, Days 3-5)

#### Step 4.1: Add Templates Management Page
```dart
// lib/pages/ceo/company/templates_tab.dart
class TemplatesTab extends ConsumerWidget {
  final Company company;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(companyTaskTemplatesProvider(company.id));
    
    return Column(
      children: [
        // Header with stats
        _buildHeader(templatesAsync),
        
        // Filters
        _buildFilters(),
        
        // Templates list
        Expanded(
          child: templatesAsync.when(
            data: (templates) => _buildTemplatesList(templates),
            loading: () => CircularProgressIndicator(),
            error: (e, s) => ErrorWidget(e),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTemplatesList(List<TaskTemplate> templates) {
    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return TemplateCard(
          template: template,
          onToggle: () => _toggleTemplate(template),
          onEdit: () => _editTemplate(template),
          onDelete: () => _deleteTemplate(template),
        );
      },
    );
  }
}
```

#### Step 4.2: Add Template Card Widget
```dart
// lib/widgets/template_card.dart
class TemplateCard extends StatelessWidget {
  final TaskTemplate template;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          template.isActive ? Icons.check_circle : Icons.cancel,
          color: template.isActive ? Colors.green : Colors.grey,
        ),
        title: Text(template.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${template.recurrencePattern.name} at ${template.scheduledTime}'),
            if (template.lastGeneratedAt != null)
              Text('Last: ${_formatDate(template.lastGeneratedAt)}'),
            Text('Generated: ${template.generationCount} times'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active/Inactive toggle
            Switch(
              value: template.isActive,
              onChanged: (_) => onToggle(),
            ),
            // More options menu
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text('Edit'),
                  onTap: onEdit,
                ),
                PopupMenuItem(
                  child: Text('Delete'),
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Step 4.3: Add Generation Log Viewer
```dart
// lib/pages/ceo/company/generation_logs_page.dart
class GenerationLogsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(generationLogsProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Task Generation Logs')),
      body: logsAsync.when(
        data: (logs) => ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return LogCard(log: log);
          },
        ),
        loading: () => CircularProgressIndicator(),
        error: (e, s) => ErrorWidget(e),
      ),
    );
  }
}
```

### Phase 2.5: Testing (Week 3, Days 1-3)

#### Test Suite 1: Unit Tests
```typescript
// tests/task-generator.test.ts
Deno.test('should generate daily task', async () => {
  const template = createMockTemplate('daily')
  const result = await generateTaskFromTemplate(supabase, template)
  
  assertEquals(result.success, true)
})

Deno.test('should respect weekly schedule', async () => {
  const template = createMockTemplate('weekly', [1, 3, 5]) // Mon, Wed, Fri
  const shouldGenerate = await shouldGenerateToday(template)
  
  const dayOfWeek = new Date().getDay()
  assertEquals(shouldGenerate, [1, 3, 5].includes(dayOfWeek))
})

Deno.test('should not create duplicate tasks', async () => {
  const template = createMockTemplate('daily')
  
  // Generate first task
  await generateTaskFromTemplate(supabase, template)
  
  // Try to generate again
  const result = await generateTaskFromTemplate(supabase, template)
  assertEquals(result.success, false)
})
```

#### Test Suite 2: Integration Tests
```bash
# Test manual trigger
curl -X POST \
  https://YOUR_PROJECT.supabase.co/functions/v1/generate_daily_tasks \
  -H "Authorization: Bearer YOUR_ANON_KEY"

# Verify results
psql -c "SELECT * FROM task_generation_logs ORDER BY created_at DESC LIMIT 1;"
psql -c "SELECT COUNT(*) FROM tasks WHERE created_at > NOW() - INTERVAL '1 hour';"
```

#### Test Suite 3: Load Tests
```typescript
// tests/load-test.ts
// Simulate 100 templates generation
for (let i = 0; i < 100; i++) {
  await createTemplate({
    recurrence_pattern: 'daily',
    is_active: true,
  })
}

// Measure execution time
const start = Date.now()
await triggerGeneration()
const executionTime = Date.now() - start

console.log(`Generated 100 tasks in ${executionTime}ms`)
assert(executionTime < 5000, 'Should complete in < 5 seconds')
```

### Phase 2.6: Deployment (Week 3, Days 4-5)

#### Step 6.1: Deploy Edge Function
```bash
# Deploy to Supabase
supabase functions deploy generate_daily_tasks

# Set secrets
supabase secrets set SUPABASE_URL=https://xxx.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=xxx

# Verify deployment
supabase functions list
```

#### Step 6.2: Enable Cron Job (Production)
```sql
-- Run in production database
SELECT cron.schedule(
  'generate-daily-tasks-prod',
  '0 0 * * *',
  $$
  SELECT net.http_post(
    url := 'https://dqddxowyikefqcdiioyh.supabase.co/functions/v1/generate_daily_tasks',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  $$
);
```

#### Step 6.3: Setup Monitoring
```sql
-- Create alert function
CREATE OR REPLACE FUNCTION check_generation_failures()
RETURNS VOID AS $$
DECLARE
  v_failures INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_failures
  FROM task_generation_logs
  WHERE run_date = CURRENT_DATE
    AND status = 'failed';
  
  IF v_failures > 0 THEN
    -- Send notification (integrate with external service)
    PERFORM net.http_post(
      url := 'YOUR_ALERT_WEBHOOK',
      body := jsonb_build_object(
        'message', format('Task generation failed %s times today', v_failures)
      )
    );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Schedule alert check (every hour)
SELECT cron.schedule(
  'check-generation-failures',
  '0 * * * *',
  'SELECT check_generation_failures()'
);
```

---

## 📊 Testing Strategy

### Phase 1: Development Testing
- [ ] Unit tests for each function
- [ ] Mock Supabase client
- [ ] Test edge cases (no employees, no templates, etc.)

### Phase 2: Staging Testing
- [ ] Deploy to staging environment
- [ ] Create test templates
- [ ] Verify cron execution
- [ ] Check task generation accuracy
- [ ] Test error handling

### Phase 3: Production Testing
- [ ] Soft launch (1 company)
- [ ] Monitor logs for 1 week
- [ ] Gradual rollout
- [ ] Full deployment

### Test Checklist
```markdown
- [ ] Daily tasks generate at correct time
- [ ] Weekly tasks only on scheduled days
- [ ] Monthly tasks only on scheduled days
- [ ] No duplicate tasks created
- [ ] Correct employee assignment
- [ ] Load balancing works
- [ ] Inactive templates are skipped
- [ ] Templates are created
- [ ] Errors are logged
- [ ] Execution time < 5 seconds
- [ ] Cron job runs reliably
```

---

## 🚀 Deployment Plan

### Pre-Deployment
1. Code review
2. Security audit
3. Performance testing
4. Documentation complete

### Deployment Steps
1. **Day 1**: Deploy to staging
2. **Day 2-7**: Staging testing
3. **Day 8**: Deploy to production (disabled)
4. **Day 9-10**: Manual testing in production
5. **Day 11**: Enable cron job
6. **Day 11-17**: Monitor closely
7. **Day 18+**: Normal operations

### Rollback Plan
```sql
-- Disable cron job
SELECT cron.unschedule('generate-daily-tasks-prod');

-- Mark all tasks as manual
UPDATE tasks 
SET created_from_template = false
WHERE created_at > 'DEPLOYMENT_DATE';
```

---

## 📈 Monitoring & Maintenance

### Daily Checks
```sql
-- Check today's generation
SELECT * FROM task_generation_logs 
WHERE run_date = CURRENT_DATE;

-- Check errors
SELECT * FROM task_generation_logs 
WHERE status = 'failed' 
  AND run_date >= CURRENT_DATE - 7;

-- Check task counts
SELECT 
  t.title,
  COUNT(ri.id) as generated_count,
  t.generation_count
FROM task_templates t
LEFT JOIN recurring_task_instances ri ON t.id = ri.template_id
WHERE t.is_active = true
GROUP BY t.id;
```

### Weekly Reports
```sql
-- Generation success rate
SELECT 
  DATE_TRUNC('week', run_date) as week,
  COUNT(*) as total_runs,
  SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as successful,
  AVG(tasks_created) as avg_tasks_created,
  AVG(execution_time_ms) as avg_execution_time
FROM task_generation_logs
WHERE run_date >= CURRENT_DATE - 30
GROUP BY week
ORDER BY week DESC;
```

### Alerting Rules
1. **Generation Failure**: Alert if status = 'failed'
2. **Slow Execution**: Alert if execution_time_ms > 10000
3. **Zero Tasks**: Alert if tasks_created = 0 and templates exist
4. **High Error Rate**: Alert if errors_count > tasks_created * 0.1

---

## 💰 Cost Estimation

### Supabase Costs (Free Tier)
- Edge Functions: 500k invocations/month (1/day = 30/month) ✅ FREE
- Database: < 500MB (logs + instances) ✅ FREE
- pg_cron: Built-in ✅ FREE

### Estimated Monthly Cost: **$0** (within free tier)

### Upgrade Threshold
- Edge Functions: > 16,000 invocations/day
- Database: > 500MB storage
- Compute: > 500 hours/month

---

## 📚 Documentation Deliverables

1. ✅ This implementation plan
2. ⏳ API documentation for Edge Function
3. ⏳ Database schema documentation
4. ⏳ Admin guide for template management
5. ⏳ Troubleshooting guide
6. ⏳ Runbook for common issues

---

## 🎯 Success Criteria

### Technical
- ✅ 100% test coverage
- ✅ < 5 seconds execution time
- ✅ 0% duplicate tasks
- ✅ 99.9% uptime

### Business
- ✅ 80% time savings confirmed
- ✅ Positive user feedback
- ✅ No manual intervention needed
- ✅ Scalable to 100+ companies

---

## 📅 Timeline Summary

| Week | Phase | Tasks | Status |
|------|-------|-------|--------|
| 1 | Database & Edge Function | Steps 1.1-2.3 | TODO |
| 2 | Cron & UI | Steps 3.1-4.3 | TODO |
| 3 | Testing & Deployment | Steps 5.1-6.3 | TODO |

**Total Duration**: 3 weeks  
**Start Date**: TBD  
**Target Completion**: TBD

---

## 🚦 Go/No-Go Checklist

Before proceeding to Phase 2, verify:

- [x] Phase 1 is 100% complete
- [x] Database has task_templates table
- [x] UI can create templates
- [x] Users can generate templates from AI
- [x] Documentation is complete
- [x] Budget approved
- [x] Resources allocated
- [ ] Stakeholder sign-off

**Status**: ✅ READY TO START PHASE 2

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-04  
**Author**: GitHub Copilot  
**Reviewers**: TBD
