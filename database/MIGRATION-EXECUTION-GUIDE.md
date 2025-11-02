# 🚀 Hướng Dẫn Thực Thi Migration - SABO HUB Database

> **Chuyên gia Backend Supabase**  
> **Ngày:** 2 November 2025  
> **Version:** 1.0

---

## 📋 TÓM TẮT

Document này hướng dẫn cách thực thi các migration scripts để phát triển database từ trạng thái hiện tại sang trạng thái hoàn chỉnh cho hệ thống quản lý bi-a SABO HUB.

### ✅ Đã Có (Current State)
- ✅ `companies` (2 records)
- ✅ `branches` (3 records)
- ⚠️ `stores` (3 records - duplicate với branches)
- ✅ `users` (5 records)
- ✅ `tables` (15 records)
- ✅ `tasks` (10 records)
- ✅ `daily_revenue` (90 records)
- ✅ `revenue_summary` (4 records)

### 🎯 Cần Thêm (Target State)
- 🔴 `menu_items` - Món ăn/uống
- 🔴 `orders` - Đơn hàng
- 🔴 `order_items` - Chi tiết đơn hàng
- 🔴 `table_sessions` - Phiên chơi bàn
- 🟡 `payments` - Thanh toán
- 🟡 `receipts` - Hóa đơn
- 🟡 `inventory_items` - Kho hàng
- 🟡 `inventory_transactions` - Giao dịch kho

---

## 🔒 TRƯỚC KHI BẮT ĐẦU

### 1. Backup Database

**Sử dụng Supabase Dashboard:**
1. Vào https://supabase.com/dashboard
2. Chọn project: `dqddxowyikefqcdiioyh`
3. Settings → Database → Connection pooling
4. Copy connection string
5. Chạy backup:

```bash
# Windows PowerShell
$env:PGPASSWORD='Acookingoil123'
pg_dump -h aws-1-ap-southeast-2.pooler.supabase.com `
  -p 6543 `
  -U postgres.dqddxowyikefqcdiioyh `
  -d postgres `
  -f "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
```

**Hoặc sử dụng Supabase CLI:**
```bash
supabase db dump -f backup_$(date +%Y%m%d).sql
```

### 2. Kiểm Tra Kết Nối

```bash
# Test connection
python database/analyze_database.py
```

Phải thấy output:
```
✅ Connected to database successfully!
📊 Found 9 tables in public schema
```

---

## 📝 MIGRATION PLAN

### Migration 1: Thống Nhất Stores → Branches
**File:** `database/migrations/001_consolidate_stores_branches.sql`  
**Thời gian:** ~2 phút  
**Risk:** 🟡 Medium (có sửa cấu trúc)

**Làm gì:**
- Merge dữ liệu từ `stores` → `branches`
- Update foreign keys trong `tables` và `tasks`
- Soft delete `stores` table

### Migration 2: Tạo Orders & Sessions System
**File:** `database/migrations/002_create_orders_sessions.sql`  
**Thời gian:** ~3 phút  
**Risk:** 🟢 Low (chỉ thêm mới)

**Làm gì:**
- Tạo `menu_items` table
- Tạo `orders` + `order_items` tables
- Tạo `table_sessions` table
- Thêm auto-numbering functions
- Thêm auto-calculation triggers
- Seed sample data

---

## 🚀 CÁCH THỰC THI

### Option 1: Supabase Dashboard (✅ Recommended)

1. **Mở SQL Editor:**
   - Vào https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/sql
   - Click "New Query"

2. **Run Migration 1:**
   ```sql
   -- Copy toàn bộ nội dung từ file:
   -- database/migrations/001_consolidate_stores_branches.sql
   
   -- Paste vào SQL Editor và click "Run"
   ```

3. **Verify Migration 1:**
   ```sql
   -- Check branches count
   SELECT COUNT(*) FROM branches WHERE deleted_at IS NULL;
   -- Expected: 6 (3 existing + 3 from stores)
   
   -- Check tables have branch_id
   SELECT table_id, branch_id FROM tables LIMIT 5;
   -- Should see branch_id values, not store_id
   
   -- Check stores are soft deleted
   SELECT COUNT(*) FROM stores WHERE deleted_at IS NOT NULL;
   -- Expected: 3
   ```

4. **Run Migration 2:**
   ```sql
   -- Copy toàn bộ nội dung từ file:
   -- database/migrations/002_create_orders_sessions.sql
   
   -- Paste vào SQL Editor và click "Run"
   ```

5. **Verify Migration 2:**
   ```sql
   -- Check new tables exist
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('menu_items', 'orders', 'order_items', 'table_sessions')
   ORDER BY table_name;
   
   -- Check menu items were seeded
   SELECT COUNT(*) FROM menu_items;
   -- Expected: 10 (5 beverages + 5 snacks)
   
   -- Check functions exist
   SELECT routine_name FROM information_schema.routines
   WHERE routine_schema = 'public'
   AND routine_name LIKE '%order%' OR routine_name LIKE '%session%';
   ```

### Option 2: Python Script (Alternative)

```bash
# Tạo script runner
python database/run_migration.py 001_consolidate_stores_branches.sql
python database/run_migration.py 002_create_orders_sessions.sql
```

### Option 3: psql Command Line

```bash
# Windows PowerShell
$env:PGPASSWORD='Acookingoil123'

psql -h aws-1-ap-southeast-2.pooler.supabase.com `
  -p 6543 `
  -U postgres.dqddxowyikefqcdiioyh `
  -d postgres `
  -f database/migrations/001_consolidate_stores_branches.sql

psql -h aws-1-ap-southeast-2.pooler.supabase.com `
  -p 6543 `
  -U postgres.dqddxowyikefqcdiioyh `
  -d postgres `
  -f database/migrations/002_create_orders_sessions.sql
```

---

## ✅ VERIFICATION CHECKLIST

### Sau Migration 1:

- [ ] `branches` table có 6 records
- [ ] `stores` có 3 records với `deleted_at` != NULL
- [ ] `tables.branch_id` có giá trị (không còn store_id)
- [ ] `tasks.branch_id` có giá trị (không còn store_id)
- [ ] Foreign key constraints đúng
- [ ] Indexes được tạo

### Sau Migration 2:

- [ ] 4 tables mới được tạo: `menu_items`, `orders`, `order_items`, `table_sessions`
- [ ] `menu_items` có 10 sample records
- [ ] Functions tạo order/session numbers hoạt động
- [ ] Triggers auto-calculate totals hoạt động
- [ ] Views `v_active_sessions` và `v_order_summary` được tạo
- [ ] Foreign keys giữa orders ↔ sessions hoạt động

### Test Queries:

```sql
-- Test 1: Check all tables
SELECT 
  schemaname,
  tablename,
  (SELECT COUNT(*) FROM pg_catalog.pg_indexes WHERE tablename = t.tablename) as index_count
FROM pg_tables t
WHERE schemaname = 'public'
ORDER BY tablename;

-- Test 2: Check menu items
SELECT name, category, price FROM menu_items WHERE is_active = true;

-- Test 3: Check functions
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- Test 4: Check views
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public'
ORDER BY table_name;
```

---

## 🔧 TROUBLESHOOTING

### Lỗi: "relation already exists"

**Nguyên nhân:** Table đã tồn tại từ migration trước  
**Giải pháp:**
```sql
-- Check existing tables
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- Drop if needed (CAREFUL!)
DROP TABLE IF EXISTS menu_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
-- ... etc
```

### Lỗi: "foreign key constraint violation"

**Nguyên nhân:** Dữ liệu không consistent  
**Giải pháp:**
```sql
-- Check orphaned records
SELECT t.* FROM tables t
LEFT JOIN branches b ON b.id = t.branch_id
WHERE b.id IS NULL;

-- Fix orphaned records
UPDATE tables SET branch_id = (
  SELECT id FROM branches LIMIT 1
)
WHERE branch_id IS NULL OR branch_id NOT IN (SELECT id FROM branches);
```

### Lỗi: "function does not exist"

**Nguyên nhân:** Migration chưa chạy hoàn chỉnh  
**Giải pháp:**
```sql
-- Re-run the function creation part from migration script
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
-- ... function body ...
$$ LANGUAGE plpgsql;
```

### Lỗi: Connection timeout

**Nguyên nhân:** Network hoặc credentials sai  
**Giải pháp:**
1. Check `.env` file có đúng credentials
2. Test connection: `python database/analyze_database.py`
3. Check Supabase Dashboard có project đang chạy

---

## 🔄 ROLLBACK (Emergency)

Nếu có vấn đề nghiêm trọng:

### Rollback Migration 2:
```sql
BEGIN;

-- Drop new tables
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS table_sessions CASCADE;
DROP TABLE IF EXISTS menu_items CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS generate_order_number();
DROP FUNCTION IF EXISTS generate_session_number();
DROP FUNCTION IF EXISTS update_order_total();
DROP FUNCTION IF EXISTS calculate_session_amounts();
DROP FUNCTION IF EXISTS update_table_status_from_session();

-- Drop views
DROP VIEW IF EXISTS v_active_sessions;
DROP VIEW IF EXISTS v_order_summary;

COMMIT;
```

### Rollback Migration 1:
```sql
BEGIN;

-- Restore stores from soft delete
UPDATE stores 
SET deleted_at = NULL, updated_at = NOW()
WHERE deleted_at IS NOT NULL;

-- If you renamed columns, restore them
-- ALTER TABLE tables RENAME COLUMN branch_id TO store_id;
-- ALTER TABLE tasks RENAME COLUMN branch_id TO store_id;

COMMIT;
```

### Full Restore from Backup:
```bash
# Windows PowerShell
$env:PGPASSWORD='Acookingoil123'

# WARNING: This will DROP all tables and restore from backup!
psql -h aws-1-ap-southeast-2.pooler.supabase.com `
  -p 6543 `
  -U postgres.dqddxowyikefqcdiioyh `
  -d postgres `
  -f backup_20251102.sql
```

---

## 📊 POST-MIGRATION TASKS

### 1. Update Flutter Services

**File cần sửa:**
- `lib/services/store_service.dart` → Đổi `.from('stores')` thành `.from('branches')`
- `lib/services/company_service.dart` → Update stats queries
- Tạo mới: `lib/services/order_service.dart`
- Tạo mới: `lib/services/session_service.dart`
- Tạo mới: `lib/services/menu_service.dart`

**Ví dụ:**
```dart
// lib/services/order_service.dart
class OrderService {
  final _supabase = supabase.client;
  
  Future<List<Order>> getOrders() async {
    final response = await _supabase
      .from('orders')
      .select('*, order_items(*)')
      .order('created_at', ascending: false);
    return (response as List).map((json) => Order.fromJson(json)).toList();
  }
}
```

### 2. Test Real-Time Subscriptions

```dart
// Test subscription
_supabase
  .from('table_sessions')
  .stream(primaryKey: ['id'])
  .eq('status', 'active')
  .listen((data) {
    print('Active sessions updated: ${data.length}');
  });
```

### 3. Setup RLS Policies

Xem file: `database/schemas/NEW-RLS-POLICIES-V2.sql`

### 4. Create Sample Data for Testing

```sql
-- Insert test session
INSERT INTO table_sessions (
  table_id, branch_id, company_id,
  customer_name, hourly_rate, status,
  started_by
)
SELECT 
  t.id, t.branch_id, t.company_id,
  'Test Customer', 50000, 'active',
  (SELECT id FROM users WHERE role = 'STAFF' LIMIT 1)
FROM tables t
WHERE t.status = 'available'
LIMIT 1;

-- Insert test order
INSERT INTO orders (
  company_id, branch_id, table_id, session_id,
  order_number, status, total
)
SELECT 
  s.company_id, s.branch_id, s.table_id, s.id,
  'TEST-001', 'pending', 30000
FROM table_sessions s
WHERE s.status = 'active'
LIMIT 1;
```

---

## 📞 SUPPORT & NEXT STEPS

### ✅ Nếu Migration Thành Công:

1. Commit changes: `git commit -am "feat: database migrations for orders & sessions"`
2. Update documentation
3. Proceed với Week 2 migrations (Payments, Inventory)
4. Implement Flutter UI cho Orders & Sessions

### ❌ Nếu Có Vấn Đề:

1. Check errors trong terminal/SQL Editor
2. Run verification queries
3. Check `database/analyze_database.py` output
4. Review migration scripts
5. Consider rollback nếu cần thiết

### 📧 Contact:

- Check logs: Supabase Dashboard → Logs
- Review docs: `/database/README.md`
- Analysis tool: `python database/analyze_database.py`

---

**Prepared by:** Supabase Backend Expert  
**Last Updated:** 2 November 2025  
**Version:** 1.0
