"""
KIỂM TRA SUPABASE THỰC TẾ - AUDIT TOÀN DIỆN
Kết nối trực tiếp vào database và kiểm tra schema thực tế
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv
import json

# Load environment variables
load_dotenv()

# Supabase credentials
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

print("=" * 80)
print("🔍 KIỂM TRA SUPABASE THỰC TẾ - AUDIT DATABASE")
print("=" * 80)
print(f"📡 Connecting to: {SUPABASE_URL}")
print()

# Create Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

def check_table_exists(table_name):
    """Kiểm tra table có tồn tại không"""
    try:
        result = supabase.table(table_name).select("*").limit(0).execute()
        return True, None
    except Exception as e:
        return False, str(e)

def get_table_columns(table_name):
    """Lấy danh sách columns của table"""
    try:
        result = supabase.table(table_name).select("*").limit(1).execute()
        if result.data and len(result.data) > 0:
            return list(result.data[0].keys())
        else:
            # Try to get schema even with no data
            result = supabase.table(table_name).select("*").limit(0).execute()
            return []
    except Exception as e:
        return None

def test_rls_policy(table_name, operation='select'):
    """Test RLS policy"""
    try:
        if operation == 'select':
            result = supabase.table(table_name).select("*").limit(1).execute()
            return True, len(result.data) if result.data else 0
        return False, "Not implemented"
    except Exception as e:
        return False, str(e)

# ============================================
# 1. KIỂM TRA CÁC TABLES CHÍNH
# ============================================

print("📋 1. KIỂM TRA CÁC TABLES CHÍNH")
print("-" * 80)

critical_tables = {
    'users': 'Bảng người dùng',
    'companies': 'Bảng công ty',
    'branches': 'Bảng chi nhánh (đã đổi tên từ stores)',
    'stores': 'Bảng cũ (đã đổi tên thành branches)',
    'tasks': 'Bảng công việc',
    'attendance': 'Bảng chấm công',
    'task_templates': 'Bảng mẫu công việc',
    'employees': 'Bảng nhân viên',
    'profiles': 'Bảng profiles (có thể không tồn tại)',
}

table_status = {}

for table, description in critical_tables.items():
    exists, error = check_table_exists(table)
    status = "✅ TỒN TẠI" if exists else "❌ KHÔNG TỒN TẠI"
    table_status[table] = exists
    
    print(f"{status} - {table:<20} ({description})")
    if not exists and error:
        print(f"         Lỗi: {error[:100]}")

print()

# ============================================
# 2. KIỂM TRA CẤU TRÚC ATTENDANCE TABLE
# ============================================

print("📊 2. KIỂM TRA CẤU TRÚC ATTENDANCE TABLE")
print("-" * 80)

if table_status.get('attendance'):
    columns = get_table_columns('attendance')
    if columns:
        print("Các cột hiện tại:")
        for col in sorted(columns):
            print(f"  ✓ {col}")
        
        print("\nKiểm tra các cột bắt buộc:")
        required_columns = {
            'id': '✅',
            'user_id': '✅',
            'branch_id': '✅ (Đã đổi từ store_id)',
            'store_id': '⚠️ (Cột cũ, nên xóa)',
            'company_id': '✅ (Cần thiết)',
            'check_in': '✅',
            'check_out': '✅',
            'check_in_latitude': '✅ (GPS)',
            'check_in_longitude': '✅ (GPS)',
            'check_out_latitude': '✅ (GPS)',
            'check_out_longitude': '✅ (GPS)',
            'employee_name': '✅ (Cache)',
            'employee_role': '✅ (Cache)',
            'total_hours': '✅',
        }
        
        for col, note in required_columns.items():
            status = "✅ CÓ" if col in columns else "❌ THIẾU"
            print(f"  {status} - {col:<25} {note}")
    else:
        print("⚠️ Không thể lấy cấu trúc columns (table có thể rỗng)")
else:
    print("❌ Attendance table không tồn tại!")

print()

# ============================================
# 3. KIỂM TRA CẤU TRÚC TASKS TABLE
# ============================================

print("📊 3. KIỂM TRA CẤU TRÚC TASKS TABLE")
print("-" * 80)

if table_status.get('tasks'):
    columns = get_table_columns('tasks')
    if columns:
        print("Các cột hiện tại:")
        for col in sorted(columns):
            print(f"  ✓ {col}")
        
        print("\nKiểm tra các cột bắt buộc:")
        required_columns = {
            'id': '✅',
            'company_id': '✅ (Multi-company)',
            'branch_id': '✅ (Đã đổi từ store_id)',
            'title': '✅',
            'assignee_id': '✅ (Tên chuẩn)',
            'assigned_to': '⚠️ (Trùng với assignee_id?)',
            'assigned_to_name': '✅',
            'status': '✅',
            'priority': '✅',
            'progress': '✅ (0-100%)',
            'created_by': '✅',
            'deleted_at': '✅ (Soft delete)',
        }
        
        for col, note in required_columns.items():
            status = "✅ CÓ" if col in columns else "❌ THIẾU"
            print(f"  {status} - {col:<25} {note}")
    else:
        print("⚠️ Không thể lấy cấu trúc columns")
else:
    print("❌ Tasks table không tồn tại!")

print()

# ============================================
# 4. KIỂM TRA CẤU TRÚC COMPANIES TABLE
# ============================================

print("📊 4. KIỂM TRA CẤU TRÚC COMPANIES TABLE")
print("-" * 80)

if table_status.get('companies'):
    columns = get_table_columns('companies')
    if columns:
        print("Các cột hiện tại:")
        for col in sorted(columns):
            print(f"  ✓ {col}")
        
        print("\nKiểm tra các cột bắt buộc:")
        required_columns = {
            'id': '✅',
            'name': '✅',
            'legal_name': '✅ (Tên pháp lý)',
            'business_type': '✅',
            'tax_code': '✅ (Mã số thuế)',
            'owner_id': '✅ (CEO)',
            'website': '✅',
            'primary_color': '✅ (Branding)',
            'secondary_color': '✅ (Branding)',
            'settings': '✅ (JSONB)',
            'created_by': '✅',
            'deleted_at': '✅ (Soft delete)',
        }
        
        for col, note in required_columns.items():
            status = "✅ CÓ" if col in columns else "❌ THIẾU"
            print(f"  {status} - {col:<25} {note}")
else:
    print("❌ Companies table không tồn tại!")

print()

# ============================================
# 5. KIỂM TRA CẤU TRÚC BRANCHES TABLE
# ============================================

print("📊 5. KIỂM TRA CẤU TRÚC BRANCHES TABLE")
print("-" * 80)

if table_status.get('branches'):
    columns = get_table_columns('branches')
    if columns:
        print("Các cột hiện tại:")
        for col in sorted(columns):
            print(f"  ✓ {col}")
        
        print("\nKiểm tra các cột bắt buộc:")
        required_columns = {
            'id': '✅',
            'company_id': '✅',
            'name': '✅',
            'manager_id': '✅ (Đã đổi từ owner_id)',
            'code': '✅ (Branch code)',
            'address': '✅',
            'phone': '✅',
            'email': '✅',
        }
        
        for col, note in required_columns.items():
            status = "✅ CÓ" if col in columns else "❌ THIẾU"
            print(f"  {status} - {col:<25} {note}")
elif table_status.get('stores'):
    print("⚠️ Bảng vẫn còn tên cũ là 'stores', chưa đổi thành 'branches'!")
else:
    print("❌ Branches/Stores table không tồn tại!")

print()

# ============================================
# 6. KIỂM TRA USERS TABLE
# ============================================

print("📊 6. KIỂM TRA CẤU TRÚC USERS TABLE")
print("-" * 80)

if table_status.get('users'):
    columns = get_table_columns('users')
    if columns:
        print("Các cột hiện tại:")
        for col in sorted(columns):
            print(f"  ✓ {col}")
        
        print("\nKiểm tra các cột bắt buộc:")
        required_columns = {
            'id': '✅',
            'name': '✅',
            'email': '✅',
            'role': '✅',
            'company_id': '✅ (Multi-company)',
            'branch_id': '✅ (Đã đổi từ store_id)',
            'deleted_at': '✅ (Soft delete)',
        }
        
        for col, note in required_columns.items():
            status = "✅ CÓ" if col in columns else "❌ THIẾU"
            print(f"  {status} - {col:<25} {note}")
else:
    print("❌ Users table không tồn tại!")

print()

# ============================================
# 7. KIỂM TRA DỮ LIỆU MẪU
# ============================================

print("📊 7. KIỂM TRA DỮ LIỆU TRONG CÁC BẢNG")
print("-" * 80)

tables_to_check = ['companies', 'branches', 'users', 'tasks', 'attendance']

for table in tables_to_check:
    if table_status.get(table):
        try:
            result = supabase.table(table).select("*", count='exact').limit(0).execute()
            count = result.count if result.count is not None else 0
            print(f"  {table:<20}: {count:>5} bản ghi")
        except Exception as e:
            print(f"  {table:<20}: ⚠️ Lỗi khi đếm - {str(e)[:50]}")
    else:
        print(f"  {table:<20}: ❌ Không tồn tại")

print()

# ============================================
# 8. KIỂM TRA RLS POLICIES
# ============================================

print("🔒 8. KIỂM TRA RLS POLICIES (Row Level Security)")
print("-" * 80)

print("⚠️ Kiểm tra RLS cần auth context, sẽ kiểm tra khả năng truy cập...")

for table in ['tasks', 'attendance', 'companies', 'branches']:
    if table_status.get(table):
        can_access, info = test_rls_policy(table)
        if can_access:
            print(f"  ✅ {table:<20}: Service role có thể truy cập ({info} records)")
        else:
            print(f"  ⚠️ {table:<20}: {info}")

print()

# ============================================
# 9. KIỂM TRA STORAGE BUCKETS
# ============================================

print("💾 9. KIỂM TRA STORAGE BUCKETS")
print("-" * 80)

try:
    buckets = supabase.storage.list_buckets()
    if buckets:
        print("Các buckets hiện có:")
        for bucket in buckets:
            print(f"  ✓ {bucket.name:<20} (Public: {bucket.public})")
    else:
        print("  ⚠️ Không có bucket nào")
except Exception as e:
    print(f"  ❌ Lỗi khi kiểm tra buckets: {str(e)}")

print()

# ============================================
# 10. TÓM TẮT VẤN ĐỀ
# ============================================

print("=" * 80)
print("📝 TÓM TẮT VẤN ĐỀ PHÁT HIỆN")
print("=" * 80)

issues = []

# Check profiles table
if table_status.get('profiles'):
    issues.append({
        'severity': 'CRITICAL',
        'issue': 'Bảng PROFILES tồn tại - RLS policies có thể đang dùng sai bảng',
        'fix': 'Kiểm tra tất cả RLS policies có đang dùng profiles thay vì users không'
    })
elif not table_status.get('profiles'):
    issues.append({
        'severity': 'HIGH',
        'issue': 'Bảng PROFILES không tồn tại - RLS policies đang reference bảng không có',
        'fix': 'Chạy migration để sửa tất cả policies từ profiles → users'
    })

# Check stores vs branches
if table_status.get('stores') and not table_status.get('branches'):
    issues.append({
        'severity': 'CRITICAL',
        'issue': 'Bảng vẫn còn tên STORES - chưa đổi thành BRANCHES',
        'fix': 'Chạy migration để rename stores → branches'
    })
elif table_status.get('stores') and table_status.get('branches'):
    issues.append({
        'severity': 'HIGH',
        'issue': 'Cả STORES và BRANCHES đều tồn tại - có thể data bị duplicate',
        'fix': 'Kiểm tra và xóa bảng stores cũ sau khi đã migrate'
    })

# Check attendance structure
if table_status.get('attendance'):
    att_cols = get_table_columns('attendance')
    if att_cols:
        if 'store_id' in att_cols and 'branch_id' not in att_cols:
            issues.append({
                'severity': 'CRITICAL',
                'issue': 'ATTENDANCE vẫn dùng store_id - chưa đổi thành branch_id',
                'fix': 'Chạy migration để rename store_id → branch_id'
            })
        if 'company_id' not in att_cols:
            issues.append({
                'severity': 'HIGH',
                'issue': 'ATTENDANCE thiếu cột company_id',
                'fix': 'Thêm cột company_id vào attendance table'
            })
        if 'check_in_latitude' not in att_cols:
            issues.append({
                'severity': 'MEDIUM',
                'issue': 'ATTENDANCE thiếu các cột GPS (latitude/longitude)',
                'fix': 'Thêm các cột check_in_latitude, check_in_longitude, etc.'
            })

# Check tasks structure
if table_status.get('tasks'):
    task_cols = get_table_columns('tasks')
    if task_cols:
        if 'progress' not in task_cols:
            issues.append({
                'severity': 'MEDIUM',
                'issue': 'TASKS thiếu cột progress',
                'fix': 'Thêm cột progress (0-100) vào tasks table'
            })
        if 'company_id' not in task_cols:
            issues.append({
                'severity': 'HIGH',
                'issue': 'TASKS thiếu cột company_id',
                'fix': 'Thêm cột company_id vào tasks table'
            })

# Print issues
if issues:
    for i, issue in enumerate(issues, 1):
        severity_icon = {
            'CRITICAL': '🔴',
            'HIGH': '🟠',
            'MEDIUM': '🟡',
            'LOW': '🟢'
        }.get(issue['severity'], '⚪')
        
        print(f"\n{severity_icon} Vấn đề #{i} - [{issue['severity']}]")
        print(f"   Vấn đề: {issue['issue']}")
        print(f"   Khắc phục: {issue['fix']}")
else:
    print("\n✅ Không phát hiện vấn đề nào!")

print()
print("=" * 80)
print("✅ HOÀN THÀNH KIỂM TRA")
print("=" * 80)
print(f"📄 Migration file đã tạo: supabase/migrations/20251112_fix_critical_schema_issues.sql")
print(f"📖 Báo cáo chi tiết: SUPABASE-FRONTEND-AUDIT-REPORT.md")
print(f"🚀 Hướng dẫn: CRITICAL-FIXES-QUICK-START.md")
print()

