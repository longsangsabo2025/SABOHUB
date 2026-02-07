import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sell-In Transaction Model (Company → Distributor)
/// Flow: Công ty xuất hàng → NPP nhập hàng
class SellInTransaction {
  final String id;
  final String companyId;
  final String distributorId;
  final String transactionCode; // DB uses transaction_code
  final DateTime transactionDate;
  final String status;
  final String? fromWarehouseId;
  final String? salesOrderId;
  final String? deliveryId;
  final int totalQuantity;
  final double totalAmount;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  
  // Joined data
  final String? distributorName;
  final String? warehouseName;
  final List<SellInItem>? items;

  SellInTransaction({
    required this.id,
    required this.companyId,
    required this.distributorId,
    required this.transactionCode,
    required this.transactionDate,
    this.status = 'pending',
    this.fromWarehouseId,
    this.salesOrderId,
    this.deliveryId,
    this.totalQuantity = 0,
    this.totalAmount = 0,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.distributorName,
    this.warehouseName,
    this.items,
  });

  factory SellInTransaction.fromJson(Map<String, dynamic> json) {
    return SellInTransaction(
      id: json['id'],
      companyId: json['company_id'],
      distributorId: json['distributor_id'],
      transactionCode: json['transaction_code'] ?? '',
      transactionDate: DateTime.parse(json['transaction_date']),
      status: json['status'] ?? 'pending',
      fromWarehouseId: json['from_warehouse_id'],
      salesOrderId: json['sales_order_id'],
      deliveryId: json['delivery_id'],
      totalQuantity: json['total_quantity'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      notes: json['notes'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      distributorName: json['customers']?['name'] ?? json['distributor']?['name'],
      warehouseName: json['warehouses']?['name'],
      items: json['sell_in_items'] != null
          ? (json['sell_in_items'] as List)
              .map((i) => SellInItem.fromJson(i))
              .toList()
          : null,
    );
  }

  int get itemCount => items?.length ?? 0;
  
  // Alias for backward compatibility
  String get transactionNumber => transactionCode;
}

/// Sell-In Item Model
class SellInItem {
  final String id;
  final String sellInId; // DB uses sell_in_id
  final String productId;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double totalAmount;
  final String? batchNumber;
  final DateTime? expiryDate;
  
  // Joined data
  final String? productName;
  final String? productSku;

  SellInItem({
    required this.id,
    required this.sellInId,
    required this.productId,
    required this.quantity,
    this.unit = 'pcs',
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    this.batchNumber,
    this.expiryDate,
    this.productName,
    this.productSku,
  });
  
  // Alias for transactionId
  String get transactionId => sellInId;

  factory SellInItem.fromJson(Map<String, dynamic> json) {
    return SellInItem(
      id: json['id'],
      sellInId: json['sell_in_id'] ?? '',
      productId: json['product_id'],
      quantity: json['quantity'],
      unit: json['unit'] ?? 'pcs',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      batchNumber: json['batch_number'],
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      productName: json['products']?['name'],
      productSku: json['products']?['sku'],
    );
  }
  
  // Alias for totalPrice
  double get totalPrice => totalAmount;
  double get discount => discountAmount;
}

/// Sell-Out Transaction Model (Distributor → Outlet)
/// Flow: NPP bán hàng → Điểm bán lẻ
class SellOutTransaction {
  final String id;
  final String companyId;
  final String? distributorId;
  final String? outletId;
  final String transactionCode; // DB uses transaction_code
  final DateTime transactionDate;
  final String status;
  final String? outletName; // Direct field in DB
  final String? outletAddress;
  final String? outletChannel;
  final String? reportedById;
  final String? storeVisitId;
  final int totalQuantity;
  final double totalAmount;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  
  // Joined data
  final String? distributorName;
  final String? reportedByName;
  final List<SellOutItem>? items;

  SellOutTransaction({
    required this.id,
    required this.companyId,
    this.distributorId,
    this.outletId,
    required this.transactionCode,
    required this.transactionDate,
    this.status = 'recorded',
    this.outletName,
    this.outletAddress,
    this.outletChannel,
    this.reportedById,
    this.storeVisitId,
    this.totalQuantity = 0,
    this.totalAmount = 0,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.distributorName,
    this.reportedByName,
    this.items,
  });

  factory SellOutTransaction.fromJson(Map<String, dynamic> json) {
    return SellOutTransaction(
      id: json['id'],
      companyId: json['company_id'],
      distributorId: json['distributor_id'],
      outletId: json['outlet_id'],
      transactionCode: json['transaction_code'] ?? '',
      transactionDate: DateTime.parse(json['transaction_date']),
      status: json['status'] ?? 'recorded',
      outletName: json['outlet_name'],
      outletAddress: json['outlet_address'],
      outletChannel: json['outlet_channel'],
      reportedById: json['reported_by_id'],
      storeVisitId: json['store_visit_id'],
      totalQuantity: json['total_quantity'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      verifiedBy: json['verified_by'],
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      notes: json['notes'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      distributorName: json['distributor']?['name'] ?? json['customers']?['name'],
      reportedByName: json['employees']?['full_name'],
      items: json['sell_out_items'] != null
          ? (json['sell_out_items'] as List)
              .map((i) => SellOutItem.fromJson(i))
              .toList()
          : null,
    );
  }

  int get itemCount => items?.length ?? 0;
  
  // Alias for backward compatibility
  String get transactionNumber => transactionCode;
  String? get invoiceNumber => transactionCode;
  String? get paymentStatus => status;
}

/// Sell-Out Item Model
class SellOutItem {
  final String id;
  final String sellOutId; // DB uses sell_out_id
  final String productId;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double totalAmount;
  
  // Joined data
  final String? productName;
  final String? productSku;

  SellOutItem({
    required this.id,
    required this.sellOutId,
    required this.productId,
    required this.quantity,
    this.unit = 'pcs',
    required this.unitPrice,
    required this.totalAmount,
    this.productName,
    this.productSku,
  });
  
  // Alias
  String get transactionId => sellOutId;
  double get totalPrice => totalAmount;

  factory SellOutItem.fromJson(Map<String, dynamic> json) {
    return SellOutItem(
      id: json['id'],
      sellOutId: json['sell_out_id'] ?? '',
      productId: json['product_id'],
      quantity: json['quantity'],
      unit: json['unit'] ?? 'pcs',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      productName: json['products']?['name'],
      productSku: json['products']?['sku'],
    );
  }
}

/// Distributor Inventory Model
class DistributorInventory {
  final String id;
  final String companyId;
  final String distributorId;
  final String productId;
  final int currentStock;
  final int reservedStock;
  final int? minStock;
  final int? maxStock;
  final double? lastPurchasePrice;
  final DateTime lastUpdated;
  
  // Joined data
  final String? distributorName;
  final String? productName;
  final String? productSku;

  DistributorInventory({
    required this.id,
    required this.companyId,
    required this.distributorId,
    required this.productId,
    this.currentStock = 0,
    this.reservedStock = 0,
    this.minStock,
    this.maxStock,
    this.lastPurchasePrice,
    required this.lastUpdated,
    this.distributorName,
    this.productName,
    this.productSku,
  });

  factory DistributorInventory.fromJson(Map<String, dynamic> json) {
    return DistributorInventory(
      id: json['id'],
      companyId: json['company_id'],
      distributorId: json['distributor_id'],
      productId: json['product_id'],
      currentStock: json['current_stock'] ?? 0,
      reservedStock: json['reserved_stock'] ?? 0,
      minStock: json['min_stock'],
      maxStock: json['max_stock'],
      lastPurchasePrice: json['last_purchase_price']?.toDouble(),
      lastUpdated: DateTime.parse(json['last_updated']),
      distributorName: json['customers']?['name'],
      productName: json['products']?['name'],
      productSku: json['products']?['sku'],
    );
  }

  int get availableStock => currentStock - reservedStock;
  bool get isLowStock => minStock != null && currentStock < minStock!;
  bool get isOverStock => maxStock != null && currentStock > maxStock!;
}

/// Sell-Through Report Model
class SellThroughReport {
  final String id;
  final String companyId;
  final String distributorId;
  final String? productId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalSellIn;
  final int totalSellOut;
  final double sellThroughRate;
  final int openingStock;
  final int closingStock;
  final DateTime generatedAt;
  
  // Joined data
  final String? distributorName;
  final String? productName;

  SellThroughReport({
    required this.id,
    required this.companyId,
    required this.distributorId,
    this.productId,
    required this.periodStart,
    required this.periodEnd,
    this.totalSellIn = 0,
    this.totalSellOut = 0,
    this.sellThroughRate = 0,
    this.openingStock = 0,
    this.closingStock = 0,
    required this.generatedAt,
    this.distributorName,
    this.productName,
  });

  factory SellThroughReport.fromJson(Map<String, dynamic> json) {
    return SellThroughReport(
      id: json['id'],
      companyId: json['company_id'],
      distributorId: json['distributor_id'],
      productId: json['product_id'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      totalSellIn: json['total_sell_in'] ?? 0,
      totalSellOut: json['total_sell_out'] ?? 0,
      sellThroughRate: (json['sell_through_rate'] ?? 0).toDouble(),
      openingStock: json['opening_stock'] ?? 0,
      closingStock: json['closing_stock'] ?? 0,
      generatedAt: DateTime.parse(json['generated_at']),
      distributorName: json['customers']?['name'],
      productName: json['products']?['name'],
    );
  }
}

/// Sales Summary
class SalesSummary {
  final double totalSellIn;
  final double totalSellOut;
  final int sellInCount;
  final int sellOutCount;
  final double avgSellThrough;

  SalesSummary({
    required this.totalSellIn,
    required this.totalSellOut,
    required this.sellInCount,
    required this.sellOutCount,
    required this.avgSellThrough,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      totalSellIn: (json['total_sell_in'] ?? 0).toDouble(),
      totalSellOut: (json['total_sell_out'] ?? 0).toDouble(),
      sellInCount: json['sell_in_count'] ?? 0,
      sellOutCount: json['sell_out_count'] ?? 0,
      avgSellThrough: (json['avg_sell_through'] ?? 0).toDouble(),
    );
  }
}

/// Sell-In/Sell-Out Service
class SellInSellOutService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== SELL-IN ====================

  /// Get sell-in transactions
  Future<List<SellInTransaction>> getSellInTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? distributorId,
    String? status,
  }) async {
    var query = _supabase
        .from('sell_in_transactions')
        .select('''
          *,
          customers!distributor_id(name),
          warehouses:from_warehouse_id(name)
        ''');
    
    if (startDate != null) {
      query = query.gte('transaction_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('transaction_date', endDate.toIso8601String().split('T')[0]);
    }
    if (distributorId != null) {
      query = query.eq('distributor_id', distributorId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    
    final response = await query.order('transaction_date', ascending: false);
    return (response as List).map((t) => SellInTransaction.fromJson(t)).toList();
  }

  /// Get sell-in transaction by ID with items
  Future<SellInTransaction?> getSellInById(String transactionId) async {
    final response = await _supabase
        .from('sell_in_transactions')
        .select('''
          *,
          customers!distributor_id(name),
          sell_in_items(
            *,
            products(name, sku)
          )
        ''')
        .eq('id', transactionId)
        .maybeSingle();
    
    if (response == null) return null;
    return SellInTransaction.fromJson(response);
  }

  /// Record sell-in using database function
  Future<String?> recordSellIn({
    required String distributorId,
    required List<Map<String, dynamic>> items,
    String? poNumber,
    DateTime? deliveryDate,
    String? notes,
  }) async {
    final response = await _supabase.rpc('record_sell_in', params: {
      'p_distributor_id': distributorId,
      'p_items': items,
      'p_po_number': poNumber,
      'p_delivery_date': deliveryDate?.toIso8601String().split('T')[0],
      'p_notes': notes,
    });
    
    return response?['transaction_id'] as String?;
  }

  /// Update sell-in status
  Future<void> updateSellInStatus(String transactionId, String status) async {
    await _supabase
        .from('sell_in_transactions')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId);
  }

  // ==================== SELL-OUT ====================

  /// Get sell-out transactions
  Future<List<SellOutTransaction>> getSellOutTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? distributorId,
    String? outletId,
    String? status,
  }) async {
    var query = _supabase
        .from('sell_out_transactions')
        .select('''
          *,
          distributor:customers!distributor_id(name)
        ''');
    
    if (startDate != null) {
      query = query.gte('transaction_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('transaction_date', endDate.toIso8601String().split('T')[0]);
    }
    if (distributorId != null) {
      query = query.eq('distributor_id', distributorId);
    }
    if (outletId != null) {
      query = query.eq('outlet_id', outletId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    
    final response = await query.order('transaction_date', ascending: false);
    return (response as List).map((t) => SellOutTransaction.fromJson(t)).toList();
  }

  /// Get sell-out transaction by ID with items
  Future<SellOutTransaction?> getSellOutById(String transactionId) async {
    final response = await _supabase
        .from('sell_out_transactions')
        .select('''
          *,
          distributor:customers!distributor_id(name),
          sell_out_items(
            *,
            products(name, sku)
          )
        ''')
        .eq('id', transactionId)
        .maybeSingle();
    
    if (response == null) return null;
    return SellOutTransaction.fromJson(response);
  }

  /// Record sell-out using database function
  Future<String?> recordSellOut({
    required String distributorId,
    required String outletId,
    required List<Map<String, dynamic>> items,
    String? invoiceNumber,
    String? paymentMethod,
    String? storeVisitId,
    String? notes,
  }) async {
    final response = await _supabase.rpc('record_sell_out', params: {
      'p_distributor_id': distributorId,
      'p_outlet_id': outletId,
      'p_items': items,
      'p_invoice_number': invoiceNumber,
      'p_payment_method': paymentMethod,
      'p_visit_id': storeVisitId,
      'p_notes': notes,
    });
    
    return response?['transaction_id'] as String?;
  }

  /// Update sell-out payment status
  Future<void> updateSellOutPayment(String transactionId, {
    required String paymentStatus,
    String? paymentMethod,
  }) async {
    await _supabase
        .from('sell_out_transactions')
        .update({
          'payment_status': paymentStatus,
          'payment_method': paymentMethod,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId);
  }

  // ==================== DISTRIBUTOR INVENTORY ====================

  /// Get distributor inventory
  Future<List<DistributorInventory>> getDistributorInventory(String distributorId) async {
    final response = await _supabase
        .from('distributor_inventory')
        .select('''
          *,
          customers!distributor_id(name),
          products(name, sku)
        ''')
        .eq('distributor_id', distributorId)
        .order('last_updated', ascending: false);
    
    return (response as List).map((i) => DistributorInventory.fromJson(i)).toList();
  }

  /// Get low stock items across all distributors
  /// Note: Returns empty list if distributor_inventory table doesn't have min_stock column
  Future<List<DistributorInventory>> getLowStockItems() async {
    try {
      final response = await _supabase
          .from('distributor_inventory')
          .select('''
            *,
            customers!distributor_id(name),
            products(name, sku)
          ''')
          .order('current_stock', ascending: true)
          .limit(20);
      
      return (response as List).map((i) => DistributorInventory.fromJson(i)).toList();
    } catch (e) {
      // Return empty list if table/columns don't exist
      return [];
    }
  }

  /// Update distributor inventory manually
  Future<void> updateInventory({
    required String distributorId,
    required String productId,
    required int newStock,
  }) async {
    await _supabase
        .from('distributor_inventory')
        .upsert({
          'distributor_id': distributorId,
          'product_id': productId,
          'current_stock': newStock,
          'last_updated': DateTime.now().toIso8601String(),
        }, onConflict: 'distributor_id,product_id');
  }

  // ==================== REPORTS & ANALYTICS ====================

  /// Get sell-through reports
  Future<List<SellThroughReport>> getSellThroughReports({
    DateTime? startDate,
    DateTime? endDate,
    String? distributorId,
    String? productId,
  }) async {
    var query = _supabase
        .from('sell_through_reports')
        .select('''
          *,
          customers!distributor_id(name),
          products(name)
        ''');
    
    if (startDate != null) {
      query = query.gte('period_start', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('period_end', endDate.toIso8601String().split('T')[0]);
    }
    if (distributorId != null) {
      query = query.eq('distributor_id', distributorId);
    }
    if (productId != null) {
      query = query.eq('product_id', productId);
    }
    
    final response = await query.order('period_end', ascending: false);
    return (response as List).map((r) => SellThroughReport.fromJson(r)).toList();
  }

  /// Calculate sell-through rate
  Future<double?> calculateSellThrough({
    required String distributorId,
    String? productId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _supabase.rpc('calculate_sell_through', params: {
      'p_distributor_id': distributorId,
      'p_product_id': productId,
      'p_start_date': startDate.toIso8601String().split('T')[0],
      'p_end_date': endDate.toIso8601String().split('T')[0],
    });
    
    return response?['sell_through_rate']?.toDouble();
  }

  /// Get sales summary
  Future<SalesSummary> getSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc('get_sales_summary', params: {
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
      });
      
      // Handle different response types (might be array or object)
      if (response == null) {
        return SalesSummary.fromJson({});
      }
      if (response is List) {
        return SalesSummary.fromJson(response.isNotEmpty ? response.first : {});
      }
      return SalesSummary.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Return default summary if RPC fails
      return SalesSummary.fromJson({});
    }
  }

  /// Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _supabase
        .from('sell_out_items')
        .select('''
          product_id,
          products(name, sku),
          quantity.sum(),
          total_price.sum()
        ''')
        .order('quantity', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }
}

// ==================== PROVIDERS ====================

final sellInSellOutServiceProvider = Provider((ref) => SellInSellOutService());

/// Provider for sell-in transactions (last 30 days)
final recentSellInProvider = FutureProvider.autoDispose<List<SellInTransaction>>((ref) async {
  final service = ref.watch(sellInSellOutServiceProvider);
  return service.getSellInTransactions(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
  );
});

/// Provider for sell-out transactions (last 30 days)
final recentSellOutProvider = FutureProvider.autoDispose<List<SellOutTransaction>>((ref) async {
  final service = ref.watch(sellInSellOutServiceProvider);
  return service.getSellOutTransactions(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
  );
});

/// Provider for sell-in detail
final sellInDetailProvider = FutureProvider.autoDispose.family<SellInTransaction?, String>((ref, id) async {
  final service = ref.watch(sellInSellOutServiceProvider);
  return service.getSellInById(id);
});

/// Provider for sell-out detail
final sellOutDetailProvider = FutureProvider.autoDispose.family<SellOutTransaction?, String>((ref, id) async {
  final service = ref.watch(sellInSellOutServiceProvider);
  return service.getSellOutById(id);
});

/// Provider for distributor inventory
final distributorInventoryProvider = FutureProvider.autoDispose.family<List<DistributorInventory>, String>((ref, distributorId) async {
  final service = ref.watch(sellInSellOutServiceProvider);
  return service.getDistributorInventory(distributorId);
});

/// Provider for low stock alerts
final lowStockAlertsProvider = FutureProvider.autoDispose<List<DistributorInventory>>((ref) async {
  final service = ref.watch(sellInSellOutServiceProvider);
  return service.getLowStockItems();
});

/// Provider for sales summary
final salesSummaryProvider = FutureProvider.autoDispose<SalesSummary>((ref) async {
  final service = ref.watch(sellInSellOutServiceProvider);
  return service.getSalesSummary(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
  );
});

/// Provider for sell-through reports
final sellThroughReportsProvider = FutureProvider.autoDispose<List<SellThroughReport>>((ref) async {
  final service = ref.watch(sellInSellOutServiceProvider);
  return service.getSellThroughReports(
    startDate: DateTime.now().subtract(const Duration(days: 90)),
  );
});
