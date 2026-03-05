/// Interface for Sales Order data access
/// Extracted from 39 files directly accessing 'sales_orders' table (115 hits)
abstract class ISalesOrderRepository {
  Future<List<Map<String, dynamic>>> getOrders({
    String? companyId,
    String? status,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  });
  Future<Map<String, dynamic>?> getOrderById(String id);
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateOrder(
      String id, Map<String, dynamic> data);
  Future<void> updateOrderStatus(String id, String status);
  Future<void> deleteOrder(String id);
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId);
  Future<Map<String, dynamic>> getOrderStats({
    String? companyId,
    DateTime? fromDate,
    DateTime? toDate,
  });
  Stream<List<Map<String, dynamic>>> subscribeToOrders({String? companyId});
}
