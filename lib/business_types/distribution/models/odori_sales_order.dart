/// Odori B2B Sales Order Model - Matches actual database schema
class OdoriSalesOrder {
  final String id;
  final String companyId;
  final String? branchId;
  final String orderNumber;
  final DateTime orderDate;
  final String customerId;
  final String? customerName; // Denormalized from form
  final String? customerAddress;
  final String? customerPhone;
  final String? saleId; // DB uses 'sale_id' not 'employee_id'
  final String? saleName;
  final String? warehouseId;
  final String? warehouseName;
  final double subtotal;
  final double? discountPercent;
  final double discountAmount;
  final double? taxPercent;
  final double taxAmount;
  final double? shippingAmount;
  final double total; // DB uses 'total' not 'total_amount'
  final String? paymentMethod;
  final String paymentStatus; // 'unpaid', 'partial', 'paid'
  final double paidAmount;
  final DateTime? dueDate;
  final String? deliveryStatus;
  final DateTime? deliveryDate;
  final String? deliveryAddress;
  final String? deliveryContactName;
  final String? deliveryContactPhone;
  final String? deliveryNotes;
  final String status; // 'draft', 'pending_approval', 'approved', 'processing', 'ready', 'delivered', 'cancelled'
  final String? priority;
  final String? source;
  final String? visitId;
  final String? notes;
  final String? internalNotes;
  final bool requiresApproval;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final List<OdoriSalesOrderItem>? items;

  const OdoriSalesOrder({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.orderNumber,
    required this.orderDate,
    required this.customerId,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
    this.saleId,
    this.saleName,
    this.warehouseId,
    this.warehouseName,
    required this.subtotal,
    this.discountPercent,
    this.discountAmount = 0,
    this.taxPercent,
    this.taxAmount = 0,
    this.shippingAmount,
    required this.total,
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0,
    this.dueDate,
    this.deliveryStatus,
    this.deliveryDate,
    this.deliveryAddress,
    this.deliveryContactName,
    this.deliveryContactPhone,
    this.deliveryNotes,
    required this.status,
    this.priority,
    this.source,
    this.visitId,
    this.notes,
    this.internalNotes,
    this.requiresApproval = false,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.items,
  });

  /// Remaining amount to be paid
  double get remainingAmount => total - paidAmount;
  
  /// Check if order is pending approval
  bool get isPendingApproval => status == 'pending_approval';
  
  /// Check if order is completed
  bool get isCompleted => status == 'delivered' || status == 'cancelled';
  
  /// Check if order was rejected
  bool get isRejected => rejectedAt != null;

  factory OdoriSalesOrder.fromJson(Map<String, dynamic> json) {
    return OdoriSalesOrder(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      branchId: json['branch_id'] as String?,
      orderNumber: json['order_number'] as String? ?? '',
      orderDate: DateTime.parse(json['order_date'] as String),
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String? ?? json['customers']?['name'] as String?,
      customerAddress: json['customer_address'] as String?,
      customerPhone: json['customer_phone'] as String?,
      saleId: json['sale_id'] as String?,
      saleName: json['employees']?['full_name'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      warehouseName: json['warehouses']?['name'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      taxPercent: (json['tax_percent'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      shippingAmount: (json['shipping_fee'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String) 
          : null,
      deliveryStatus: json['delivery_status'] as String?,
      deliveryDate: json['delivery_date'] != null 
          ? DateTime.parse(json['delivery_date'] as String) 
          : null,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryContactName: json['delivery_contact_name'] as String?,
      deliveryContactPhone: json['delivery_contact_phone'] as String?,
      deliveryNotes: json['delivery_notes'] as String?,
      status: json['status'] as String? ?? 'draft',
      priority: json['priority'] as String?,
      source: json['source'] as String?,
      visitId: json['visit_id'] as String?,
      notes: json['notes'] as String?,
      internalNotes: json['internal_notes'] as String?,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'] as String) 
          : null,
      rejectedBy: json['rejected_by'] as String?,
      rejectedAt: json['rejected_at'] != null 
          ? DateTime.parse(json['rejected_at'] as String) 
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      cancelledAt: json['cancelled_at'] != null 
          ? DateTime.parse(json['cancelled_at'] as String) 
          : null,
      cancelledBy: json['cancelled_by'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      items: json['sales_order_items'] != null
          ? (json['sales_order_items'] as List)
              .map((item) => OdoriSalesOrderItem.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'branch_id': branchId,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String().split('T')[0],
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_phone': customerPhone,
      'sale_id': saleId,
      'warehouse_id': warehouseId,
      'subtotal': subtotal,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'shipping_fee': shippingAmount,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'paid_amount': paidAmount,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'delivery_status': deliveryStatus,
      'delivery_date': deliveryDate?.toIso8601String().split('T')[0],
      'delivery_address': deliveryAddress,
      'delivery_notes': deliveryNotes,
      'status': status,
      'priority': priority,
      'source': source,
      'visit_id': visitId,
      'notes': notes,
      'internal_notes': internalNotes,
      'requires_approval': requiresApproval,
    };
  }
}

/// Sales Order Line Item
class OdoriSalesOrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String? productName;
  final String? productSku;
  final String? productImageUrl;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double? discountPercent;
  final double discountAmount;
  final double lineTotal;

  const OdoriSalesOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.productName,
    this.productSku,
    this.productImageUrl,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.discountPercent,
    this.discountAmount = 0,
    required this.lineTotal,
  });

  factory OdoriSalesOrderItem.fromJson(Map<String, dynamic> json) {
    return OdoriSalesOrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? json['sales_order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['products']?['name'] as String? ?? json['product_name'] as String?,
      productSku: json['products']?['sku'] as String? ?? json['product_sku'] as String?,
      productImageUrl: json['products']?['image_url'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'cái',
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 
                 (json['quantity'] as num).toDouble() * (json['unit_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'line_total': lineTotal,
    };
  }
}
