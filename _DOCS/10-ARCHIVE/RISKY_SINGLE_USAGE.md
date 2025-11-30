# DANH SÁCH CÁC CHỖ CẦN FIX .single() → .maybeSingle()

## HIGH RISK (Có thể gây lỗi PGRST116)

### 1. lib/services/manager_kpi_service.dart:22
```dart
final employee = await _supabase
    .from('employees')
    .select('company_id, branch_id')
    .eq('id', userId)
    .single();  // ❌ Nếu employee không tồn tại → crash
```
**Fix**: Dùng `.maybeSingle()` và check null

### 2. lib/services/company_service.dart:51
```dart
final response = await _supabase
    .from('companies')
    .select('id, name, ...')
    .eq('id', id)
    .single();  // ❌ Nếu company không tồn tại → crash
```
**Fix**: Dùng `.maybeSingle()` và return null (đã có try-catch)

### 3. lib/services/location_service.dart:90
```dart
final companyData = await _supabase
    .from('companies')
    .select('check_in_latitude, check_in_longitude, check_in_radius')
    .eq('id', companyId)
    .single();  // ❌ Nếu company không tồn tại → crash
```
**Fix**: Dùng `.maybeSingle()` và check null (đã có try-catch)

### 4. lib/services/ai_service.dart:44
```dart
await _supabase.from('ai_assistants').insert({...}).select().single();
```
**Risk**: INSERT thường OK, nhưng nếu có constraint violation → crash
**Fix**: Đã có try-catch, OK

### 5. lib/providers/auth_provider.dart:602
```dart
final insertResponse = await _supabaseClient
    .from('users')
    .insert(newUser)
    .select()
    .single();
```
**Risk**: INSERT có thể fail nếu duplicate email
**Status**: Cần kiểm tra có try-catch không

### 6. lib/services/store_service.dart:27
```dart
await _supabase.from('stores').select().eq('id', id).single();
```
**Risk**: Nếu store không tồn tại → crash

## MEDIUM RISK (Có try-catch nhưng nên dùng maybeSingle)

- Các SELECT với `.eq('id', ...)` trong các service khác
- Các UPDATE/DELETE với `.single()` để lấy kết quả

## LOW RISK (An toàn)

- INSERT operations (luôn trả về 1 row nếu thành công)
- UPDATE/INSERT trong transaction

## TÓM TẮT

**Cần fix ngay:**
1. manager_kpi_service.dart:22 - employee lookup
2. store_service.dart:27 - store lookup by ID
3. Tất cả các SELECT BY ID nên dùng .maybeSingle()

**Đã OK:**
- daily_reports_dashboard_page.dart - Đã fix
- Các service có try-catch return null

**Best Practice:**
- SELECT BY ID → dùng `.maybeSingle()` + check null
- INSERT → dùng `.single()` OK (đã có trong transaction)
- UPDATE → dùng `.maybeSingle()` nếu không chắc có row
