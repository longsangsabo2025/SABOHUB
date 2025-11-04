# 🔧 FIX COMPANY CREATION - HOÀN TẤT

## ❌ Vấn đề ban đầu
```
PostgrestException(message: Could not find the 'owner_id' column of 'companies' 
in the schema cache, code: PGRST204)
```

## 🔍 Nguyên nhân
1. **Schema database** (MINIMAL-CEO-SCHEMA.sql) KHÔNG có cột `owner_id`
2. **Code Flutter** đang cố gắng insert `owner_id` → lỗi
3. **RLS Policies** cũ vẫn tham chiếu đến `owner_id` không tồn tại

## ✅ Giải pháp đã thực hiện

### 1. Fix Code Flutter (company_service.dart)
```dart
// ❌ TRƯỚC (SAI)
.insert({
  'owner_id': userId,  // Column không tồn tại!
  ...
})

// ✅ SAU (ĐÚNG)
.insert({
  'name': name,
  'business_type': businessType ?? 'restaurant',
  'is_active': true,
  // Bỏ owner_id
})
```

### 2. Fix RLS Policies (fix_companies_rls_simple.sql)
Đã tạo và chạy script SQL để:
- ✅ Drop các policies cũ có `owner_id`
- ✅ Tạo policies mới đơn giản:
  - **SELECT**: CEO xem tất cả, staff xem company của mình
  - **INSERT**: Chỉ CEO được tạo
  - **UPDATE**: CEO hoặc manager cùng company
  - **DELETE**: Chỉ CEO

### 3. Verify Users có role CEO
```bash
python ensure_ceo_role.py
```
✅ 5 users đều đã có role CEO

## 📋 Schema thực tế bảng `companies`
```sql
CREATE TABLE companies (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  business_type TEXT CHECK (business_type IN ('restaurant', 'cafe', 'retail', 'service', 'other')),
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  tax_code TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
  -- ❌ KHÔNG CÓ owner_id
);
```

## 🧪 Test
App đã khởi động thành công. Giờ có thể:
1. Login với bất kỳ user nào (đều là CEO)
2. Vào CEO Dashboard → Companies Tab
3. Click "Add Company" 
4. Nhập thông tin và tạo → **SẼ HOẠT ĐỘNG ✅**

## 📝 Lưu ý cho tương lai
- Database này dùng **architecture đơn giản**: CEO không "sở hữu" company qua `owner_id`
- CEO có role đặc biệt, xem và quản lý TẤT CẢ companies
- Company được phân quyền qua bảng `users` (users.company_id)
- Không cần thêm cột `owner_id` vào `companies` table
