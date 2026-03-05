import '../../models/order.dart';

/// Abstract interface cho OrderService.
///
/// Cho phép:
/// - Mock trong unit tests
/// - Swap implementation mà không sửa consumer code
/// - Enforce contract rõ ràng
///
/// Tất cả code mới nên depend on [IOrderService] thay vì [OrderService].
abstract class IOrderService {
  /// Get all orders, optionally filtered by company/table.
  Future<List<Order>> getAllOrders({String? companyId, String? tableId});

  /// Get orders filtered by status.
  Future<List<Order>> getOrdersByStatus(
    OrderStatus status, {
    String? companyId,
  });

  /// Create a new order with items.
  Future<Order> createOrder({
    required String companyId,
    String? tableId,
    String? tableName,
    required List<OrderItem> items,
    String? customerName,
    String? notes,
    String? employeeId,
  });

  /// Update order status.
  Future<Order> updateOrderStatus(String orderId, OrderStatus status);

  /// Delete (soft) an order.
  Future<void> deleteOrder(String orderId);

  /// Get order with full details including items.
  Future<Order?> getOrderDetails(String orderId);
}
