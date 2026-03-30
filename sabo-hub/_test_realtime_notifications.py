"""
Test Supabase Realtime Notifications
=====================================
Gửi thử 5 loại notification khác nhau trực tiếp vào DB.
Mở app trước, đăng nhập → chạy script này → xem toast + bell badge.

Cách chạy:
  .venv-2\Scripts\python.exe _test_realtime_notifications.py
  hoặc chọn user_id từ danh sách bên dưới
"""

import psycopg2
import uuid
import time
from datetime import datetime

# --- DB Config ---
DB = dict(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123",
)

def connect():
    return psycopg2.connect(**DB)

def get_employees(cur):
    cur.execute("""
        SELECT id, full_name, role
        FROM employees
        WHERE is_active = true
        ORDER BY role, full_name
        LIMIT 20
    """)
    return cur.fetchall()

def insert_notification(cur, user_id: str, type_: str, title: str, message: str, link: str = None, data: dict = None):
    import json
    nid = str(uuid.uuid4())
    cur.execute("""
        INSERT INTO notifications (id, user_id, type, title, message, is_read, created_at, link, data)
        VALUES (%s, %s, %s, %s, %s, false, NOW(), %s, %s)
    """, (
        nid,
        user_id,
        type_,
        title,
        message,
        link,
        json.dumps(data) if data else None,
    ))
    return nid

# --- Test Cases ---
TEST_CASES = [
    {
        "label": "📋 Task mới được giao",
        "type": "task_assigned",
        "title": "Bạn có task mới",
        "message": "Kiểm tra kho hàng cuối ngày — Deadline: hôm nay 18:00",
        "link": "/tasks",
        "data": {"task_id": "test-001", "priority": "high"},
        "delay": 2,
    },
    {
        "label": "⏰ Task sắp quá hạn",
        "type": "task_overdue",
        "title": "Task sắp quá hạn!",
        "message": "Còn 30 phút: Cập nhật báo cáo doanh thu tuần",
        "link": "/tasks",
        "data": {"task_id": "test-002"},
        "delay": 5,
    },
    {
        "label": "✅ Task hoàn thành",
        "type": "task_completed",
        "title": "Task đã hoàn thành",
        "message": "Nhân viên Minh đã hoàn thành: Vệ sinh khu vực bàn billiards",
        "link": "/tasks",
        "data": {"task_id": "test-003", "completed_by": "Minh"},
        "delay": 5,
    },
    {
        "label": "✅ Yêu cầu phê duyệt",
        "type": "approval_request",
        "title": "Cần phê duyệt",
        "message": "Nhân viên Lan xin nghỉ phép ngày 20/03 — cần duyệt",
        "link": "/approvals",
        "data": {"request_type": "leave", "employee": "Lan"},
        "delay": 5,
    },
    {
        "label": "📢 Thông báo hệ thống",
        "type": "system",
        "title": "Cập nhật hệ thống",
        "message": "SABOHUB v1.4.2 — Tính năng Realtime đã hoạt động ✅",
        "link": None,
        "data": {"version": "1.4.2"},
        "delay": 5,
    },
]

def main():
    conn = connect()
    cur = conn.cursor()
    conn.autocommit = True  # important: commit immediately so realtime picks up

    print("=" * 60)
    print("  SABOHUB — Realtime Notification Test")
    print("=" * 60)

    # List employees
    employees = get_employees(cur)
    if not employees:
        print("❌ Không có nhân viên nào trong DB!")
        return

    print("\n📋 Danh sách nhân viên (is_active = true):")
    for i, (eid, fname, role) in enumerate(employees):
        print(f"  [{i}] {fname:30s}  role={role:15s}  id={eid}")

    print("\nChọn employee để gửi test notifications:")
    print("  Nhập số thứ tự (0-based), hoặc Enter để dùng employee đầu tiên: ", end="")
    choice = input().strip()
    idx = int(choice) if choice.isdigit() else 0
    idx = max(0, min(idx, len(employees) - 1))

    target_id, target_name, target_role = employees[idx]
    print(f"\n✅ Target: {target_name} ({target_role})")
    print(f"   ID: {target_id}")
    print(f"\n⚡ MỞ APP, đăng nhập với tài khoản '{target_name}' trước khi tiếp tục.")
    print("   Nhấn Enter khi đã sẵn sàng...")
    input()

    print("\n🚀 Bắt đầu gửi test notifications...\n")

    for i, tc in enumerate(TEST_CASES, 1):
        print(f"[{i}/{len(TEST_CASES)}] {tc['label']}")
        print(f"       type: {tc['type']}")
        print(f"       title: {tc['title']}")
        print(f"       message: {tc['message']}")

        nid = insert_notification(
            cur,
            user_id=target_id,
            type_=tc["type"],
            title=tc["title"],
            message=tc["message"],
            link=tc.get("link"),
            data=tc.get("data"),
        )
        print(f"       ✅ Inserted: {nid}")

        if i < len(TEST_CASES):
            delay = tc["delay"]
            print(f"       ⏳ Chờ {delay}s trước notification tiếp theo...\n")
            time.sleep(delay)

    print("\n" + "=" * 60)
    print("✅ Xong! Kiểm tra:")
    print("   1. Toast popup xuất hiện ở góc trên app (4 giây mỗi cái)")
    print("   2. Bell icon có badge count tăng lên")
    print("   3. Tap bell → xem danh sách notifications")
    print("=" * 60)

    # Verify inserted
    cur.execute(
        "SELECT type, title, is_read, created_at FROM notifications WHERE user_id = %s ORDER BY created_at DESC LIMIT 10",
        (target_id,)
    )
    print(f"\n📋 10 notifications gần nhất của {target_name}:")
    for row in cur.fetchall():
        read = "✅" if row[2] else "🔴"
        print(f"  {read} [{row[0]:25s}] {row[1]}")

    conn.close()

if __name__ == "__main__":
    main()
