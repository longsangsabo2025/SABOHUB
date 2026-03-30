"""
Fix email triggers to use pg_net instead of http extension
"""
import psycopg2

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()
conn.autocommit = True

RESEND_API_KEY = "re_AqAaLdb8_5yarkY2QxJsjKG1eJhwKofWw"

print("🔧 FIXING EMAIL TRIGGERS TO USE pg_net")
print("=" * 60)

# 1. Update task assignment trigger
print("\n1️⃣ Updating email_notify_task_assignment...")
cur.execute(f"""
CREATE OR REPLACE FUNCTION email_notify_task_assignment()
RETURNS TRIGGER AS $$
DECLARE
    v_assignee_email TEXT;
    v_assignee_name TEXT;
    v_assigner_name TEXT;
    v_email_html TEXT;
    v_subject TEXT;
    v_request_id BIGINT;
BEGIN
    -- Get assignee info
    SELECT email, full_name INTO v_assignee_email, v_assignee_name 
    FROM employees WHERE id = NEW.assigned_to;
    
    -- Get assigner name
    IF TG_OP = 'INSERT' THEN
        SELECT full_name INTO v_assigner_name FROM employees WHERE id = NEW.created_by;
    ELSE
        SELECT full_name INTO v_assigner_name FROM employees WHERE id = COALESCE(NEW.updated_by, NEW.created_by);
    END IF;
    
    IF v_assigner_name IS NULL THEN v_assigner_name := 'Hệ thống'; END IF;
    IF v_assignee_email IS NULL THEN RETURN NEW; END IF;

    -- Build subject with priority
    v_subject := CASE NEW.priority 
        WHEN 'urgent' THEN '🔴 [KHẨN] ' 
        WHEN 'high' THEN '🟠 [Ưu tiên] ' 
        ELSE '' 
    END || 'Task mới: ' || NEW.title;
    
    -- Generate HTML
    v_email_html := generate_task_assigned_email(
        v_assignee_name, 
        v_assigner_name, 
        NEW.title, 
        COALESCE(NEW.description, ''), 
        NEW.priority, 
        NEW.due_date
    );

    -- Send via pg_net
    SELECT net.http_post(
        url := 'https://api.resend.com/emails',
        headers := jsonb_build_object(
            'Authorization', 'Bearer {RESEND_API_KEY}',
            'Content-Type', 'application/json'
        ),
        body := jsonb_build_object(
            'from', 'SABOHUB <onboarding@resend.dev>',
            'to', ARRAY[v_assignee_email],
            'subject', v_subject,
            'html', v_email_html
        )
    ) INTO v_request_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")
print("   ✅ Done")

# 2. Update task status changed trigger  
print("\n2️⃣ Updating email_notify_task_status_changed...")
cur.execute(f"""
CREATE OR REPLACE FUNCTION email_notify_task_status_changed()
RETURNS TRIGGER AS $$
DECLARE
    v_assignee_email TEXT;
    v_assignee_name TEXT;
    v_email_html TEXT;
    v_subject TEXT;
    v_request_id BIGINT;
BEGIN
    -- Only if status actually changed
    IF OLD.status = NEW.status THEN RETURN NEW; END IF;
    
    SELECT email, full_name INTO v_assignee_email, v_assignee_name 
    FROM employees WHERE id = NEW.assigned_to;
    
    IF v_assignee_email IS NULL THEN RETURN NEW; END IF;
    
    v_subject := '📋 Task "' || NEW.title || '" - ' || NEW.status;
    v_email_html := generate_task_status_email(v_assignee_name, NEW.title, OLD.status, NEW.status);

    SELECT net.http_post(
        url := 'https://api.resend.com/emails',
        headers := jsonb_build_object(
            'Authorization', 'Bearer {RESEND_API_KEY}',
            'Content-Type', 'application/json'
        ),
        body := jsonb_build_object(
            'from', 'SABOHUB <onboarding@resend.dev>',
            'to', ARRAY[v_assignee_email],
            'subject', v_subject,
            'html', v_email_html
        )
    ) INTO v_request_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")
print("   ✅ Done")

# 3. Update task completed trigger
print("\n3️⃣ Updating email_notify_task_completed...")
cur.execute(f"""
CREATE OR REPLACE FUNCTION email_notify_task_completed()
RETURNS TRIGGER AS $$
DECLARE
    v_creator_email TEXT;
    v_creator_name TEXT;
    v_completer_name TEXT;
    v_email_html TEXT;
    v_subject TEXT;
    v_request_id BIGINT;
BEGIN
    IF NEW.status != 'completed' OR OLD.status = 'completed' THEN RETURN NEW; END IF;
    
    SELECT email, full_name INTO v_creator_email, v_creator_name 
    FROM employees WHERE id = NEW.created_by;
    
    SELECT full_name INTO v_completer_name FROM employees WHERE id = NEW.assigned_to;
    
    IF v_creator_email IS NULL THEN RETURN NEW; END IF;
    
    v_subject := '✅ Task hoàn thành: ' || NEW.title;
    v_email_html := generate_task_completed_email(
        v_creator_name, 
        NEW.title, 
        COALESCE(v_completer_name, 'Unknown'),
        NEW.created_at,
        NOW()
    );

    SELECT net.http_post(
        url := 'https://api.resend.com/emails',
        headers := jsonb_build_object(
            'Authorization', 'Bearer {RESEND_API_KEY}',
            'Content-Type', 'application/json'
        ),
        body := jsonb_build_object(
            'from', 'SABOHUB <onboarding@resend.dev>',
            'to', ARRAY[v_creator_email],
            'subject', v_subject,
            'html', v_email_html
        )
    ) INTO v_request_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")
print("   ✅ Done")

# 4. Update overdue check function
print("\n4️⃣ Updating check_overdue_tasks...")
cur.execute(f"""
CREATE OR REPLACE FUNCTION check_overdue_tasks()
RETURNS void AS $$
DECLARE
    v_task RECORD;
    v_assignee_email TEXT;
    v_assignee_name TEXT;
    v_email_html TEXT;
    v_days_overdue INTEGER;
    v_request_id BIGINT;
BEGIN
    FOR v_task IN 
        SELECT * FROM tasks 
        WHERE status NOT IN ('completed', 'cancelled')
        AND due_date < CURRENT_DATE
        AND assigned_to IS NOT NULL
    LOOP
        -- Check if already notified today
        IF EXISTS(
            SELECT 1 FROM task_email_log 
            WHERE task_id = v_task.id 
            AND email_type = 'overdue' 
            AND sent_date = CURRENT_DATE
        ) THEN
            CONTINUE;
        END IF;
        
        SELECT email, full_name INTO v_assignee_email, v_assignee_name 
        FROM employees WHERE id = v_task.assigned_to;
        
        IF v_assignee_email IS NULL THEN CONTINUE; END IF;
        
        v_days_overdue := CURRENT_DATE - v_task.due_date;
        v_email_html := generate_task_overdue_email(
            v_assignee_name, 
            v_task.title, 
            v_task.due_date, 
            v_days_overdue
        );

        SELECT net.http_post(
            url := 'https://api.resend.com/emails',
            headers := jsonb_build_object(
                'Authorization', 'Bearer {RESEND_API_KEY}',
                'Content-Type', 'application/json'
            ),
            body := jsonb_build_object(
                'from', 'SABOHUB <onboarding@resend.dev>',
                'to', ARRAY[v_assignee_email],
                'subject', '🔴 [QUÁ HẠN] ' || v_task.title,
                'html', v_email_html
            )
        ) INTO v_request_id;
        
        -- Log
        INSERT INTO task_email_log (task_id, email_type) 
        VALUES (v_task.id, 'overdue');
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")
print("   ✅ Done")

print("\n" + "=" * 60)
print("✅ ALL TRIGGERS UPDATED to use pg_net!")

# Test by creating a task
print("\n🧪 TESTING: Creating a new task to trigger email...")
cur.execute("""
    SELECT id FROM employees WHERE email IS NOT NULL LIMIT 1
""")
emp = cur.fetchone()
if emp:
    emp_id = emp[0]
    cur.execute(f"""
        INSERT INTO tasks (title, description, priority, status, assigned_to, created_by, due_date)
        VALUES (
            'Test Email pg_net - ' || NOW()::TEXT,
            'Testing email notification với pg_net extension',
            'high',
            'pending',
            '{emp_id}',
            '{emp_id}',
            CURRENT_DATE + 3
        )
        RETURNING id
    """)
    task_id = cur.fetchone()[0]
    print(f"   ✅ Task created: {task_id}")
    print(f"   📧 Email should be sent to the assigned employee")
else:
    print("   ❌ No employee found for test")

conn.close()
print("\n🎉 Done! Check inbox in 1-2 minutes.")
