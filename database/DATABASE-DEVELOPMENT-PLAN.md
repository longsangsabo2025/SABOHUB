# 🎯 SABO HUB - Database Development Plan

> **Chuyên gia Backend Supabase**  
> **Ngày phân tích:** 2 Nov 2025  
> **Trạng thái:** ✅ Đã kết nối và phân tích thành công

---

## 📊 1. PHÂN TÍCH HIỆN TRẠNG DATABASE

### ✅ **Đã Kết Nối Thành Công**
```
URL: https://dqddxowyikefqcdiioyh.supabase.co
Database: PostgreSQL 15
Schema: public
```

### 📋 **Bảng Hiện Có (9 tables)**

| Bảng | Số Dòng | Trạng Thái | Mục Đích |
|------|---------|------------|----------|
| `companies` | 2 | ✅ Active | Công ty/doanh nghiệp |
| `branches` | 3 | ✅ Active | Chi nhánh |
| `stores` | 3 | ✅ Active | Cửa hàng (tương tự branches) |
| `users` | 5 | ✅ Active | Người dùng (CEO, Manager, Staff) |
| `tasks` | 10 | ✅ Active | Công việc |
| `tables` | 15 | ✅ Active | Bàn bi-a |
| `daily_revenue` | 90 | ✅ Active | Doanh thu theo ngày |
| `revenue_summary` | 4 | ✅ Active | Tổng hợp doanh thu |
| `activity_logs` | 0 | ⚠️ Empty | Nhật ký hoạt động |

### 🔍 **Phân Tích Chi Tiết**

#### ✅ **Điểm Mạnh**
1. ✅ Sử dụng UUID cho tất cả ID (tốt cho distributed systems)
2. ✅ Có timestamp fields (created_at, updated_at)
3. ✅ Foreign keys được thiết lập đúng
4. ✅ Indexes trên các trường quan trọng
5. ✅ Đã có dữ liệu mẫu để test

#### ⚠️ **Vấn Đề Cần Giải Quyết**

##### 1. **TRÙNG LẶP: `stores` vs `branches`**
- ❌ Có 2 bảng làm cùng 1 việc (stores và branches)
- ❌ Cấu trúc gần như giống hệt nhau
- ❌ Frontend code sử dụng cả 2 (`company_service.dart` dùng companies, `store_service.dart` dùng stores)
- ⚠️ Cần thống nhất: chọn 1 trong 2

**Giải pháp đề xuất:**
```sql
-- Option 1: Giữ branches, migrate data từ stores
-- Option 2: Giữ stores, xóa branches
-- Recommendation: Giữ BRANCHES vì:
--   + Phù hợp với business logic (company → branch)
--   + Đã được thiết kế trong schema V2
--   + Tên rõ ràng hơn cho multi-location business
```

##### 2. **THIẾU CÁC BẢNG QUAN TRỌNG**

Theo frontend models, cần thêm các bảng:

| Bảng Thiếu | Frontend Model | Mức Độ |
|------------|----------------|--------|
| `orders` | order.dart | 🔴 Critical |
| `order_items` | order.dart | 🔴 Critical |
| `sessions` | session.dart | 🔴 Critical |
| `menu_items` | menu_item.dart | 🟡 High |
| `inventory` | inventory.dart | 🟡 High |
| `inventory_transactions` | stock_movement.dart | 🟡 High |
| `receipts` | receipt.dart | 🟡 High |
| `payments` | payment.dart | 🟡 High |
| `attendance` | attendance.dart | 🟢 Medium |
| `products` | - | 🟢 Medium |
| `staff` | staff.dart | 🟢 Medium |

##### 3. **CẤU TRÚC PHÂN QUYỀN (RLS)**

- ⚠️ README đề cập đến vấn đề "infinite recursion in RLS policies"
- ⚠️ Cần kiểm tra RLS policies hiện tại
- ⚠️ Cần implement JWT-based authentication

##### 4. **SCHEMA NAMING INCONSISTENCY**

Frontend sử dụng:
```dart
// company_service.dart
.from('companies')

// store_service.dart  
.from('stores')

// task_service.dart
.from('tasks')
```

Database có:
- ✅ `companies` - match
- ⚠️ `stores` AND `branches` - conflict!
- ✅ `tasks` - match

---

## 🎯 2. KẾ HOẠCH PHÁT TRIỂN

### Phase 1: 🔴 **CRITICAL - Core Transaction System** (Week 1)

#### 1.1. Thống nhất Store/Branch Architecture
```sql
-- Migrate data from stores → branches
-- Update all foreign keys
-- Drop stores table
-- Update Flutter services
```

#### 1.2. Tạo Orders System
```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  table_id UUID REFERENCES tables(id),
  
  -- Customer Info
  customer_name TEXT,
  customer_phone TEXT,
  
  -- Order Status
  status TEXT NOT NULL CHECK (status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')),
  
  -- Financial
  subtotal DECIMAL(15,2) DEFAULT 0,
  tax DECIMAL(15,2) DEFAULT 0,
  discount DECIMAL(15,2) DEFAULT 0,
  total DECIMAL(15,2) NOT NULL,
  
  -- Timestamps
  ordered_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES menu_items(id),
  
  -- Item Details
  item_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(15,2) NOT NULL,
  total_price DECIMAL(15,2) NOT NULL,
  
  -- Notes
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 1.3. Tạo Sessions System (Quản lý bàn)
```sql
CREATE TABLE table_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_id UUID NOT NULL REFERENCES tables(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  company_id UUID NOT NULL REFERENCES companies(id),
  
  -- Customer
  customer_name TEXT,
  customer_phone TEXT,
  
  -- Time Tracking
  start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  pause_time TIMESTAMPTZ,
  total_paused_minutes INTEGER DEFAULT 0,
  
  -- Pricing
  hourly_rate DECIMAL(15,2) NOT NULL,
  table_amount DECIMAL(15,2) DEFAULT 0,    -- Tiền bàn
  orders_amount DECIMAL(15,2) DEFAULT 0,   -- Tiền đồ ăn/uống
  total_amount DECIMAL(15,2) DEFAULT 0,     -- Tổng
  
  -- Status
  status TEXT NOT NULL CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
  
  -- Notes
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
```

### Phase 2: 🟡 **HIGH - Menu & Inventory** (Week 2)

#### 2.1. Menu Items
```sql
CREATE TABLE menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  
  -- Item Info
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,  -- food, beverage, snack, etc
  
  -- Pricing
  price DECIMAL(15,2) NOT NULL,
  cost_price DECIMAL(15,2),
  
  -- Stock
  has_stock BOOLEAN DEFAULT false,
  current_stock DECIMAL(15,2) DEFAULT 0,
  
  -- Media
  image_url TEXT,
  
  -- Status
  is_available BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
```

#### 2.2. Inventory System
```sql
CREATE TABLE inventory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  branch_id UUID REFERENCES branches(id),
  
  -- Item Info
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('food', 'beverage', 'equipment', 'cleaning', 'other')),
  
  -- Stock
  unit TEXT NOT NULL,  -- kg, liter, piece, box, etc
  quantity DECIMAL(15,2) DEFAULT 0,
  min_quantity DECIMAL(15,2) DEFAULT 0,
  
  -- Pricing
  unit_price DECIMAL(15,2) NOT NULL,
  
  -- Supplier
  supplier TEXT,
  
  -- Tracking
  last_restocked_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE inventory_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_item_id UUID NOT NULL REFERENCES inventory_items(id),
  
  -- Transaction
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('in', 'out', 'adjustment', 'waste')),
  quantity DECIMAL(15,2) NOT NULL,
  unit_price DECIMAL(15,2),
  total_value DECIMAL(15,2),
  
  -- Reference
  reference_type TEXT,  -- 'order', 'purchase', 'manual'
  reference_id UUID,
  
  -- Notes
  notes TEXT,
  performed_by UUID REFERENCES users(id),
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Phase 3: 🟡 **HIGH - Payment & Receipt** (Week 3)

#### 3.1. Payments System
```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Reference (có thể là order hoặc session)
  reference_type TEXT NOT NULL CHECK (reference_type IN ('order', 'session')),
  reference_id UUID NOT NULL,
  
  -- Payment Details
  amount DECIMAL(15,2) NOT NULL,
  method TEXT NOT NULL CHECK (method IN ('cash', 'card', 'transfer', 'e_wallet', 'other')),
  
  -- Payment Info
  transaction_id TEXT,
  card_last_4 TEXT,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  
  -- Notes
  notes TEXT,
  processed_by UUID REFERENCES users(id),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  
  -- Reference
  session_id UUID REFERENCES table_sessions(id),
  
  -- Receipt Details
  receipt_number TEXT UNIQUE NOT NULL,
  
  -- Amounts
  table_amount DECIMAL(15,2) DEFAULT 0,
  orders_amount DECIMAL(15,2) DEFAULT 0,
  subtotal DECIMAL(15,2) NOT NULL,
  tax DECIMAL(15,2) DEFAULT 0,
  discount DECIMAL(15,2) DEFAULT 0,
  total DECIMAL(15,2) NOT NULL,
  
  -- Customer
  customer_name TEXT,
  customer_phone TEXT,
  
  -- Staff
  served_by UUID REFERENCES users(id),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
```

### Phase 4: 🟢 **MEDIUM - Staff Management** (Week 4)

#### 4.1. Attendance System
```sql
CREATE TABLE attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  branch_id UUID NOT NULL REFERENCES branches(id),
  company_id UUID NOT NULL REFERENCES companies(id),
  
  -- Attendance
  date DATE NOT NULL,
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  
  -- Work Hours
  scheduled_hours DECIMAL(5,2),
  actual_hours DECIMAL(5,2),
  overtime_hours DECIMAL(5,2) DEFAULT 0,
  
  -- Status
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late', 'leave', 'holiday')),
  
  -- Notes
  notes TEXT,
  approved_by UUID REFERENCES users(id),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, date)
);
```

### Phase 5: 🔒 **Security - RLS Policies** (Ongoing)

```sql
-- Enable RLS on all tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ... etc for all tables

-- CEO: Can see everything in their company
CREATE POLICY "CEO can see all company data" ON companies
  FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'CEO' 
    AND id = (auth.jwt() ->> 'company_id')::uuid
  );

-- Branch Manager: Can see their branch data
CREATE POLICY "Manager can see branch data" ON orders
  FOR SELECT
  USING (
    auth.jwt() ->> 'role' IN ('CEO', 'BRANCH_MANAGER')
    AND branch_id = (auth.jwt() ->> 'branch_id')::uuid
  );

-- Staff: Can see only their assigned tasks
CREATE POLICY "Staff can see assigned tasks" ON tasks
  FOR SELECT
  USING (
    assigned_to = auth.uid()
    OR created_by = auth.uid()
  );
```

---

## 🚀 3. MIGRATION SCRIPT

### Script 1: Thống nhất Stores → Branches

```sql
-- File: database/migrations/001_consolidate_stores_branches.sql

BEGIN;

-- 1. Kiểm tra xem có dữ liệu conflict không
SELECT 
  'stores' as source,
  s.id,
  s.name,
  s.company_id,
  s.code
FROM stores s
WHERE EXISTS (
  SELECT 1 FROM branches b 
  WHERE b.company_id = s.company_id 
  AND b.code = s.code
);

-- 2. Migrate dữ liệu từ stores sang branches (nếu không có conflict)
INSERT INTO branches (
  id, company_id, name, code, address, phone, 
  manager_id, is_active, created_at, updated_at
)
SELECT 
  id, company_id, name, code, address, phone,
  manager_id, 
  CASE WHEN status = 'ACTIVE' THEN true ELSE false END,
  created_at, updated_at
FROM stores
WHERE id NOT IN (SELECT id FROM branches)
ON CONFLICT (id) DO NOTHING;

-- 3. Update foreign keys trong tables table
UPDATE tables 
SET store_id = branch_id 
WHERE branch_id IS NOT NULL;

-- Note: Sau khi verify data, có thể drop table stores

COMMIT;
```

### Script 2: Tạo Core Transaction Tables

```sql
-- File: database/migrations/002_create_transaction_tables.sql
-- (Xem chi tiết ở Phase 1.2 và 1.3 ở trên)
```

---

## 📋 4. CHECKLIST TRIỂN KHAI

### Week 1: Critical Tables
- [ ] Backup database hiện tại
- [ ] Chạy migration consolidate stores/branches
- [ ] Tạo orders + order_items tables
- [ ] Tạo table_sessions table
- [ ] Update Flutter services (company_service.dart)
- [ ] Test CRUD operations
- [ ] Verify RLS policies

### Week 2: Menu & Inventory
- [ ] Tạo menu_items table
- [ ] Tạo inventory_items table
- [ ] Tạo inventory_transactions table
- [ ] Seed sample data
- [ ] Create Flutter services
- [ ] Test inventory tracking

### Week 3: Payments
- [ ] Tạo payments table
- [ ] Tạo receipts table
- [ ] Implement payment processing logic
- [ ] Create receipt generation
- [ ] Test payment flows

### Week 4: Staff Management
- [ ] Tạo attendance_records table
- [ ] Implement check-in/check-out logic
- [ ] Create reporting queries
- [ ] Test attendance tracking

### Ongoing: Security
- [ ] Review all RLS policies
- [ ] Setup JWT claims
- [ ] Configure auth hook
- [ ] Test role-based access
- [ ] Document security model

---

## 🔧 5. CÁC LỆNH HỮU ÍCH

### Kết nối Database
```bash
# Sử dụng Python script
python database/analyze_database.py

# Hoặc dùng psql
psql "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
```

### Backup & Restore
```bash
# Backup
pg_dump -h aws-1-ap-southeast-2.pooler.supabase.com \
  -U postgres.dqddxowyikefqcdiioyh \
  -d postgres \
  -f backup_$(date +%Y%m%d).sql

# Restore
psql -h ... -U ... -d postgres -f backup_20251102.sql
```

### Chạy Migration
```bash
# Từ Supabase Dashboard SQL Editor
# Hoặc dùng script
node database/run-migration.js 002_create_transaction_tables.sql
```

---

## 📊 6. EXPECTED RESULTS

Sau khi hoàn thành:

### Database Schema
```
companies (1) ─┬─ branches (N)
               │
               ├─ users (N)
               │   └─ attendance_records (N)
               │
               ├─ menu_items (N)
               │
               ├─ inventory_items (N)
               │   └─ inventory_transactions (N)
               │
               └─ branches (N) ─┬─ tables (N)
                                │   └─ table_sessions (N)
                                │       ├─ orders (N)
                                │       │   └─ order_items (N)
                                │       ├─ payments (N)
                                │       └─ receipts (N)
                                │
                                └─ tasks (N)
```

### Performance Metrics
- ✅ Query response time < 100ms
- ✅ RLS policies không có recursive loop
- ✅ Indexes trên tất cả foreign keys
- ✅ Proper data normalization
- ✅ Audit trail với activity_logs

### Code Quality
- ✅ Flutter services match database schema
- ✅ Type-safe models
- ✅ Proper error handling
- ✅ Real-time subscriptions working
- ✅ Consistent naming conventions

---

## 🎯 7. NEXT STEPS

1. **Review & Approval**
   - [ ] Review kế hoạch này với team
   - [ ] Confirm business requirements
   - [ ] Prioritize features

2. **Start Implementation**
   - [ ] Create backup
   - [ ] Run Week 1 migrations
   - [ ] Update Flutter code
   - [ ] Test thoroughly

3. **Documentation**
   - [ ] API documentation
   - [ ] Database schema diagram
   - [ ] Migration guides
   - [ ] Troubleshooting guide

---

## 📞 SUPPORT

Nếu có vấn đề gì trong quá trình triển khai:

1. Check logs trong Supabase Dashboard
2. Review migration scripts
3. Test với Python script: `python database/analyze_database.py`
4. Consult documentation trong `/database` folder

---

**Prepared by:** Supabase Backend Expert  
**Last Updated:** 2 November 2025  
**Version:** 1.0
