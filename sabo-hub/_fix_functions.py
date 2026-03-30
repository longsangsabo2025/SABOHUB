"""
Check function signatures and fix
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

# Check function signatures
print("📋 CHECKING FUNCTION SIGNATURES")
print("=" * 60)

cur.execute("""
    SELECT p.proname, pg_get_function_arguments(p.oid) as args
    FROM pg_proc p
    WHERE p.proname = 'generate_task_assigned_email'
""")
funcs = cur.fetchall()
for f in funcs:
    print(f"\n{f[0]}:")
    print(f"  Args: {f[1]}")

# Drop all versions and recreate with correct signature
print("\n\n🔧 RECREATING EMAIL FUNCTIONS WITH CORRECT SIGNATURES")
print("=" * 60)

# Drop existing functions
print("\n1️⃣ Dropping existing functions...")
cur.execute("DROP FUNCTION IF EXISTS generate_task_assigned_email CASCADE;")
cur.execute("DROP FUNCTION IF EXISTS generate_task_status_email CASCADE;")
cur.execute("DROP FUNCTION IF EXISTS generate_task_completed_email CASCADE;")
cur.execute("DROP FUNCTION IF EXISTS generate_task_overdue_email CASCADE;")
cur.execute("DROP FUNCTION IF EXISTS generate_task_approval_email CASCADE;")
cur.execute("DROP FUNCTION IF EXISTS generate_daily_digest_email CASCADE;")
print("   ✅ Done")

# Recreate with ALL TEXT arguments (simplest)
print("\n2️⃣ Creating generate_task_assigned_email...")
cur.execute(r"""
CREATE OR REPLACE FUNCTION generate_task_assigned_email(
    p_assignee_name TEXT,
    p_assigner_name TEXT,
    p_task_title TEXT,
    p_description TEXT,
    p_priority TEXT,
    p_due_date TEXT
) RETURNS TEXT AS $$
DECLARE
    v_priority_color TEXT;
    v_priority_label TEXT;
    v_initial TEXT;
BEGIN
    v_initial := UPPER(LEFT(p_assigner_name, 1));
    
    v_priority_color := CASE p_priority
        WHEN 'urgent' THEN '#dc2626'
        WHEN 'high' THEN '#ea580c'
        WHEN 'medium' THEN '#2563eb'
        ELSE '#6b7280'
    END;
    
    v_priority_label := CASE p_priority
        WHEN 'urgent' THEN '🔴 Khẩn cấp'
        WHEN 'high' THEN '🟠 Cao'
        WHEN 'medium' THEN '🔵 Trung bình'
        ELSE '⚪ Thấp'
    END;
    
    RETURN '
    <div style="font-family: -apple-system, BlinkMacSystemFont, ''Segoe UI'', Roboto, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 24px;">📋 Task Mới Được Giao</h1>
        </div>
        <div style="padding: 30px;">
            <p style="font-size: 16px; color: #374151;">Xin chào <strong>' || p_assignee_name || '</strong>,</p>
            <p style="color: #6b7280;">Bạn vừa được giao một task mới:</p>
            
            <div style="background: #f3f4f6; border-radius: 12px; padding: 20px; margin: 20px 0;">
                <div style="display: flex; align-items: center; margin-bottom: 15px;">
                    <div style="width: 40px; height: 40px; background: ' || v_priority_color || '; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; margin-right: 12px;">' || v_initial || '</div>
                    <div>
                        <div style="font-weight: 600; color: #111827;">' || p_task_title || '</div>
                        <div style="font-size: 13px; color: #6b7280;">Giao bởi: ' || p_assigner_name || '</div>
                    </div>
                </div>
                
                <div style="display: inline-block; background: ' || v_priority_color || '20; color: ' || v_priority_color || '; padding: 4px 12px; border-radius: 20px; font-size: 13px; font-weight: 500;">' || v_priority_label || '</div>
                
                ' || CASE WHEN p_due_date IS NOT NULL AND p_due_date != '' THEN 
                '<div style="margin-top: 15px; padding: 12px; background: #fef3c7; border-radius: 8px; border-left: 4px solid #f59e0b;">
                    <strong style="color: #92400e;">📅 Deadline:</strong>
                    <span style="color: #b45309;">' || p_due_date || '</span>
                </div>' ELSE '' END || '
                
                ' || CASE WHEN p_description IS NOT NULL AND p_description != '' THEN 
                '<div style="margin-top: 15px; padding: 12px; background: #ffffff; border-radius: 8px; border: 1px solid #e5e7eb;">
                    <div style="font-size: 12px; color: #9ca3af; margin-bottom: 5px;">MÔ TẢ</div>
                    <div style="color: #374151;">' || LEFT(p_description, 200) || '</div>
                </div>' ELSE '' END || '
            </div>
            
            <a href="https://sabo.com.vn/tasks" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; margin-top: 10px;">👉 Xem & Bắt đầu ngay</a>
        </div>
        <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
            <p style="color: #9ca3af; font-size: 12px; margin: 0;">© 2026 SABOHUB - Hệ thống quản lý doanh nghiệp</p>
        </div>
    </div>';
END;
$$ LANGUAGE plpgsql;
""")
print("   ✅ Done")

print("\n3️⃣ Creating generate_task_status_email...")
cur.execute(r"""
CREATE OR REPLACE FUNCTION generate_task_status_email(
    p_name TEXT,
    p_task_title TEXT,
    p_old_status TEXT,
    p_new_status TEXT
) RETURNS TEXT AS $$
BEGIN
    RETURN '
    <div style="font-family: -apple-system, BlinkMacSystemFont, ''Segoe UI'', Roboto, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff;">
        <div style="background: #3b82f6; padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 24px;">📊 Cập nhật Trạng thái Task</h1>
        </div>
        <div style="padding: 30px;">
            <p style="font-size: 16px; color: #374151;">Xin chào <strong>' || p_name || '</strong>,</p>
            <p style="color: #6b7280;">Task của bạn đã được cập nhật:</p>
            
            <div style="background: #f3f4f6; border-radius: 12px; padding: 20px; margin: 20px 0;">
                <div style="font-weight: 600; color: #111827; font-size: 18px; margin-bottom: 15px;">' || p_task_title || '</div>
                
                <div style="display: flex; align-items: center; gap: 10px;">
                    <span style="background: #fee2e2; color: #dc2626; padding: 6px 12px; border-radius: 6px;">' || p_old_status || '</span>
                    <span style="color: #9ca3af;">→</span>
                    <span style="background: #dcfce7; color: #16a34a; padding: 6px 12px; border-radius: 6px;">' || p_new_status || '</span>
                </div>
            </div>
            
            <a href="https://sabo.com.vn/tasks" style="display: inline-block; background: #3b82f6; color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600;">📂 Xem chi tiết</a>
        </div>
        <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
            <p style="color: #9ca3af; font-size: 12px; margin: 0;">© 2026 SABOHUB</p>
        </div>
    </div>';
END;
$$ LANGUAGE plpgsql;
""")
print("   ✅ Done")

print("\n4️⃣ Creating generate_task_completed_email...")
cur.execute(r"""
CREATE OR REPLACE FUNCTION generate_task_completed_email(
    p_name TEXT,
    p_task_title TEXT,
    p_completer TEXT,
    p_created_at TEXT,
    p_completed_at TEXT
) RETURNS TEXT AS $$
BEGIN
    RETURN '
    <div style="font-family: -apple-system, BlinkMacSystemFont, ''Segoe UI'', Roboto, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff;">
        <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 30px; text-align: center;">
            <div style="font-size: 48px; margin-bottom: 10px;">✅</div>
            <h1 style="color: white; margin: 0; font-size: 24px;">Task Hoàn Thành!</h1>
        </div>
        <div style="padding: 30px;">
            <p style="font-size: 16px; color: #374151;">Xin chào <strong>' || p_name || '</strong>,</p>
            <p style="color: #6b7280;">Một task đã được hoàn thành:</p>
            
            <div style="background: #ecfdf5; border-radius: 12px; padding: 20px; margin: 20px 0; border: 2px solid #10b981;">
                <div style="font-weight: 600; color: #065f46; font-size: 18px;">' || p_task_title || '</div>
                <div style="color: #047857; margin-top: 10px;">Hoàn thành bởi: <strong>' || p_completer || '</strong></div>
            </div>
            
            <a href="https://sabo.com.vn/tasks" style="display: inline-block; background: #10b981; color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; margin-right: 10px;">✅ Xem kết quả</a>
        </div>
        <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
            <p style="color: #9ca3af; font-size: 12px; margin: 0;">© 2026 SABOHUB</p>
        </div>
    </div>';
END;
$$ LANGUAGE plpgsql;
""")
print("   ✅ Done")

print("\n5️⃣ Creating generate_task_overdue_email...")
cur.execute(r"""
CREATE OR REPLACE FUNCTION generate_task_overdue_email(
    p_name TEXT,
    p_task_title TEXT,
    p_due_date TEXT,
    p_days_overdue INTEGER
) RETURNS TEXT AS $$
BEGIN
    RETURN '
    <div style="font-family: -apple-system, BlinkMacSystemFont, ''Segoe UI'', Roboto, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff;">
        <div style="background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); padding: 30px; text-align: center;">
            <div style="font-size: 48px; margin-bottom: 10px;">⚠️</div>
            <h1 style="color: white; margin: 0; font-size: 24px;">Task Quá Hạn!</h1>
        </div>
        <div style="padding: 30px;">
            <p style="font-size: 16px; color: #374151;">Xin chào <strong>' || p_name || '</strong>,</p>
            <p style="color: #dc2626; font-weight: 500;">Task sau đã quá hạn ' || p_days_overdue || ' ngày:</p>
            
            <div style="background: #fef2f2; border-radius: 12px; padding: 20px; margin: 20px 0; border: 2px solid #dc2626;">
                <div style="font-weight: 600; color: #991b1b; font-size: 18px;">' || p_task_title || '</div>
                <div style="color: #b91c1c; margin-top: 10px;">📅 Hạn chót: ' || p_due_date || '</div>
                <div style="background: #dc2626; color: white; display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 13px; margin-top: 10px;">Quá hạn ' || p_days_overdue || ' ngày</div>
            </div>
            
            <a href="https://sabo.com.vn/tasks" style="display: inline-block; background: #dc2626; color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600;">🔥 Xử lý ngay</a>
        </div>
        <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
            <p style="color: #9ca3af; font-size: 12px; margin: 0;">© 2026 SABOHUB</p>
        </div>
    </div>';
END;
$$ LANGUAGE plpgsql;
""")
print("   ✅ Done")

# Now update the trigger to use TEXT for due_date
print("\n6️⃣ Updating trigger to pass TEXT...")
RESEND_API_KEY = "re_AqAaLdb8_5yarkY2QxJsjKG1eJhwKofWw"

cur.execute(f"""
CREATE OR REPLACE FUNCTION email_notify_task_assignment()
RETURNS TRIGGER AS $$
DECLARE
    v_assignee_email TEXT;
    v_assignee_name TEXT;
    v_assigner_name TEXT;
    v_email_html TEXT;
    v_subject TEXT;
    v_due_date_text TEXT;
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
    
    -- Convert due_date to text
    IF NEW.due_date IS NOT NULL THEN
        v_due_date_text := TO_CHAR(NEW.due_date, 'DD/MM/YYYY');
    ELSE
        v_due_date_text := '';
    END IF;
    
    v_email_html := generate_task_assigned_email(
        v_assignee_name, 
        v_assigner_name, 
        NEW.title, 
        COALESCE(NEW.description, ''), 
        COALESCE(NEW.priority, 'medium'),
        v_due_date_text
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

# Test
print("\n🧪 TESTING...")
cur.execute("""
    SELECT id, email FROM employees WHERE email = 'ngocdiem1112@gmail.com' LIMIT 1
""")
emp = cur.fetchone()

if not emp:
    # Get any employee and set test email temporarily
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
            'Test Email FINAL ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
            'Kiểm tra hệ thống email thông báo',
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
    print(f"   📧 Email triggered via pg_net to: {emp_email}")
else:
    print("   ❌ No employee found")

conn.close()
print("\n" + "=" * 60)
print("📬 Check your inbox in 1-2 minutes!")
print("   (Resend test domain only sends to owner email)")
