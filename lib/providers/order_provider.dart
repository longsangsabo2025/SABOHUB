import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

/// Order Service Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

/// All Orders Provider
/// Fetches orders for current company
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final service = ref.watch(orderServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) return [];
  
  return await service.getAllOrders(companyId: authState.user!.companyId!);
});

/// Orders by Status Provider
/// Gets orders filtered by status
final ordersByStatusProvider = FutureProvider.family<List<Order>, OrderStatus>((ref, status) async {
  final service = ref.watch(orderServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) return [];
  
  return await service.getOrdersByStatus(status, companyId: authState.user!.companyId!);
});

/// Single Order Provider
/// Gets order details by ID
final orderProvider = FutureProvider.family<Order?, String>((ref, orderId) async {
  final service = ref.watch(orderServiceProvider);
  return await service.getOrderDetails(orderId);
});

/// Orders Stream Provider
/// Real-time orders stream
final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  final service = ref.watch(orderServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) {
    return Stream.value([]);
  }
  
  // Since Supabase doesn't have built-in stream for complex queries,
  // we'll use a periodic refresh approach
  return Stream.periodic(const Duration(seconds: 30), (_) async {
    return await service.getAllOrders(companyId: authState.user!.companyId!);
  }).asyncMap((future) => future);
});

/// Order Actions Provider
/// Provides order CRUD operations
final orderActionsProvider = Provider<OrderActions>((ref) {
  return OrderActions(ref);
});

class OrderActions {
  final Ref ref;
  
  OrderActions(this.ref);
  
  /// Create new order
  Future<Order> createOrder({
    required List<OrderItem> items,
    String? tableId,
    String? tableName,
    String? customerName,
    String? notes,
  }) async {
    final service = ref.read(orderServiceProvider);
    final authState = ref.read(authProvider);
    
    if (authState.user?.companyId == null) {
      throw Exception('Company ID not found');
    }
    
    final order = await service.createOrder(
      companyId: authState.user!.companyId!,
      tableId: tableId,
      tableName: tableName,
      items: items,
      customerName: customerName,
      notes: notes,
    );
    
    // Refresh orders
    ref.invalidate(ordersProvider);
    
    return order;
  }
  
  /// Update order status
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    final service = ref.read(orderServiceProvider);
    
    final order = await service.updateOrderStatus(orderId, status);
    
    // Refresh orders
    ref.invalidate(ordersProvider);
    ref.invalidate(ordersByStatusProvider);
    
    return order;
  }
  
  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    final service = ref.read(orderServiceProvider);
    
    await service.deleteOrder(orderId);
    
    // Refresh orders
    ref.invalidate(ordersProvider);
    ref.invalidate(ordersByStatusProvider);
  }
}