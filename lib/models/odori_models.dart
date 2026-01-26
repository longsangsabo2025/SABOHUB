// Odori Module Models - B2B Distribution
// This file contains all models for the Odori distribution management system

import 'package:equatable/equatable.dart';

/// Customer Types
enum CustomerType {
  distributor, // Nhà phân phối
  retailer,    // Đại lý / Cửa hàng
  endCustomer, // Khách hàng cuối
}

/// Customer Model
class OdoriCustomer extends Equatable {
  final String id;
  final String companyId;
  final String? code;
  final String name;
  final CustomerType type;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? district;
  final String? ward;
  final double? latitude;
  final double? longitude;
  final String? taxId;
  final double? creditLimit;
  final int? paymentTerms;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OdoriCustomer({
    required this.id,
    required this.companyId,
    this.code,
    required this.name,
    required this.type,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.district,
    this.ward,
    this.latitude,
    this.longitude,
    this.taxId,
    this.creditLimit,
    this.paymentTerms,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory OdoriCustomer.fromJson(Map<String, dynamic> json) {
    return OdoriCustomer(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String,
      type: _parseCustomerType(json['type'] as String?),
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      ward: json['ward'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      taxId: json['tax_id'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      paymentTerms: json['payment_terms'] as int?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'code': code,
    'name': name,
    'type': type.name,
    'contact_person': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'city': city,
    'district': district,
    'ward': ward,
    'latitude': latitude,
    'longitude': longitude,
    'tax_id': taxId,
    'credit_limit': creditLimit,
    'payment_terms': paymentTerms,
    'notes': notes,
    'is_active': isActive,
  };

  static CustomerType _parseCustomerType(String? type) {
    switch (type) {
      case 'distributor': return CustomerType.distributor;
      case 'end_customer': return CustomerType.endCustomer;
      default: return CustomerType.retailer;
    }
  }

  String get typeLabel {
    switch (type) {
      case CustomerType.distributor: return 'Nhà phân phối';
      case CustomerType.retailer: return 'Đại lý';
      case CustomerType.endCustomer: return 'Khách hàng';
    }
  }

  @override
  List<Object?> get props => [id, companyId, name, type];
}

/// Product Category
class OdoriProductCategory extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String? parentId;
  final int sortOrder;
  final bool isActive;

  const OdoriProductCategory({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory OdoriProductCategory.fromJson(Map<String, dynamic> json) {
    return OdoriProductCategory(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, companyId, name];
}

/// Product Model
class OdoriProduct extends Equatable {
  final String id;
  final String companyId;
  final String? sku;
  final String? barcode;
  final String name;
  final String? description;
  final String? categoryId;
  final String unit;
  final double basePrice;
  final double? costPrice;
  final double? weight;
  final double? volume;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  // Related data
  final OdoriProductCategory? category;

  const OdoriProduct({
    required this.id,
    required this.companyId,
    this.sku,
    this.barcode,
    required this.name,
    this.description,
    this.categoryId,
    required this.unit,
    required this.basePrice,
    this.costPrice,
    this.weight,
    this.volume,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    this.category,
  });

  factory OdoriProduct.fromJson(Map<String, dynamic> json) {
    return OdoriProduct(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      unit: json['unit'] as String? ?? 'Cái',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['category'] != null 
          ? OdoriProductCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  String get formattedPrice {
    return '${basePrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}đ';
  }

  @override
  List<Object?> get props => [id, companyId, sku, barcode, name];
}

/// Order Status
enum OrderStatus {
  draft,
  pending,
  approved,
  processing,
  shipped,
  delivered,
  cancelled,
}

/// Sales Order Model
class OdoriSalesOrder extends Equatable {
  final String id;
  final String companyId;
  final String customerId;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final OrderStatus status;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double totalAmount;
  final String? shippingAddress;
  final String? notes;
  final String? salesRepId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final int itemCount;
  final DateTime createdAt;

  // Related data
  final OdoriCustomer? customer;
  final List<OdoriOrderItem>? items;

  const OdoriSalesOrder({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.orderNumber,
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.status,
    required this.subtotal,
    this.discountTotal = 0,
    this.taxTotal = 0,
    required this.totalAmount,
    this.shippingAddress,
    this.notes,
    this.salesRepId,
    this.approvedBy,
    this.approvedAt,
    this.itemCount = 0,
    required this.createdAt,
    this.customer,
    this.items,
  });

  factory OdoriSalesOrder.fromJson(Map<String, dynamic> json) {
    return OdoriSalesOrder(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      customerId: json['customer_id'] as String,
      orderNumber: json['order_number'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      status: _parseOrderStatus(json['status'] as String?),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountTotal: (json['discount_total'] as num?)?.toDouble() ?? 0,
      taxTotal: (json['tax_total'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      shippingAddress: json['shipping_address'] as String?,
      notes: json['notes'] as String?,
      salesRepId: json['sales_rep_id'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      itemCount: json['item_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      customer: json['customer'] != null
          ? OdoriCustomer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
    );
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending': return OrderStatus.pending;
      case 'approved': return OrderStatus.approved;
      case 'processing': return OrderStatus.processing;
      case 'shipped': return OrderStatus.shipped;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.draft;
    }
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.draft: return 'Nháp';
      case OrderStatus.pending: return 'Chờ duyệt';
      case OrderStatus.approved: return 'Đã duyệt';
      case OrderStatus.processing: return 'Đang xử lý';
      case OrderStatus.shipped: return 'Đang giao';
      case OrderStatus.delivered: return 'Đã giao';
      case OrderStatus.cancelled: return 'Đã hủy';
    }
  }

  String get formattedTotal {
    return '${totalAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}đ';
  }

  @override
  List<Object?> get props => [id, orderNumber, customerId, status];
}

/// Order Item Model
class OdoriOrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productSku;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double lineTotal;
  final int lineNumber;
  final String? notes;

  const OdoriOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.lineTotal,
    this.lineNumber = 0,
    this.notes,
  });

  factory OdoriOrderItem.fromJson(Map<String, dynamic> json) {
    return OdoriOrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productSku: json['product_sku'] as String?,
      unit: json['unit'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num).toDouble(),
      lineNumber: json['line_number'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, orderId, productId, quantity];
}

/// Delivery Status
enum DeliveryStatus {
  pending,
  assigned,
  inTransit,
  delivered,
  failed,
  returned,
}

/// Delivery Model
class OdoriDelivery extends Equatable {
  final String id;
  final String companyId;
  final String? orderId;
  final String customerId;
  final String deliveryNumber;
  final DateTime expectedDate;
  final DeliveryStatus status;
  final String? driverId;
  final String? vehicleInfo;
  final String shippingAddress;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? signatureUrl;
  final String? failureReason;
  final DateTime createdAt;

  // Related data
  final OdoriCustomer? customer;
  final OdoriSalesOrder? order;

  const OdoriDelivery({
    required this.id,
    required this.companyId,
    this.orderId,
    required this.customerId,
    required this.deliveryNumber,
    required this.expectedDate,
    required this.status,
    this.driverId,
    this.vehicleInfo,
    required this.shippingAddress,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.currentLatitude,
    this.currentLongitude,
    this.signatureUrl,
    this.failureReason,
    required this.createdAt,
    this.customer,
    this.order,
  });

  factory OdoriDelivery.fromJson(Map<String, dynamic> json) {
    return OdoriDelivery(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      orderId: json['order_id'] as String?,
      customerId: json['customer_id'] as String,
      deliveryNumber: json['delivery_number'] as String,
      expectedDate: DateTime.parse(json['expected_date'] as String),
      status: _parseDeliveryStatus(json['status'] as String?),
      driverId: json['driver_id'] as String?,
      vehicleInfo: json['vehicle_info'] as String?,
      shippingAddress: json['shipping_address'] as String,
      notes: json['notes'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      startLatitude: (json['start_latitude'] as num?)?.toDouble(),
      startLongitude: (json['start_longitude'] as num?)?.toDouble(),
      endLatitude: (json['end_latitude'] as num?)?.toDouble(),
      endLongitude: (json['end_longitude'] as num?)?.toDouble(),
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      signatureUrl: json['signature_url'] as String?,
      failureReason: json['failure_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      customer: json['customer'] != null
          ? OdoriCustomer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
    );
  }

  static DeliveryStatus _parseDeliveryStatus(String? status) {
    switch (status) {
      case 'assigned': return DeliveryStatus.assigned;
      case 'in_transit': return DeliveryStatus.inTransit;
      case 'delivered': return DeliveryStatus.delivered;
      case 'failed': return DeliveryStatus.failed;
      case 'returned': return DeliveryStatus.returned;
      default: return DeliveryStatus.pending;
    }
  }

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.pending: return 'Chờ xử lý';
      case DeliveryStatus.assigned: return 'Đã phân công';
      case DeliveryStatus.inTransit: return 'Đang giao';
      case DeliveryStatus.delivered: return 'Đã giao';
      case DeliveryStatus.failed: return 'Thất bại';
      case DeliveryStatus.returned: return 'Hoàn trả';
    }
  }

  bool get hasLocation => currentLatitude != null && currentLongitude != null;

  @override
  List<Object?> get props => [id, deliveryNumber, customerId, status];
}

/// Receivable Status
enum ReceivableStatus {
  pending,
  partial,
  paid,
  overdue,
  writtenOff,
}

/// Receivable Model
class OdoriReceivable extends Equatable {
  final String id;
  final String companyId;
  final String customerId;
  final String? orderId;
  final String? deliveryId;
  final String receivableNumber;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime dueDate;
  final ReceivableStatus status;
  final DateTime? lastPaymentDate;
  final String? notes;
  final DateTime createdAt;

  // Related data
  final OdoriCustomer? customer;

  const OdoriReceivable({
    required this.id,
    required this.companyId,
    required this.customerId,
    this.orderId,
    this.deliveryId,
    required this.receivableNumber,
    required this.amount,
    this.paidAmount = 0,
    required this.remainingAmount,
    required this.dueDate,
    required this.status,
    this.lastPaymentDate,
    this.notes,
    required this.createdAt,
    this.customer,
  });

  factory OdoriReceivable.fromJson(Map<String, dynamic> json) {
    return OdoriReceivable(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      customerId: json['customer_id'] as String,
      orderId: json['order_id'] as String?,
      deliveryId: json['delivery_id'] as String?,
      receivableNumber: json['receivable_number'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: _parseReceivableStatus(json['status'] as String?),
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      customer: json['customer'] != null
          ? OdoriCustomer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
    );
  }

  static ReceivableStatus _parseReceivableStatus(String? status) {
    switch (status) {
      case 'partial': return ReceivableStatus.partial;
      case 'paid': return ReceivableStatus.paid;
      case 'overdue': return ReceivableStatus.overdue;
      case 'written_off': return ReceivableStatus.writtenOff;
      default: return ReceivableStatus.pending;
    }
  }

  String get statusLabel {
    switch (status) {
      case ReceivableStatus.pending: return 'Chờ thanh toán';
      case ReceivableStatus.partial: return 'Thanh toán 1 phần';
      case ReceivableStatus.paid: return 'Đã thanh toán';
      case ReceivableStatus.overdue: return 'Quá hạn';
      case ReceivableStatus.writtenOff: return 'Đã xóa nợ';
    }
  }

  bool get isOverdue => dueDate.isBefore(DateTime.now()) && 
      status != ReceivableStatus.paid;

  double get paidPercentage => amount > 0 ? (paidAmount / amount) * 100 : 0;

  @override
  List<Object?> get props => [id, receivableNumber, customerId, amount, status];
}

/// Payment Model
class OdoriPayment extends Equatable {
  final String id;
  final String receivableId;
  final String paymentNumber;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? referenceNumber;
  final String? notes;
  final String? collectedBy;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const OdoriPayment({
    required this.id,
    required this.receivableId,
    required this.paymentNumber,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.referenceNumber,
    this.notes,
    this.collectedBy,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory OdoriPayment.fromJson(Map<String, dynamic> json) {
    return OdoriPayment(
      id: json['id'] as String,
      receivableId: json['receivable_id'] as String,
      paymentNumber: json['payment_number'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      referenceNumber: json['reference_number'] as String?,
      notes: json['notes'] as String?,
      collectedBy: json['collected_by'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get methodLabel {
    switch (paymentMethod) {
      case 'cash': return 'Tiền mặt';
      case 'bank_transfer': return 'Chuyển khoản';
      case 'check': return 'Séc';
      default: return 'Khác';
    }
  }

  @override
  List<Object?> get props => [id, receivableId, amount, paymentDate];
}
