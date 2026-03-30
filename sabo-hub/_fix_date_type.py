"""
Fix date type casting in email triggers
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

print("🔧 FIXING DATE TYPE IN TRIGGERS")
print("=" * 60)

# Check if generate functions exist
print("\n1️⃣ Checking email template functions...")
cur.execute("""
    SELECT proname FROM pg_proc WHERE proname LIKE 'generate_%email%'
""")
funcs = cur.fetchall()
print(f"   Found: {[f[0] for f in funcs]}")

# Fix assignment trigger with proper date casting
print("\n2️⃣ Fixing email_notify_task_assignment with DATE cast...")
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
    SELECT email, full_name INTO v_assignee_email, v_assignee_name 
    FROM employees WHERE id = NEW.assigned_to;
    
    IF TG_OP = 'INSERT' THEN
        SELECT full_name INTO v_assigner_name FROM employees WHERE id = NEW.created_by;
    ELSE
        SELECT full_name INTO v_assigner_name FROM employees WHERE id = COALESCE(NEW.updated_by, NEW.created_by);
    END IF;
    
    IF v_assigner_name IS NULL THEN v_assigner_name := 'Hệ thống'; END IF;
    IF v_assignee_email IS NULL THEN RETURN NEW; END IF;

    v_subject := CASE NEW.priority 
        WHEN 'urgent' THEN '🔴 [KHẨN] ' 
        WHEN 'high' THEN '🟠 [Ưu tiên] ' 
        ELSE '' 
    END || 'Task mới: ' || NEW.title;
    
    v_email_html := generate_task_assigned_email(
        v_assignee_name, 
        v_assigner_name, 
        NEW.title, 
        COALESCE(NEW.description, ''), 
        NEW.priority, 
        NEW.due_date::DATE  -- Cast to DATE
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
            'subject', v_subject,
            'html', v_email_html
        )
    ) INTO v_request_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")
print("   ✅ Done")

# Test with a simple task
print("\n3️⃣ Testing with new task...")
cur.execute("""
    SELECT id, email FROM employees WHERE email IS NOT NULL LIMIT 1
""")
emp = cur.fetchone()
if emp:
    emp_id = emp[0]
    emp_email = emp[1]
    print(f"   Employee: {emp_email}")
    
    cur.execute(f"""
        INSERT INTO tasks (title, description, priority, status, assigned_to, created_by, due_date)
        VALUES (
            'Test pg_net trigger ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
            'Testing email từ trigger với pg_net',
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
    print(f"   📧 Email should be sent to: {emp_email}")

# Check pg_net queue
print("\n4️⃣ Checking pg_net queue...")
try:
    cur.execute("""
        SELECT id, url, status, created 
        FROM net._http_response 
        ORDER BY created DESC 
        LIMIT 5
    """)
    responses = cur.fetchall()
    if responses:
        print("   Recent HTTP responses:")
        for r in responses:
            print(f"     ID:{r[0]} Status:{r[2]} Created:{r[3]}")
    else:
        print("   (no responses yet - may take a moment)")
except Exception as e:
    print(f"   ⚠️ Cannot check queue: {e}")

conn.close()
print("\n" + "=" * 60)
print("🎉 Check your email in 1-2 minutes!")
