"""
Test Supabase Realtime Notifications
- Liệt kê employees active
- Insert thử các loại notification
- Kiểm tra toast popup hiện trên app
"""
import psycopg2
import uuid
import time
from datetime import datetime

DB = dict(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require',
)

def get_conn():
    return psycopg2.connect(**DB)

def list_employees():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        SELECT id, full_name, role, company_id
        FROM employees
        WHERE is_active = true
        ORDER BY role, full_name
        LIMIT 30
    """)
    rows = cur.fetchall()
    conn.close()
    return rows

def send_notification(user_id, title, message, notif_type='info', link=None):
    conn = get_conn()
    cur = conn.cursor()
    notif_id = str(uuid.uuid4())
    cur.execute("""
        INSERT INTO notifications (id, user_id, title, message, type, link, is_read, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, false, NOW())
        RETURNING id
    """, (notif_id, user_id, title, message, notif_type, link))
    conn.commit()
    conn.close()
    return notif_id

TEST_CASES = [
    {
        'title': '📋 Task mới được giao',
        'message': 'Bạn có task mới: "Kiểm tra kho hàng tháng 3"',
        'type': 'task_assigned',
        'delay': 2,
    },
    {
        'title': '✅ Task hoàn thành',
        'message': 'Task "Báo cáo doanh thu" đã được đánh dấu hoàn thành',
        'type': 'task_completed',
        'delay': 3,
    },
    {
        'title': '⚠️ Task quá hạn',
        'message': 'Task "Đối soát công nợ" đã quá hạn 2 ngày!',
        'type': 'task_overdue',
        'delay': 3,
    },
    {
        'title': '🔔 Nhắc ca làm việc',
        'message': 'Ca sáng bắt đầu lúc 08:00. Hãy chấm công đúng giờ.',
        'type': 'shift_reminder',
        'delay': 3,
    },
    {
        'title': '📢 Thông báo hệ thống',
        'message': 'Hệ thống sẽ bảo trì từ 23:00–01:00 đêm nay.',
        'type': 'system',
        'delay': 3,
    },
    {
        'title': '✔️ Phê duyệt yêu cầu',
        'message': 'Yêu cầu nghỉ phép của bạn đã được phê duyệt.',
        'type': 'approval_update',
        'delay': 3,
    },
]

if __name__ == '__main__':
    print('=' * 55)
    print('  SABOHUB — Realtime Notification Test')
    print('=' * 55)

    employees = list_employees()
    if not employees:
        print('❌ Không có employee nào!')
        exit(1)

    print(f'\n📋 Employees active ({len(employees)}):')
    for i, (eid, name, role, cid) in enumerate(employees):
        print(f'  {i+1:2}. [{role:12}] {name}')

    print()
    choice = input('Chọn số thứ tự employee để test (hoặc Enter = chọn #1): ').strip()
    idx = (int(choice) - 1) if choice.isdigit() else 0
    idx = max(0, min(idx, len(employees) - 1))

    target_id, target_name, target_role, _ = employees[idx]
    print(f'\n🎯 Target: {target_name} ({target_role})')
    print(f'   ID: {target_id}')
    print()
    print('💡 Mở app và đăng nhập bằng account này trước khi tiếp tục.')
    input('   Nhấn Enter khi đã sẵn sàng...')
    print()

    sent = []
    for i, tc in enumerate(TEST_CASES):
        print(f'  [{i+1}/{len(TEST_CASES)}] Gửi: {tc["title"]}')
        nid = send_notification(
            user_id=target_id,
            title=tc['title'],
            message=tc['message'],
            notif_type=tc['type'],
        )
        sent.append(nid)
        print(f'       ✅ id={nid[:8]}... → chờ toast trên app...')

        if i < len(TEST_CASES) - 1:
            time.sleep(tc['delay'])

    print()
    print(f'🏁 Đã gửi {len(sent)} notifications.')
    print()

    cleanup = input('Xóa test notifications vừa gửi? (y/N): ').strip().lower()
    if cleanup == 'y':
        conn = get_conn()
        cur = conn.cursor()
        cur.execute('DELETE FROM notifications WHERE id = ANY(%s)', (sent,))
        conn.commit()
        conn.close()
        print(f'🗑️  Đã xóa {len(sent)} records.')
    else:
        print('ℹ️  Giữ lại để xem trong notification bell.')
