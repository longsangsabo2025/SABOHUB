import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../base_repository.dart';
import '../i_customer_repository.dart';

/// Riverpod provider — singleton instance
final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(),
);

/// Concrete implementation of [ICustomerRepository].
///
/// Quản lý toàn bộ truy vấn bảng `customers` qua Supabase.
/// Hỗ trợ CRUD, tìm kiếm (name/phone/email), phân trang,
/// lấy đơn hàng của khách, thống kê, và subscribe realtime.
///
/// Đây là abstraction đầu tiên cho bảng customers — trước đó
/// 33 file truy cập trực tiếp bảng này (81 hits).
class CustomerRepository extends BaseRepository
    implements ICustomerRepository {
  @override
  String get tableName => 'customers';

  // ---------------------------------------------------------------------------
  // Select patterns
  // ---------------------------------------------------------------------------

  static const String _defaultSelect =
      'id, name, phone, email, address, tier, company_id, '
      'assigned_to, notes, is_active, created_at, updated_at';

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  /// Lấy danh sách khách hàng với nhiều bộ lọc + tìm kiếm + phân trang.
  ///
  /// [companyId] — lọc theo công ty.
  /// [tier] — hạng khách hàng (VIP, Regular, …).
  /// [assignedTo] — nhân viên phụ trách.
  /// [searchQuery] — tìm theo tên, SĐT, hoặc email (dùng `.or()` + `.ilike()`).
  /// [limit] — số bản ghi tối đa (mặc định 50).
  /// [offset] — vị trí bắt đầu cho phân trang.
  @override
  Future<List<Map<String, dynamic>>> getCustomers({
    String? companyId,
    String? tier,
    String? assignedTo,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    return safeCall(
      operation: 'getCustomers',
      action: () async {
        var query = client.from(tableName).select(_defaultSelect);

        if (companyId != null) {
          query = query.eq('company_id', companyId);
        }
        if (tier != null) {
          query = query.eq('tier', tier);
        }
        if (assignedTo != null) {
          query = query.eq('assigned_to', assignedTo);
        }

        // Tìm kiếm theo name, phone, email — dùng OR + ilike
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final pattern = '%$searchQuery%';
          query = query.or(
            'name.ilike.$pattern,'
            'phone.ilike.$pattern,'
            'email.ilike.$pattern',
          );
        }

        final ordered = query.order('created_at', ascending: false);

        // Phân trang: dùng .range() khi cả offset và limit đều có
        final effectiveLimit = limit ?? 50;
        final effectiveOffset = offset ?? 0;

        return await ordered.range(
          effectiveOffset,
          effectiveOffset + effectiveLimit - 1,
        );
      },
    );
  }

  /// Lấy chi tiết 1 khách hàng theo [id].
  @override
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    return fetchById(id, select: _defaultSelect);
  }

  // ---------------------------------------------------------------------------
  // WRITE
  // ---------------------------------------------------------------------------

  /// Tạo khách hàng mới. [data] phải chứa ít nhất `company_id`, `name`.
  @override
  Future<Map<String, dynamic>> createCustomer(
    Map<String, dynamic> data,
  ) async {
    return insert(data);
  }

  /// Cập nhật thông tin khách hàng. Trả về bản ghi sau update.
  @override
  Future<Map<String, dynamic>> updateCustomer(
    String id,
    Map<String, dynamic> data,
  ) async {
    return update(id, {
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Soft-delete khách hàng (đánh dấu `status = 'inactive'`).
  @override
  Future<void> deleteCustomer(String id) async {
    await client.from(tableName).update({
      'status': 'inactive',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // RELATED DATA
  // ---------------------------------------------------------------------------

  /// Lấy các đơn hàng của khách hàng từ bảng `sales_orders`.
  ///
  /// Sắp xếp mới nhất trước, giới hạn 100 bản ghi.
  @override
  Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId,
  ) async {
    return safeCall(
      operation: 'getCustomerOrders',
      action: () async {
        final result = await client
            .from('sales_orders')
            .select('*')
            .eq('customer_id', customerId)
            .order('created_at', ascending: false)
            .limit(100);
        return result;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // STATS / AGGREGATION
  // ---------------------------------------------------------------------------

  /// Thống kê khách hàng: tổng số, theo tier, theo trạng thái.
  ///
  /// Ưu tiên RPC `get_customer_stats` nếu có, fallback tính trên client.
  @override
  Future<Map<String, dynamic>> getCustomerStats({
    String? companyId,
  }) async {
    return safeCall(
      operation: 'getCustomerStats',
      action: () async {
        // --- Thử RPC trước ---
        try {
          final params = <String, dynamic>{};
          if (companyId != null) params['p_company_id'] = companyId;

          final rpcResult =
              await client.rpc('get_customer_stats', params: params);
          if (rpcResult != null) {
            return rpcResult is Map<String, dynamic>
                ? rpcResult
                : (rpcResult as List).isNotEmpty
                    ? rpcResult.first as Map<String, dynamic>
                    : <String, dynamic>{};
          }
        } catch (_) {
          logInfo(
            'getCustomerStats',
            'RPC not available, using client fallback',
          );
        }

        // --- Fallback: fetch + đếm trên client ---
        var query = client.from(tableName).select('id, tier, is_active');

        if (companyId != null) {
          query = query.eq('company_id', companyId);
        }

        final rows = await query;

        int total = rows.length;
        int active = 0;
        final tierCounts = <String, int>{};

        for (final row in rows) {
          if (row['is_active'] == true) active++;
          final t = (row['tier'] as String?) ?? 'unknown';
          tierCounts[t] = (tierCounts[t] ?? 0) + 1;
        }

        return {
          'total': total,
          'active': active,
          'inactive': total - active,
          'by_tier': tierCounts,
        };
      },
    );
  }

  /// Đếm tổng số khách hàng, tùy chọn lọc theo [companyId].
  @override
  Future<int> getCustomerCount({String? companyId}) async {
    final filters = <String, dynamic>{};
    if (companyId != null) {
      filters['company_id'] = companyId;
    }
    return count(filters: filters.isNotEmpty ? filters : null);
  }

  // ---------------------------------------------------------------------------
  // REALTIME
  // ---------------------------------------------------------------------------

  /// Subscribe realtime các thay đổi bảng `customers`.
  ///
  /// Filter phía client khi [companyId] được truyền.
  @override
  Stream<List<Map<String, dynamic>>> subscribeToCustomers({
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
