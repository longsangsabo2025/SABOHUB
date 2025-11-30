# 🔧 FIX: Lỗi "column branches.email does not exist"

## 📋 Mô tả lỗi
Khi tạo task từ các tab trong Company Details, ứng dụng gặp lỗi:
```
PostgrestException(message: column branches.email does not exist, code: 42703)
```

## 🔍 Nguyên nhân
- Code trong `lib/services/branch_service.dart` đang cố gắng select cột `email` từ bảng `branches`
- Bảng `branches` trong database không có cột `email`
- Model `Branch` đã có trường `email` nhưng database schema thiếu cột này

## ✅ Giải pháp đã áp dụng

### 1. Thêm cột email vào database
**File:** `add_email_to_branches.sql`
```sql
ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS email TEXT;

COMMENT ON COLUMN public.branches.email IS 'Branch contact email address';
```

**Script:** `add_email_to_branches.py`
- Tự động chạy migration để thêm cột email
- Kết nối với Supabase qua psycopg2
- Xử lý lỗi và đưa ra hướng dẫn nếu không thể auto-execute

### 2. Cập nhật BranchService
**File:** `lib/services/branch_service.dart`

Đã cập nhật tất cả các query để bao gồm cột `email`:

✅ `getAllBranches()` - Thêm `email` vào SELECT
✅ `getActiveBranches()` - Thêm `email` vào SELECT  
✅ `getBranchById()` - Thêm `email` vào SELECT
✅ `createBranch()` - Thêm parameter `email` và INSERT
✅ `updateBranch()` - Thêm `email` vào SELECT sau UPDATE
✅ `deactivateBranch()` - Thêm `email` vào SELECT sau UPDATE

### 3. Đã chạy migration
```bash
python add_email_to_branches.py
```
✅ Migration completed successfully!
📧 Email column đã được thêm vào bảng branches

## 🧪 Kiểm tra
- ✅ Không có lỗi compile trong `branch_service.dart`
- ✅ Model `Branch` đã tương thích với database schema mới
- ✅ Tất cả các method trong BranchService đã được cập nhật

## 📝 Tác động
- Giờ đây có thể tạo task từ các tab mà không gặp lỗi
- Branch có thể lưu trữ email liên hệ
- UI hiện có ở `branch_details_page.dart` đã có thể hiển thị email

## 🚀 Bước tiếp theo
1. Test lại chức năng tạo task từ các tab
2. Kiểm tra việc tạo/cập nhật branch có bao gồm email
3. Verify UI hiển thị email của branch đúng cách

## 📅 Thời gian
- Date: November 4, 2025
- Status: ✅ COMPLETED
