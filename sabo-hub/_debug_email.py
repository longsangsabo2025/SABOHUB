"""
Debug email system - check triggers, logs, and test send
"""
import psycopg2
import requests
import json

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

print("=" * 60)
print("🔍 DEBUG EMAIL SYSTEM")
print("=" * 60)

# 1. Check email triggers
print("\n📋 1. EMAIL TRIGGERS:")
cur.execute("""
    SELECT trigger_name, event_manipulation, action_statement
    FROM information_schema.triggers
    WHERE trigger_name LIKE '%email%'
    ORDER BY trigger_name
""")
triggers = cur.fetchall()
if triggers:
    for t in triggers:
        print(f"  ✅ {t[0]} ({t[1]})")
else:
    print("  ❌ No email triggers found!")

# 2. Check email log
print("\n📋 2. RECENT EMAIL LOG (task_email_log):")
cur.execute("""
    SELECT * FROM task_email_log ORDER BY sent_at DESC LIMIT 5
""")
logs = cur.fetchall()
if logs:
    for log in logs:
        print(f"  - {log}")
else:
    print("  (empty)")

# 3. Check http_request extension
print("\n📋 3. HTTP EXTENSION:")
cur.execute("""
    SELECT extname FROM pg_extension WHERE extname = 'http'
""")
http_ext = cur.fetchone()
if http_ext:
    print("  ✅ http extension installed")
else:
    print("  ❌ http extension NOT installed!")

# 4. Check net extension (for async requests)
cur.execute("""
    SELECT extname FROM pg_extension WHERE extname = 'pg_net'
""")
net_ext = cur.fetchone()
if net_ext:
    print("  ✅ pg_net extension installed")
else:
    print("  ⚠️ pg_net extension not installed")

# 5. Test Resend API directly from Python
print("\n📋 4. DIRECT RESEND API TEST:")
RESEND_API_KEY = "re_AqAaLdb8_5yarkY2QxJsjKG1eJhwKofWw"
TEST_EMAIL = "ngocdiem1112@gmail.com"

response = requests.post(
    "https://api.resend.com/emails",
    headers={
        "Authorization": f"Bearer {RESEND_API_KEY}",
        "Content-Type": "application/json"
    },
    json={
        "from": "SABOHUB <onboarding@resend.dev>",
        "to": [TEST_EMAIL],
        "subject": "🔔 Test Email từ SABOHUB - Debug",
        "html": """
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px; text-align: center;">
                <h1 style="color: white; margin: 0;">🔔 SABOHUB</h1>
                <p style="color: rgba(255,255,255,0.9); margin-top: 10px;">Test Email - Debug</p>
            </div>
            <div style="padding: 30px; background: #f8f9fa; border-radius: 0 0 10px 10px;">
                <p style="font-size: 16px; color: #333;">Xin chào!</p>
                <p style="color: #666;">Đây là email test từ hệ thống SABOHUB.</p>
                <p style="color: #666;">Nếu bạn nhận được email này, hệ thống email đang hoạt động bình thường.</p>
                <div style="margin-top: 30px; padding: 15px; background: #e8f5e9; border-radius: 8px; border-left: 4px solid #4caf50;">
                    <strong style="color: #2e7d32;">✅ Resend API: OK</strong>
                </div>
            </div>
        </div>
        """
    }
)

print(f"  HTTP Status: {response.status_code}")
print(f"  Response: {response.text}")

if response.status_code == 200:
    print("  ✅ Email sent successfully via Python!")
else:
    print(f"  ❌ Error: {response.status_code}")

# 6. Check what triggers call
print("\n📋 5. TRIGGER FUNCTION CODE (email_notify_task_assignment):")
cur.execute("""
    SELECT prosrc FROM pg_proc WHERE proname = 'email_notify_task_assignment'
""")
func = cur.fetchone()
if func:
    # Just show first 500 chars
    code = func[0][:800] if len(func[0]) > 800 else func[0]
    print(f"  {code}...")
else:
    print("  ❌ Function not found!")

# 7. Check recent tasks to see if triggers fired
print("\n📋 6. RECENT TASKS (last 5):")
cur.execute("""
    SELECT id, title, assigned_to, status, created_at
    FROM tasks
    ORDER BY created_at DESC
    LIMIT 5
""")
tasks = cur.fetchall()
for t in tasks:
    print(f"  - {t[1][:30]}... | status: {t[3]} | {t[4]}")

conn.close()
print("\n" + "=" * 60)
