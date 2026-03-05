import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../base_repository.dart';
import '../i_sales_order_repository.dart';

/// Riverpod provider — singleton instance
final salesOrderRepositoryProvider = Provider<SalesOrderRepository>(
  (ref) => SalesOrderRepository(),
);

/// Concrete implementation of [ISalesOrderRepository].
///
/// Quản lý toàn bộ truy vấn bảng `sales_orders` qua Supabase,
/// bao gồm join với `customers`, `order_items`, `employees`.
///
/// Tất cả method đều dùng [safeCall] để thống nhất error handling.
class SalesOrderRepository extends BaseRepository
    implements ISalesOrderRepository {
  @override
  String get tableName => 'sales_orders';

  // ---------------------------------------------------------------------------
  // Select patterns — dùng chung cho nhiều query
  // ---------------------------------------------------------------------------

  /// Select cơ bản kèm join customer + employee
  static const String _defaultSelect = '''
*, 
customers:customer_id(id, name, phone, email), 
employees:assigned_to(id, full_name, email)
''';

  /// Select chi tiết kèm order_items
  static const String _detailSelect = '''
*, 
customers:customer_id(id, name, phone, email), 
employees:assigned_to(id, full_name, email), 
order_items(*)
''';

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  /// Lấy danh sách đơn hàng với nhiều bộ lọc.
  ///
  /// [companyId] — lọc theo công ty (bắt buộc trong hầu hết use-case).
  /// [status] — trạng thái đơn (pending, confirmed, delivered, cancelled…).
  /// [assignedTo] — ID nhân viên được giao xử lý.
  /// [fromDate] / [toDate] — khoảng thời gian tạo đơn.
  /// [limit] — giới hạn số bản ghi trả về.
  @override
  Future<List<Map<String, dynamic>>> getOrders({
    String? companyId,
    String? status,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return safeCall(
      operation: 'getOrders',
      action: () async {
        var query = client.from(tableName).select(_defaultSelect);

        if (companyId != null) {
          query = query.eq('company_id', companyId);
        }
        if (status != null) {
          query = query.eq('status', status);
        }
        if (assignedTo != null) {
          query = query.eq('assigned_to', assignedTo);
        }
        if (fromDate != null) {
          query = query.gte('created_at', fromDate.toIso8601String());
        }
        if (toDate != null) {
          query = query.lte('created_at', toDate.toIso8601String());
        }

        final ordered = query.order('created_at', ascending: false);

        if (limit != null) {
          return await ordered.limit(limit);
        }
        return await ordered;
      },
    );
  }

  /// Lấy chi tiết 1 đơn hàng theo [id], bao gồm order_items.
  @override
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    return safeCall(
      operation: 'getOrderById',
      action: () async {
        final result = await client
            .from(tableName)
            .select(_detailSelect)
            .eq('id', id)
            .maybeSingle();
        return result;
      },
    );
  }

  /// Lấy danh sách items của 1 đơn hàng.
  @override
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    return safeCall(
      operation: 'getOrderItems',
      action: () async {
        final result = await client
            .from('order_items')
            .select('*')
            .eq('order_id', orderId)
            .order('created_at', ascending: true);
        return result;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WRITE
  // ---------------------------------------------------------------------------

  /// Tạo đơn hàng mới. [data] phải chứa ít nhất `company_id`.
  @override
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    return safeCall(
      operation: 'createOrder',
      action: () async {
        final result = await client
            .from(tableName)
            .insert(data)
            .select(_defaultSelect)
            .single();
        return result;
      },
    );
  }

  /// Cập nhật đơn hàng. Trả về bản ghi sau khi update.
  @override
  Future<Map<String, dynamic>> updateOrder(
    String id,
    Map<String, dynamic> data,
  ) async {
    return safeCall(
      operation: 'updateOrder',
      action: () async {
        final result = await client
            .from(tableName)
            .update({
              ...data,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select(_defaultSelect)
            .single();
        return result;
      },
    );
  }

  /// Chỉ cập nhật trạng thái đơn hàng.
  @override
  Future<void> updateOrderStatus(String id, String status) async {
    return safeCall(
      operation: 'updateOrderStatus',
      action: () async {
        await client.from(tableName).update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      },
    );
  }

  /// Soft-delete đơn hàng (đánh dấu is_deleted = true).
  @override
  Future<void> deleteOrder(String id) async {
    return softDelete(id);
  }

  // ---------------------------------------------------------------------------
  // STATS / AGGREGATION
  // ---------------------------------------------------------------------------

  /// Lấy thống kê đơn hàng: tổng số, theo trạng thái, tổng doanh thu.
  ///
  /// Ưu tiên gọi Supabase RPC `get_order_stats` nếu có.
  /// Nếu RPC chưa tồn tại → fallback fetch + tính toán trên client.
  @override
  Future<Map<String, dynamic>> getOrderStats({
    String? companyId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return safeCall(
      operation: 'getOrderStats',
      action: () async {
        // --- Thử gọi RPC trước (nhanh hơn, tính trên server) ---
        try {
          final params = <String, dynamic>{};
          if (companyId != null) params['p_company_id'] = companyId;
          if (fromDate != null) {
            params['p_from_date'] = fromDate.toIso8601String();
          }
          if (toDate != null) {
            params['p_to_date'] = toDate.toIso8601String();
          }

          final rpcResult =
              await client.rpc('get_order_stats', params: params);
          if (rpcResult != null) {
            return rpcResult is Map<String, dynamic>
                ? rpcResult
                : (rpcResult as List).isNotEmpty
                    ? rpcResult.first as Map<String, dynamic>
                    : <String, dynamic>{};
          }
        } catch (_) {
          // RPC chưa tồn tại → fallback bên dưới
          logInfo('getOrderStats', 'RPC not available, using client fallback');
        }

        // --- Fallback: fetch tất cả rồi tính trên client ---
        var query = client.from(tableName).select('id, status, total_amount');

        if (companyId != null) {
          query = query.eq('company_id', companyId);
        }
        if (fromDate != null) {
          query = query.gte('created_at', fromDate.toIso8601String());
        }
        if (toDate != null) {
          query = query.lte('created_at', toDate.toIso8601String());
        }

        final rows = await query;

        int total = rows.length;
        int pending = 0;
        int confirmed = 0;
        int delivered = 0;
        int cancelled = 0;
        double totalRevenue = 0;

        for (final row in rows) {
          final s = row['status'] as String?;
          final amount = (row['total_amount'] as num?)?.toDouble() ?? 0;

          switch (s) {
            case 'pending':
              pending++;
              break;
            case 'confirmed':
              confirmed++;
              totalRevenue += amount;
              break;
            case 'delivered':
              delivered++;
              totalRevenue += amount;
              break;
            case 'cancelled':
              cancelled++;
              break;
          }
        }

        return {
          'total': total,
          'pending': pending,
          'confirmed': confirmed,
          'delivered': delivered,
          'cancelled': cancelled,
          'total_revenue': totalRevenue,
        };
      },
    );
  }

  // ---------------------------------------------------------------------------
  // REALTIME
  // ---------------------------------------------------------------------------

  /// Subscribe realtime thay đổi bảng `sales_orders`.
  ///
  /// Supabase stream không hỗ trợ filter phức tạp nên filter phía client
  /// khi [companyId] được truyền vào.
  @override
  Stream<List<Map<String, dynamic>>> subscribeToOrders({
    String? companyId,
  }) {
    final stream = client.from(tableName).stream(primaryKey: ['id']);

    if (companyId != null) {
      return stream.map(
        (rows) => rows
            .where((row) => row['company_id'] == companyId)
            .toList(),
      );
    }
    return stream;
  }
}
