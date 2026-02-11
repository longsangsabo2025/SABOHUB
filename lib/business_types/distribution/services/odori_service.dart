// Odori Module Services - B2B Distribution
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/odori_models.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền companyId từ authProvider

class OdoriService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // ⚠️ Lưu companyId từ caller thay vì dùng auth
  final String? companyId;
  
  OdoriService({this.companyId});
  
  // Helper để validate và lấy companyId
  String _getCompanyId([String? overrideCompanyId]) {
    final cid = overrideCompanyId ?? companyId;
    if (cid == null) throw Exception('Company not found');
    return cid;
  }

  // ==================== CUSTOMERS ====================
  
  Future<List<OdoriCustomer>> getCustomers({
    String? search,
    CustomerType? type,
    bool? isActive,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);

    var query = _supabase
        .from('customers')
        .select()
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (type != null) {
      query = query.eq('type', type.name);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('name');
    
    var customers = (response as List)
        .map((json) => OdoriCustomer.fromJson(json))
        .toList();

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      customers = customers.where((c) =>
        c.name.toLowerCase().contains(searchLower) ||
        (c.code?.toLowerCase().contains(searchLower) ?? false) ||
        (c.phone?.contains(search) ?? false)
      ).toList();
    }

    return customers;
  }

  Future<OdoriCustomer?> getCustomerById(String id) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return OdoriCustomer.fromJson(response);
  }

  Future<OdoriCustomer> createCustomer(Map<String, dynamic> data, {String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);

    final response = await _supabase
        .from('customers')
        .insert({
          ...data,
          'company_id': cid,
        })
        .select()
        .single();

    return OdoriCustomer.fromJson(response);
  }

  Future<OdoriCustomer> updateCustomer(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('customers')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return OdoriCustomer.fromJson(response);
  }

  // ==================== PRODUCTS ====================
  
  Future<List<OdoriProduct>> getProducts({
    String? search,
    String? categoryId,
    bool? isActive,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);

    var query = _supabase
        .from('products')
        .select('*, category:category_id(*)')
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('name');
    
    var products = (response as List)
        .map((json) => OdoriProduct.fromJson(json))
        .toList();

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      products = products.where((p) =>
        p.name.toLowerCase().contains(searchLower) ||
        (p.sku?.toLowerCase().contains(searchLower) ?? false) ||
        (p.barcode?.contains(search) ?? false)
      ).toList();
    }

    return products;
  }

  Future<OdoriProduct?> getProductByBarcode(String barcode, {String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);

    final response = await _supabase
        .from('products')
        .select('*, category:category_id(*)')
        .eq('company_id', cid)
        .eq('barcode', barcode)
        .maybeSingle();

    if (response == null) return null;
    return OdoriProduct.fromJson(response);
  }

  Future<List<OdoriProductCategory>> getProductCategories({String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);

    final response = await _supabase
        .from('product_categories')
        .select()
        .eq('company_id', cid)
        .eq('is_active', true)
        .order('sort_order');

    return (response as List)
        .map((json) => OdoriProductCategory.fromJson(json))
        .toList();
  }

  Future<OdoriProduct> createProduct(Map<String, dynamic> data, {String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);

    final response = await _supabase
        .from('products')
        .insert({
          ...data,
          'company_id': cid,
          'is_active': true,
        })
        .select()
        .single();

    return OdoriProduct.fromJson(response);
  }

  // ==================== ORDERS ====================
  
  Future<List<OdoriSalesOrder>> getOrders({
    String? customerId,
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);

    var query = _supabase
        .from('sales_orders')
        .select('*, customer:customer_id(*)')
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (fromDate != null) {
      query = query.gte('order_date', fromDate.toIso8601String().split('T')[0]);
    }
    if (toDate != null) {
      query = query.lte('order_date', toDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => OdoriSalesOrder.fromJson(json))
        .toList();
  }

  Future<OdoriSalesOrder?> getOrderById(String id) async {
    final response = await _supabase
        .from('sales_orders')
        .select('*, customer:customer_id(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return OdoriSalesOrder.fromJson(response);
  }

  Future<List<OdoriOrderItem>> getOrderItems(String orderId) async {
    final response = await _supabase
        .from('sales_order_items')
        .select()
        .eq('order_id', orderId)
        .order('line_number');

    return (response as List)
        .map((json) => OdoriOrderItem.fromJson(json))
        .toList();
  }

  Future<OdoriSalesOrder> createOrder(Map<String, dynamic> orderData, List<Map<String, dynamic>> items, {String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);

    // Generate order number
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final orderNumber = 'SO${DateTime.now().year}$timestamp';

    // Calculate totals
    double subtotal = 0;
    for (var item in items) {
      final lineTotal = (item['quantity'] as int) * (item['unit_price'] as double);
      subtotal += lineTotal;
    }

    // Create order
    final orderResponse = await _supabase
        .from('sales_orders')
        .insert({
          ...orderData,
          'company_id': cid,
          'order_number': orderNumber,
          'order_date': DateTime.now().toIso8601String().split('T')[0],
          'subtotal': subtotal,
          'total': subtotal,
          'status': 'draft',
          'item_count': items.length,
        })
        .select()
        .single();

    final order = OdoriSalesOrder.fromJson(orderResponse);

    // Create order items
    final orderItems = items.asMap().entries.map((entry) {
      final item = entry.value;
      final lineTotal = (item['quantity'] as int) * (item['unit_price'] as double);
      return {
        'order_id': order.id,
        'product_id': item['product_id'],
        'product_name': item['product_name'],
        'product_sku': item['product_sku'],
        'unit': item['unit'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
        'line_total': lineTotal,
        'line_number': entry.key + 1,
      };
    }).toList();

    await _supabase.from('sales_order_items').insert(orderItems);

    return order;
  }

  // ==================== DELIVERIES ====================

  /// Get a single delivery by ID
  Future<OdoriDelivery?> getDeliveryById(String deliveryId, {String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);

    final response = await _supabase
        .from('deliveries')
        .select('*, employees(full_name), delivery_items(*)')
        .eq('id', deliveryId)
        .eq('company_id', cid)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) return null;
    return OdoriDelivery.fromJson(response);
  }
  
  Future<List<OdoriDelivery>> getDeliveries({
    String? driverId,
    DeliveryStatus? status,
    DateTime? date,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);

    var query = _supabase
        .from('deliveries')
        .select('*, customer:customer_id(*)')
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (driverId != null) {
      query = query.eq('driver_id', driverId);
    }
    if (status != null) {
      query = query.eq('status', status.name.replaceAll('inTransit', 'in_progress'));
    }
    if (date != null) {
      query = query.eq('expected_date', date.toIso8601String().split('T')[0]);
    }

    final response = await query.order('expected_date');
    
    return (response as List)
        .map((json) => OdoriDelivery.fromJson(json))
        .toList();
  }

  Future<OdoriDelivery> startDelivery(String id, double? latitude, double? longitude) async {
    final response = await _supabase
        .from('deliveries')
        .update({
          'status': 'in_progress',  // Valid: planned, loading, in_progress, completed, cancelled
          'started_at': DateTime.now().toIso8601String(),
          'start_latitude': latitude,
          'start_longitude': longitude,
        })
        .eq('id', id)
        .select()
        .single();

    return OdoriDelivery.fromJson(response);
  }

  Future<OdoriDelivery> completeDelivery(
    String id, {
    double? latitude,
    double? longitude,
    String? signatureUrl,
  }) async {
    final response = await _supabase
        .from('deliveries')
        .update({
          'status': 'completed',  // valid: planned, loading, in_progress, completed, cancelled
          'completed_at': DateTime.now().toIso8601String(),
          'end_latitude': latitude,
          'end_longitude': longitude,
          'signature_url': signatureUrl,
        })
        .eq('id', id)
        .select('*, order_id')
        .single();

    // Also update sales_orders.delivery_status to 'delivered'
    final orderId = response['order_id'];
    if (orderId != null) {
      await _supabase.from('sales_orders').update({
        'delivery_status': 'delivered',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
    }

    return OdoriDelivery.fromJson(response);
  }

  Future<void> updateDeliveryLocation(String id, double latitude, double longitude) async {
    // Record tracking point
    await _supabase.from('delivery_tracking').insert({
      'delivery_id': id,
      'latitude': latitude,
      'longitude': longitude,
      'recorded_at': DateTime.now().toIso8601String(),
    });

    // Update current location
    await _supabase.from('deliveries').update({
      'current_latitude': latitude,
      'current_longitude': longitude,
      'location_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ==================== RECEIVABLES ====================
  
  Future<List<OdoriReceivable>> getReceivables({
    String? customerId,
    ReceivableStatus? status,
    bool? isOverdue,
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);

    var query = _supabase
        .from('receivables')
        .select('*, customer:customer_id(*)')
        .eq('company_id', cid)
        .isFilter('deleted_at', null);

    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }
    if (status != null) {
      query = query.eq('status', status.name.replaceAll('writtenOff', 'written_off'));
    }

    final response = await query.order('due_date');
    
    var receivables = (response as List)
        .map((json) => OdoriReceivable.fromJson(json))
        .toList();

    if (isOverdue == true) {
      final today = DateTime.now();
      receivables = receivables.where((r) =>
        r.dueDate.isBefore(today) && 
        r.status != ReceivableStatus.paid
      ).toList();
    }

    return receivables;
  }

  Future<OdoriPayment> recordPayment(String receivableId, Map<String, dynamic> paymentData) async {
    // Get current receivable
    final receivable = await _supabase
        .from('receivables')
        .select()
        .eq('id', receivableId)
        .single();

    final currentPaid = (receivable['paid_amount'] as num?)?.toDouble() ?? 0;
    final amount = (paymentData['amount'] as num).toDouble();
    final totalAmount = (receivable['original_amount'] as num).toDouble();
    final newPaidAmount = currentPaid + amount;
    final newRemaining = totalAmount - newPaidAmount;
    final newStatus = newRemaining <= 0 ? 'paid' : 'partial';

    // Generate payment number
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final paymentNumber = 'TT${DateTime.now().year}$timestamp';

    // Create payment
    final paymentResponse = await _supabase
        .from('payments')
        .insert({
          'receivable_id': receivableId,
          'payment_number': paymentNumber,
          'amount': amount,
          'payment_method': paymentData['payment_method'],
          'payment_date': paymentData['payment_date'] ?? DateTime.now().toIso8601String().split('T')[0],
          'reference_number': paymentData['reference_number'],
          'notes': paymentData['notes'],
          'collected_by': paymentData['collected_by'],
          'latitude': paymentData['latitude'],
          'longitude': paymentData['longitude'],
        })
        .select()
        .single();

    // Update receivable
    await _supabase.from('receivables').update({
      'paid_amount': newPaidAmount,
      'remaining_amount': newRemaining > 0 ? newRemaining : 0,
      'status': newStatus,
      'last_payment_date': paymentData['payment_date'] ?? DateTime.now().toIso8601String().split('T')[0],
    }).eq('id', receivableId);

    return OdoriPayment.fromJson(paymentResponse);
  }

  Future<Map<String, dynamic>> getAgingReport({String? overrideCompanyId}) async {
    final cid = _getCompanyId(overrideCompanyId);

    final response = await _supabase
        .from('receivables')
        .select('remaining_amount, due_date, status')
        .eq('company_id', cid)
        .isFilter('deleted_at', null)
        .inFilter('status', ['pending', 'partial']);

    final today = DateTime.now();
    double current = 0;
    double days1to30 = 0;
    double days31to60 = 0;
    double days61to90 = 0;
    double over90days = 0;

    for (final r in response as List) {
      final dueDate = DateTime.parse(r['due_date'] as String);
      final amount = (r['remaining_amount'] as num).toDouble();
      final daysPastDue = today.difference(dueDate).inDays;

      if (daysPastDue <= 0) {
        current += amount;
      } else if (daysPastDue <= 30) {
        days1to30 += amount;
      } else if (daysPastDue <= 60) {
        days31to60 += amount;
      } else if (daysPastDue <= 90) {
        days61to90 += amount;
      } else {
        over90days += amount;
      }
    }

    return {
      'current': current,
      'days1to30': days1to30,
      'days31to60': days31to60,
      'days61to90': days61to90,
      'over90days': over90days,
      'total': current + days1to30 + days31to60 + days61to90 + over90days,
    };
  }
}

// Singleton instance
final odoriService = OdoriService();
