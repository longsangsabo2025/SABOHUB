import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sabohub/utils/postgrest_sanitizer.dart';
import '../../../utils/app_logger.dart';
import '../models/odori_customer.dart';
import '../models/odori_product.dart';
import '../models/odori_sales_order.dart';
import '../models/odori_delivery.dart';
import '../models/odori_receivable.dart';
import '../../../models/inventory_movement.dart';
import '../models/product_sample.dart';
import '../../../models/referrer.dart';
import '../../../providers/auth_provider.dart';

final supabase = Supabase.instance.client;

/// Exception thrown when auth is still loading
class _AuthLoadingException implements Exception {
  const _AuthLoadingException();
  @override
  String toString() => 'Đang tải thông tin đăng nhập...';
}

// ============================================================================
// CUSTOMERS PROVIDER
// ============================================================================
final customersProvider = FutureProvider.autoDispose
    .family<List<OdoriCustomer>, CustomerFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  AppLogger.data('customersProvider: START', {'companyId': companyId, 'channel': filters.channel, 'search': filters.search});
  
  if (companyId == null) {
    AppLogger.warn('customersProvider: companyId is NULL');
    return [];
  }

  try {
    var query = supabase
        .from('customers')
        .select('*, employees(full_name), referrers(name)')
        .eq('company_id', companyId);

    if (filters.status != null) {
      query = query.eq('status', filters.status!);
    }
    if (filters.customerType != null) {
      query = query.eq('type', filters.customerType!); // DB uses 'type' not 'customer_type'
    }
    if (filters.channel != null) {
      query = query.eq('channel', filters.channel!);
    }
    if (filters.search != null && filters.search!.isNotEmpty) {
      query = query.or('name.ilike.%${PostgrestSanitizer.sanitizeSearch(filters.search!)}%,code.ilike.%${PostgrestSanitizer.sanitizeSearch(filters.search!)}%'); // DB uses 'code' not 'customer_code'
    }

    // Pagination: limit results for better performance
    final limit = filters.limit ?? 50;
    final offset = filters.offset ?? 0;
    
    AppLogger.data('customersProvider: Executing query', {'limit': limit, 'offset': offset});
    
    final response = await query
        .order('last_order_date', ascending: false, nullsFirst: false) // Ưu tiên KH mới mua gần đây
        .range(offset, offset + limit - 1);
    
    AppLogger.info('customersProvider: loaded ${(response as List).length} customers (offset=$offset, limit=$limit)');
    return response.map((json) => OdoriCustomer.fromJson(json)).toList();
  } catch (e, stack) {
    AppLogger.error('customersProvider ERROR', e, stack);
    rethrow;
  }
});

class CustomerFilters {
  final String? status;
  final String? customerType;
  final String? channel;
  final String? search;
  final int? limit;
  final int? offset;

  const CustomerFilters({
    this.status, 
    this.customerType, 
    this.channel, 
    this.search,
    this.limit,
    this.offset,
  });
  
  CustomerFilters copyWith({
    String? status,
    String? customerType,
    String? channel,
    String? search,
    int? limit,
    int? offset,
  }) {
    return CustomerFilters(
      status: status ?? this.status,
      customerType: customerType ?? this.customerType,
      channel: channel ?? this.channel,
      search: search ?? this.search,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

// ============================================================================
// PRODUCTS PROVIDER
// ============================================================================
final productsProvider = FutureProvider.autoDispose
    .family<List<OdoriProduct>, ProductFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  var query = supabase
      .from('products')
      .select('*, product_categories(name)')
      .eq('company_id', companyId);

  if (filters.categoryId != null) {
    query = query.eq('category_id', filters.categoryId!);
  }
  if (filters.isActive != null) {
    // DB uses 'status' column instead of 'is_active' boolean
    query = query.eq('status', filters.isActive! ? 'active' : 'inactive');
  }
  if (filters.search != null && filters.search!.isNotEmpty) {
    query = query.or('name.ilike.%${PostgrestSanitizer.sanitizeSearch(filters.search!)}%,sku.ilike.%${PostgrestSanitizer.sanitizeSearch(filters.search!)}%');
  }

  final response = await query.order('name');
  return (response as List).map((json) => OdoriProduct.fromJson(json)).toList();
});

final productCategoriesProvider = FutureProvider.autoDispose<List<OdoriProductCategory>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('product_categories')
      .select()
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('sort_order');

  return (response as List).map((json) => OdoriProductCategory.fromJson(json)).toList();
});

class ProductFilters {
  final String? categoryId;
  final bool? isActive;
  final String? search;

  const ProductFilters({this.categoryId, this.isActive, this.search});
}

// ============================================================================
// SALES ORDERS PROVIDER
// ============================================================================
final salesOrdersProvider = FutureProvider.autoDispose
    .family<List<OdoriSalesOrder>, OrderFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  
  // Wait for auth to finish initializing
  if (user == null) {
    AppLogger.info('salesOrdersProvider: Waiting for auth to initialize...');
    // Throw a special "loading" exception to show loading state
    throw const _AuthLoadingException();
  }
  
  final companyId = user.companyId;
  AppLogger.data('salesOrdersProvider', {'user': user.name, 'companyId': companyId, 'status': filters.status});
  
  if (companyId == null) {
    AppLogger.warn('salesOrdersProvider: companyId is NULL - user may not have company assigned');
    // Throw error so UI can show proper message instead of silent empty list
    throw Exception('Không tìm thấy công ty. Vui lòng liên hệ Admin để được gán vào công ty.');
  }

  var query = supabase
      .from('sales_orders')
      .select('*, customers(name), employees(full_name), warehouses(name)')
      .eq('company_id', companyId)
      .isFilter('rejected_at', null);

  if (filters.status != null) {
    query = query.eq('status', filters.status!);
  }
  if (filters.customerId != null) {
    query = query.eq('customer_id', filters.customerId!);
  }
  if (filters.dateFrom != null) {
    query = query.gte('order_date', filters.dateFrom!.toIso8601String());
  }
  if (filters.dateTo != null) {
    query = query.lte('order_date', filters.dateTo!.toIso8601String());
  }

  final response = await query.order('order_date', ascending: false).limit(500);
  AppLogger.info('salesOrdersProvider: loaded ${(response as List).length} orders');
  return response.map((json) => OdoriSalesOrder.fromJson(json)).toList();
});

final salesOrderDetailProvider = FutureProvider.autoDispose
    .family<OdoriSalesOrder?, String>((ref, orderId) async {
  final response = await supabase
      .from('sales_orders')
      .select('*, customers(name), employees(full_name), warehouses(name), sales_order_items(*, products(name, sku))')
      .eq('id', orderId)
      .isFilter('rejected_at', null)
      .single();

  return OdoriSalesOrder.fromJson(response);
});

final pendingApprovalsProvider = FutureProvider.autoDispose<List<OdoriSalesOrder>>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  // Wait for auth to finish initializing
  if (user == null) {
    AppLogger.info('pendingApprovalsProvider: Waiting for auth to initialize...');
    return [];
  }
  
  final companyId = user.companyId;
  AppLogger.data('pendingApprovalsProvider', {'companyId': companyId});
  
  if (companyId == null) {
    AppLogger.warn('pendingApprovalsProvider: companyId is NULL');
    return []; // For badge count, return empty instead of error
  }

  final response = await supabase
      .from('sales_orders')
      .select('*, customers(name), employees(full_name)')
      .eq('company_id', companyId)
      .isFilter('rejected_at', null)
      .eq('status', 'pending_approval')
      .order('created_at');

  AppLogger.info('pendingApprovalsProvider: loaded ${(response as List).length} pending orders');
  return response.map((json) => OdoriSalesOrder.fromJson(json)).toList();
});

class OrderFilters {
  final String? status;
  final String? customerId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const OrderFilters({this.status, this.customerId, this.dateFrom, this.dateTo});
}

// ============================================================================
// DELIVERIES PROVIDER
// ============================================================================
final deliveriesProvider = FutureProvider.autoDispose
    .family<List<OdoriDelivery>, DeliveryFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  var query = supabase
      .from('deliveries')
      .select('*, employees(full_name)')
      .eq('company_id', companyId);

  if (filters.status != null) {
    query = query.eq('status', filters.status!);
  }
  if (filters.date != null) {
    query = query.eq('delivery_date', filters.date!.toIso8601String().split('T')[0]);
  }
  if (filters.driverId != null) {
    query = query.eq('driver_id', filters.driverId!);
  }

  final response = await query.order('delivery_date', ascending: false).limit(500);
  return (response as List).map((json) => OdoriDelivery.fromJson(json)).toList();
});

final deliveryDetailProvider = FutureProvider.autoDispose
    .family<OdoriDelivery?, String>((ref, deliveryId) async {
  final response = await supabase
      .from('deliveries')
      .select('*, employees(full_name), delivery_items(*, sales_orders(order_number))')
      .eq('id', deliveryId)
      .single();

  return OdoriDelivery.fromJson(response);
});

final activeDeliveriesProvider = FutureProvider.autoDispose<List<OdoriDelivery>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('deliveries')
      .select('*, employees(full_name)')
      .eq('company_id', companyId)
      .eq('status', 'in_progress')
      .order('started_at');

  return (response as List).map((json) => OdoriDelivery.fromJson(json)).toList();
});

class DeliveryFilters {
  final String? status;
  final DateTime? date;
  final String? driverId;

  const DeliveryFilters({this.status, this.date, this.driverId});
}

// ============================================================================
// RECEIVABLES PROVIDER
// ============================================================================
final receivablesProvider = FutureProvider.autoDispose
    .family<List<OdoriReceivable>, ReceivableFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  var query = supabase
      .from('receivables')
      .select('*, customers(name), sales_orders(order_number)')
      .eq('company_id', companyId);

  if (filters.status != null) {
    query = query.eq('status', filters.status!);
  }
  if (filters.customerId != null) {
    query = query.eq('customer_id', filters.customerId!);
  }

  final response = await query.order('due_date');
  return (response as List).map((json) => OdoriReceivable.fromJson(json)).toList();
});

final overdueReceivablesProvider = FutureProvider.autoDispose<List<OdoriReceivable>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  final today = DateTime.now().toIso8601String().split('T')[0];
  final response = await supabase
      .from('receivables')
      .select('*, customers(name)')
      .eq('company_id', companyId)
      .inFilter('status', ['open', 'partial'])
      .lt('due_date', today)
      .order('due_date');

  return (response as List).map((json) => OdoriReceivable.fromJson(json)).toList();
});

class ReceivableFilters {
  final String? status;
  final String? customerId;

  const ReceivableFilters({this.status, this.customerId});
}

// ============================================================================
// PAYMENTS PROVIDER
// ============================================================================
final paymentsProvider = FutureProvider.autoDispose
    .family<List<OdoriPayment>, PaymentFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  var query = supabase
      .from('payments')
      .select('*, customers(name), employees(full_name)')
      .eq('company_id', companyId);

  if (filters.customerId != null) {
    query = query.eq('customer_id', filters.customerId!);
  }
  if (filters.dateFrom != null) {
    query = query.gte('payment_date', filters.dateFrom!.toIso8601String());
  }
  if (filters.dateTo != null) {
    query = query.lte('payment_date', filters.dateTo!.toIso8601String());
  }

  final response = await query.order('payment_date', ascending: false);
  return (response as List).map((json) => OdoriPayment.fromJson(json)).toList();
});

class PaymentFilters {
  final String? customerId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const PaymentFilters({this.customerId, this.dateFrom, this.dateTo});
}

// ============================================================================
// INVENTORY MOVEMENTS PROVIDER
// ============================================================================
final inventoryMovementsProvider = FutureProvider.autoDispose
    .family<List<InventoryMovement>, InventoryFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  var query = supabase
      .from('inventory_movements')
      .select('*, products(name, sku)')
      .eq('company_id', companyId);

  if (filters.productId != null) {
    query = query.eq('product_id', filters.productId!);
  }
  if (filters.type != null) {
    query = query.eq('type', filters.type!);
  }

  final response = await query.order('created_at', ascending: false).limit(100);
  return (response as List).map((json) => InventoryMovement.fromJson(json)).toList();
});

class InventoryFilters {
  final String? productId;
  final String? type;
  const InventoryFilters({this.productId, this.type});
}

// ============================================================================
// DASHBOARD STATS PROVIDERS
// ============================================================================

/// Dashboard statistics model
class OdoriDashboardStats {
  final int totalCustomers;
  final int activeCustomers;
  final int totalProducts;
  final int pendingOrders;
  final int inProgressDeliveries;
  final int completedOrdersToday;
  final double todaySales;       // Tổng doanh số (tất cả đơn delivered)
  final double todayRevenue;     // Doanh thu đã thu (delivered + paid)
  final double monthSales;       // Doanh số tháng
  final double monthRevenue;     // Doanh thu tháng đã thu
  final double totalReceivables;
  final double overdueReceivables;

  const OdoriDashboardStats({
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.totalProducts = 0,
    this.pendingOrders = 0,
    this.inProgressDeliveries = 0,
    this.completedOrdersToday = 0,
    this.todaySales = 0,
    this.todayRevenue = 0,
    this.monthSales = 0,
    this.monthRevenue = 0,
    this.totalReceivables = 0,
    this.overdueReceivables = 0,
  });
}

/// Provider for dashboard statistics
final dashboardStatsProvider = FutureProvider.autoDispose<OdoriDashboardStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return const OdoriDashboardStats();

  try {
    // Get customer counts
    final customersResult = await supabase
        .from('customers')
        .select('id, status')
        .eq('company_id', companyId);
    final customers = customersResult as List;
    final totalCustomers = customers.length;
    final activeCustomers = customers.where((c) => c['status'] == 'active').length;

    // Get product count
    final productsResult = await supabase
        .from('products')
        .select('id')
        .eq('company_id', companyId)
        .eq('status', 'active');
    final totalProducts = (productsResult as List).length;

    // Get order stats
    final ordersResult = await supabase
        .from('sales_orders')
        .select('id, status, delivery_status, payment_status, total, created_at, updated_at')
      .eq('company_id', companyId)
      .isFilter('rejected_at', null);
    final orders = ordersResult as List;
    
    // Đơn chờ xử lý: delivery_status = pending hoặc null (chưa giao)
    final pendingOrders = orders.where((o) {
      final status = o['status']?.toString() ?? '';
      final deliveryStatus = o['delivery_status']?.toString() ?? '';
      // Không tính đơn đã hủy
      if (status == 'cancelled') return false;
      // Đơn chờ xử lý = chưa giao hoặc đang chờ
      return deliveryStatus.isEmpty || 
             deliveryStatus == 'pending' || 
             deliveryStatus == 'null' ||
             deliveryStatus == 'awaiting_pickup';
    }).length;
    
    final today = DateTime.now();
    // Lấy ngày bắt đầu của hôm nay (00:00:00 UTC)
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    // Cho phép lệch timezone (VN = UTC+7), check trong 24h gần nhất
    final yesterdayStart = todayStart.subtract(const Duration(hours: 7));
    
    // Hoàn thành hôm nay: delivery_status = delivered và updated_at trong 24h
    final completedToday = orders.where((o) {
      final deliveryStatus = o['delivery_status']?.toString() ?? '';
      final updatedAtStr = o['updated_at']?.toString() ?? '';
      if (deliveryStatus != 'delivered' || updatedAtStr.isEmpty) return false;
      
      try {
        final updatedAt = DateTime.parse(updatedAtStr);
        return updatedAt.isAfter(yesterdayStart);
      } catch (e) {
        AppLogger.warn('Date parse error in completedToday filter: $e');
        return false;
      }
    }).length;

    // Calculate revenue - tính doanh số theo ngày tạo đơn (created_at) khớp với Reports page
    // Dùng created_at (ngày tạo đơn) thay vì updated_at, và tính tất cả đơn non-cancelled
    double todaySales = 0;    // Tổng doanh số hôm nay (tất cả đơn non-cancelled)
    double todayRevenue = 0;  // Doanh thu đã thu hôm nay (non-cancelled + paid)
    double monthSales = 0;
    double monthRevenue = 0;
    // Dùng cùng cách tính ngày với Reports page: DateTime local → so sánh UTC
    final todayDayStart = DateTime.utc(today.year, today.month, today.day);
    final monthDayStart = DateTime.utc(today.year, today.month, 1);
    
    for (final order in orders) {
      final status = order['status']?.toString() ?? '';
      if (status == 'cancelled') continue;
      
      final paymentStatus = order['payment_status']?.toString() ?? '';
      final total = (order['total'] as num?)?.toDouble() ?? 0;
      final createdAtStr = order['created_at']?.toString() ?? '';
      
      if (createdAtStr.isEmpty) continue;
      
      try {
        final createdAt = DateTime.parse(createdAtStr);
        
        // Doanh số hôm nay (theo created_at, khớp Reports page)
        if (!createdAt.isBefore(todayDayStart)) {
          todaySales += total;
          if (paymentStatus == 'paid') {
            todayRevenue += total;
          }
        }
        // Doanh số tháng này
        if (!createdAt.isBefore(monthDayStart)) {
          monthSales += total;
          if (paymentStatus == 'paid') {
            monthRevenue += total;
          }
        }
      } catch (e) {
        AppLogger.warn('Order data parse error in dashboard: $e');
        continue;
      }
    }

    // Get delivery stats - từ cả deliveries table và sales_orders
    final deliveriesResult = await supabase
        .from('deliveries')
        .select('id, status')
        .eq('company_id', companyId);
    final deliveries = deliveriesResult as List;
    final inProgressFromDeliveries = deliveries.where((d) => 
        d['status'] == 'in_progress' || d['status'] == 'loading'
    ).length;
    
    // Cũng đếm từ sales_orders có delivery_status = delivering
    final inProgressFromOrders = orders.where((o) {
      final deliveryStatus = o['delivery_status']?.toString() ?? '';
      return deliveryStatus == 'delivering' || deliveryStatus == 'awaiting_pickup';
    }).length;
    
    // Lấy số lớn hơn (tránh đếm trùng)
    final inProgressDeliveries = inProgressFromDeliveries > inProgressFromOrders 
        ? inProgressFromDeliveries 
        : inProgressFromOrders;

    // Get receivables
    final receivablesResult = await supabase
        .from('receivables')
        .select('original_amount, paid_amount, due_date, status')
        .eq('company_id', companyId)
        .inFilter('status', ['open', 'partial']);
    final receivables = receivablesResult as List;
    
    double totalReceivables = 0;
    double overdueReceivables = 0;
    
    for (final r in receivables) {
      final originalAmount = (r['original_amount'] as num?)?.toDouble() ?? 0;
      final paidAmount = (r['paid_amount'] as num?)?.toDouble() ?? 0;
      final outstandingAmount = originalAmount - paidAmount;
      totalReceivables += outstandingAmount;
      
      if (r['due_date'] != null) {
        final dueDate = DateTime.parse(r['due_date'] as String);
        if (dueDate.isBefore(today)) {
          overdueReceivables += outstandingAmount;
        }
      }
    }

    return OdoriDashboardStats(
      totalCustomers: totalCustomers,
      activeCustomers: activeCustomers,
      totalProducts: totalProducts,
      pendingOrders: pendingOrders,
      inProgressDeliveries: inProgressDeliveries,
      completedOrdersToday: completedToday,
      todaySales: todaySales,
      todayRevenue: todayRevenue,
      monthSales: monthSales,
      monthRevenue: monthRevenue,
      totalReceivables: totalReceivables,
      overdueReceivables: overdueReceivables,
    );
  } catch (e) {
    AppLogger.error('Error loading dashboard stats: $e');
    return const OdoriDashboardStats();
  }
});

/// Provider for recent orders
final recentOrdersProvider = FutureProvider.autoDispose<List<OdoriSalesOrder>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('sales_orders')
      .select('*, customers(name)')
      .eq('company_id', companyId)
      .isFilter('rejected_at', null)
      .order('created_at', ascending: false)
      .limit(10);

  return (response as List).map((json) => OdoriSalesOrder.fromJson(json)).toList();
});

/// Provider for all customers (simple list)
final allCustomersProvider = FutureProvider.autoDispose<List<OdoriCustomer>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('customers')
      .select('*, employees(full_name)')
      .eq('company_id', companyId)
      .eq('status', 'active')
      .order('name')
      .limit(1000);

  return (response as List).map((json) => OdoriCustomer.fromJson(json)).toList();
});

/// Provider for all products (simple list)
final allProductsProvider = FutureProvider.autoDispose<List<OdoriProduct>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('products')
      .select('*, product_categories(name)')
      .eq('company_id', companyId)
      .eq('status', 'active')
      .order('name');

  return (response as List).map((json) => OdoriProduct.fromJson(json)).toList();
});

// ============================================================================
// PRODUCT SAMPLES PROVIDER
// ============================================================================
final productSamplesProvider = FutureProvider.autoDispose
    .family<List<ProductSample>, ProductSampleFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  var query = supabase
      .from('product_samples')
      .select('*, customers(name), products(name, sku), employees(full_name)')
      .eq('company_id', companyId);

  if (filters.status != null) {
    query = query.eq('status', filters.status!);
  } else {
    query = query.or('status.is.null,status.neq.cancelled');
  }
  if (filters.customerId != null) {
    query = query.eq('customer_id', filters.customerId!);
  }
  if (filters.productId != null) {
    query = query.eq('product_id', filters.productId!);
  }
  if (filters.search != null && filters.search!.isNotEmpty) {
    query = query.or('product_name.ilike.%${PostgrestSanitizer.sanitizeSearch(filters.search!)}%,notes.ilike.%${PostgrestSanitizer.sanitizeSearch(filters.search!)}%');
  }

  final response = await query.order('sent_date', ascending: false);
  return (response as List).map((json) => ProductSample.fromJson(json)).toList();
});

// ============================================================================
// REFERRERS PROVIDER - Người giới thiệu
// ============================================================================
final referrersProvider = FutureProvider.autoDispose
    .family<List<Referrer>, ReferrerFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  var query = supabase
      .from('referrers')
      .select()
      .eq('company_id', companyId);

  if (filters.status != null) {
    query = query.eq('status', filters.status!);
  }
  if (filters.search != null && filters.search!.isNotEmpty) {
    query = query.or('name.ilike.%${PostgrestSanitizer.sanitizeSearch(filters.search!)}%,phone.ilike.%${PostgrestSanitizer.sanitizeSearch(filters.search!)}%');
  }

  final response = await query.order('name');
  return (response as List).map((json) => Referrer.fromJson(json)).toList();
});

class ReferrerFilters {
  final String? status;
  final String? search;

  const ReferrerFilters({this.status, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferrerFilters &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          search == other.search;

  @override
  int get hashCode => status.hashCode ^ search.hashCode;
}

/// Provider cho danh sách referrers active (dùng trong dropdown)
final activeReferrersProvider = FutureProvider.autoDispose<List<Referrer>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('referrers')
      .select()
      .eq('company_id', companyId)
      .eq('status', 'active')
      .order('name');

  return (response as List).map((json) => Referrer.fromJson(json)).toList();
});

// ============================================================================
// COMMISSIONS PROVIDER - Hoa hồng
// ============================================================================
final commissionsProvider = FutureProvider.autoDispose
    .family<List<Commission>, CommissionFilters>((ref, filters) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  var query = supabase
      .from('commissions')
      .select('*, referrers(name), customers(name)')
      .eq('company_id', companyId);

  if (filters.status != null) {
    query = query.eq('status', filters.status!);
  }
  if (filters.referrerId != null) {
    query = query.eq('referrer_id', filters.referrerId!);
  }

  final response = await query.order('created_at', ascending: false);
  return (response as List).map((json) => Commission.fromJson(json)).toList();
});

class CommissionFilters {
  final String? status;
  final String? referrerId;

  const CommissionFilters({this.status, this.referrerId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionFilters &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          referrerId == other.referrerId;

  @override
  int get hashCode => status.hashCode ^ referrerId.hashCode;
}

