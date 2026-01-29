"""
Check Manager Diễm's permissions
"""
import psycopg2
import os
import json
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

# Get Manager Diễm's permissions
cur.execute("""
    SELECT 
        e.full_name as manager_name,
        mp.can_view_overview,
        mp.can_view_employees,
        mp.can_view_tasks,
        mp.can_view_documents,
        mp.can_view_ai_assistant,
        mp.can_view_attendance,
        mp.can_view_accounting,
        mp.can_view_employee_docs,
        mp.can_view_business_law,
        mp.can_view_settings,
        mp.can_create_employee,
        mp.can_edit_employee,
        mp.can_delete_employee,
        mp.can_create_task,
        mp.can_edit_task,
        mp.can_delete_task,
        mp.can_approve_attendance,
        mp.can_edit_company_info
    FROM manager_permissions mp
    JOIN employees e ON mp.manager_id = e.id
    WHERE e.full_name LIKE '%Diễm%'
""")

result = cur.fetchone()

if result:
    print("=" * 60)
    print(f"PERMISSIONS FOR MANAGER: {result[0]}")
    print("=" * 60)
    
    # Tab permissions
    print("\n📋 TAB PERMISSIONS:")
    tabs = [
        ("Tổng quan", result[1]),
        ("Nhân viên", result[2]),
        ("Công việc", result[3]),
        ("Tài liệu", result[4]),
        ("AI Assistant", result[5]),
        ("Chấm công", result[6]),
        ("Kế toán", result[7]),
        ("Hồ sơ NV", result[8]),
        ("Luật kinh doanh", result[9]),
        ("Cài đặt", result[10]),
    ]
    
    for tab_name, has_access in tabs:
        status = "✅ CÓ" if has_access else "❌ KHÔNG"
        print(f"   {status} - {tab_name}")
    
    # Action permissions
    print("\n⚡ ACTION PERMISSIONS:")
    actions = [
        ("Thêm nhân viên", result[11]),
        ("Sửa nhân viên", result[12]),
        ("Xóa nhân viên", result[13]),
        ("Thêm công việc", result[14]),
        ("Sửa công việc", result[15]),
        ("Xóa công việc", result[16]),
        ("Duyệt chấm công", result[17]),
        ("Sửa thông tin công ty", result[18]),
    ]
    
    for action_name, has_access in actions:
        status = "✅ CÓ" if has_access else "❌ KHÔNG"
        print(f"   {status} - {action_name}")
    
    # Count total permissions
    total_tabs = sum(1 for _, val in tabs if val)
    total_actions = sum(1 for _, val in actions if val)
    
    print("\n" + "=" * 60)
    print(f"TỔNG KẾT: {total_tabs}/10 tabs, {total_actions}/8 actions")
    print("=" * 60)
    
    if total_tabs == 10 and total_actions == 8:
        print("\n🎉 TOÀN QUYỀN! Manager Diễm đã được cấp đầy đủ 18 quyền!")
    else:
        print(f"\n⚠️ Chưa đủ quyền. Còn thiếu {10-total_tabs} tabs và {8-total_actions} actions")
else:
    print("❌ Không tìm thấy permissions cho Manager Diễm")

cur.close()
conn.close()
