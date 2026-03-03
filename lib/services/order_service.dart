import '../core/services/base_service.dart';
import '../models/order.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền employeeId từ authProvider

/// Order Service (Entertainment)
/// Handles all order-related database operations
class OrderService extends BaseService {

  /// Get all orders
  Future<List<Order>> getAllOrders({String? companyId, String? tableId}) async {
    return safeCall(
      operation: 'getAllOrders',
      action: () async {
        var query = client.from('orders').select('*');

        if (companyId != null) {
          query = query.eq('company_id', companyId);
        }
        if (tableId != null) {
          query = query.eq('table_id', tableId);
        }

        final response = await query.order('created_at', ascending: false);
        return (response as List).map((json) => _orderFromJson(json)).toList();
      },
    );
  }

  /// Get orders by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status,
      {String? companyId}) async {
    return safeCall(
      operation: 'getOrdersByStatus',
      action: () async {
        var query = client.from('orders').select('*');

        if (companyId != null) {
          query = query.eq('company_id', companyId);
        }

        query = query.eq('status', status.name);
        final response = await query.order('created_at', ascending: false);

        return (response as List).map((json) => _orderFromJson(json)).toList();
      },
    );
  }

  /// Create new order
  /// [employeeId] - ID của employee từ authProvider (KHÔNG phải từ auth.currentUser)
  Future<Order> createOrder({
    required String companyId,
    String? tableId,
    String? tableName,
    required List<OrderItem> items,
    String? customerName,
    String? notes,
    String? employeeId,
  }) async {
    return safeCall(
      operation: 'createOrder',
      action: () async {
        final orderData = {
          'id': null, // Auto-generated UUID
          'company_id': companyId,
          'table_id': tableId,
          'table_name': tableName,
          'status': OrderStatus.pending.name,
          'customer_name': customerName,
          'notes': notes,
          'created_by': employeeId,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Insert order header
        final orderResponse =
            await client.from('orders').insert(orderData).select().single();

        final orderId = orderResponse['id'] as String;

        // Insert order items
        final orderItemsData = items.map((item) => {
              'order_id': orderId,
              'menu_item_id': item.menuItemId,
              'menu_item_name': item.menuItemName,
              'quantity': item.quantity,
              'unit_price': item.price,
              'total_price': item.totalPrice,
              'notes': item.notes,
            });

        await client.from('order_items').insert(orderItemsData.toList());

        return _orderFromJson(orderResponse);
      },
    );
  }

  /// Update order status
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    return safeCall(
      operation: 'updateOrderStatus',
      action: () async {
        final response = await client
            .from('orders')
            .update({'status': status.name, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', orderId)
            .select()
            .single();

        return _orderFromJson(response);
      },
    );
  }

  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    return safeCall(
      operation: 'deleteOrder',
      action: () async {
        // Delete order items first
        await client.from('order_items').delete().eq('order_id', orderId);
        
        // Then delete order
        await client.from('orders').delete().eq('id', orderId);
      },
    );
  }

  /// Get order details with items
  Future<Order?> getOrderDetails(String orderId) async {
    return safeCall(
      operation: 'getOrderDetails',
      action: () async {
        final response = await client
            .from('orders')
            .select('*, order_items(*)')
            .eq('id', orderId)
            .single();

        return _orderFromJson(response);
      },
    );
  }

  /// Convert JSON to Order model
  Order _orderFromJson(Map<String, dynamic> json) {
    // Parse order items if available
    List<OrderItem> items = [];
    if (json['order_items'] != null) {
      items = (json['order_items'] as List)
          .map((itemJson) => OrderItem(
                menuItemId: itemJson['menu_item_id'] as String,
                menuItemName: itemJson['menu_item_name'] as String,
                price: (itemJson['unit_price'] as num).toDouble(),
                quantity: itemJson['quantity'] as int,
                notes: itemJson['notes'] as String?,
              ))
          .toList();
    }

    return Order(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      tableId: json['table_id'] as String?,
      tableName: json['table_name'] as String?,
      items: items,
      status: _parseOrderStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: json['customer_name'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Parse order status from string
  OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}