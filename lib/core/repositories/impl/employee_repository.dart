import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../base_repository.dart';
import '../i_employee_repository.dart';

/// Riverpod provider — singleton instance
final employeeRepositoryProvider = Provider<EmployeeRepository>(
  (ref) => EmployeeRepository(),
);

/// Concrete implementation of [IEmployeeRepository].
///
/// Quản lý toàn bộ truy vấn bảng `employees` qua Supabase.
/// Hỗ trợ CRUD, toggle trạng thái, tra cứu theo `auth_user_id`,
/// đếm nhân viên, và subscribe realtime.
class EmployeeRepository extends BaseRepository
    implements IEmployeeRepository {
  @override
  String get tableName => 'employees';

  // ---------------------------------------------------------------------------
  // Select patterns
  // ---------------------------------------------------------------------------

  /// Các cột thường dùng — hạn chế select * để giảm payload
  static const String _defaultSelect =
      'id, full_name, email, phone, avatar_url, role, '
      'company_id, branch_id, is_active, auth_user_id, '
      'created_at, updated_at';

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  /// Lấy danh sách nhân viên theo nhiều tiêu chí.
  ///
  /// [companyId] — lọc theo công ty.
  /// [role] — lọc theo vai trò (MANAGER, STAFF, SHIFT_LEADER…).
  /// [isActive] — true = đang hoạt động, false = đã tắt.
  /// [limit] — giới hạn bản ghi trả về.
  @override
  Future<List<Map<String, dynamic>>> getEmployees({
    String? companyId,
    String? role,
    bool? isActive,
    int? limit,
  }) async {
    return safeCall(
      operation: 'getEmployees',
      action: () async {
        var query = client.from(tableName).select(_defaultSelect);

        if (companyId != null) {
          query = query.eq('company_id', companyId);
        }
        if (role != null) {
          query = query.eq('role', role);
        }
        if (isActive != null) {
          query = query.eq('is_active', isActive);
        }

        final ordered = query.order('created_at', ascending: false);

        if (limit != null) {
          return await ordered.limit(limit);
        }
        return await ordered;
      },
    );
  }

  /// Lấy chi tiết 1 nhân viên theo [id].
  @override
  Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    return fetchById(id, select: _defaultSelect);
  }

  /// Tra cứu nhân viên theo `auth_user_id` (Supabase Auth UUID).
  ///
  /// Đây là cách map giữa bảng `auth.users` và bảng `employees`.
  @override
  Future<Map<String, dynamic>?> getEmployeeByAuthId(
    String authUserId,
  ) async {
    return safeCall(
      operation: 'getEmployeeByAuthId',
      action: () async {
        final result = await client
            .from(tableName)
            .select(_defaultSelect)
            .eq('auth_user_id', authUserId)
            .maybeSingle();
        return result;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WRITE
  // ---------------------------------------------------------------------------

  /// Tạo nhân viên mới. [data] phải chứa ít nhất `company_id`, `email`, `role`.
  @override
  Future<Map<String, dynamic>> createEmployee(
    Map<String, dynamic> data,
  ) async {
    return insert(data);
  }

  /// Cập nhật thông tin nhân viên. Trả về bản ghi sau update.
  @override
  Future<Map<String, dynamic>> updateEmployee(
    String id,
    Map<String, dynamic> data,
  ) async {
    return update(id, {
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Bật / tắt trạng thái hoạt động của nhân viên.
  ///
  /// Khi [isActive] = false, nhân viên sẽ không thể đăng nhập.
  @override
  Future<void> toggleEmployeeStatus(String id, bool isActive) async {
    return safeCall(
      operation: 'toggleEmployeeStatus',
      action: () async {
        await client.from(tableName).update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      },
    );
  }

  /// Soft-delete nhân viên (đánh dấu `is_deleted = true`).
  @override
  Future<void> deleteEmployee(String id) async {
    return softDelete(id);
  }

  // ---------------------------------------------------------------------------
  // STATS
  // ---------------------------------------------------------------------------

  /// Đếm số nhân viên, tùy chọn lọc theo [companyId].
  ///
  /// Dùng lại method `count()` từ [BaseRepository].
  @override
  Future<int> getEmployeeCount({String? companyId}) async {
    final filters = <String, dynamic>{};
    if (companyId != null) {
      filters['company_id'] = companyId;
    }
    return count(filters: filters.isNotEmpty ? filters : null);
  }

  // ---------------------------------------------------------------------------
  // REALTIME
  // ---------------------------------------------------------------------------

  /// Subscribe realtime các thay đổi bảng `employees`.
  ///
  /// Filter phía client khi [companyId] được truyền.
  @override
  Stream<List<Map<String, dynamic>>> subscribeToEmployees({
    String? companyId,
  }) {
    final stream = client.from(tableName).stream(primaryKey: ['id']);

    if (companyId != null) {
      return stream.map(
        (rows) =>
            rows.where((row) => row['company_id'] == companyId).toList(),
      );
    }
    return stream;
  }
}
