/// Product Sample Model - Tracks sample products sent to customers
class ProductSample {
  final String id;
  final String companyId;
  final String? customerId;
  final String? customerName;
  final String? productId;
  final String? productName;
  final String? productSku;
  final int quantity;
  final String unit;
  final DateTime sentDate;
  final String? sentById;
  final String? sentByName;
  final DateTime? receivedDate;
  final String? receivedBy;
  final String status; // pending, delivered, received, feedback_received, converted
  final int? feedbackRating; // 1-5
  final String? feedbackNotes;
  final DateTime? feedbackDate;
  final bool convertedToOrder;
  final String? orderId;
  final String? notes;
  final String? deliveryNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductSample({
    required this.id,
    required this.companyId,
    this.customerId,
    this.customerName,
    this.productId,
    this.productName,
    this.productSku,
    this.quantity = 1,
    this.unit = 'cái',
    required this.sentDate,
    this.sentById,
    this.sentByName,
    this.receivedDate,
    this.receivedBy,
    this.status = 'pending',
    this.feedbackRating,
    this.feedbackNotes,
    this.feedbackDate,
    this.convertedToOrder = false,
    this.orderId,
    this.notes,
    this.deliveryNotes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Status display text in Vietnamese
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ gửi';
      case 'delivered':
        return 'Đã gửi';
      case 'received':
        return 'Đã nhận';
      case 'feedback_received':
        return 'Có phản hồi';
      case 'converted':
        return 'Đã mua hàng';
      default:
        return status;
    }
  }

  /// Status color for UI
  static String statusColor(String status) {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'delivered':
        return 'blue';
      case 'received':
        return 'green';
      case 'feedback_received':
        return 'purple';
      case 'converted':
        return 'teal';
      default:
        return 'grey';
    }
  }

  factory ProductSample.fromJson(Map<String, dynamic> json) {
    return ProductSample(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customers']?['name'] as String? ?? json['customer_name'] as String?,
      productId: json['product_id'] as String?,
      productName: json['products']?['name'] as String? ?? json['product_name'] as String?,
      productSku: json['products']?['sku'] as String? ?? json['product_sku'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? 'cái',
      sentDate: DateTime.parse(json['sent_date'] as String),
      sentById: json['sent_by_id'] as String?,
      sentByName: json['employees']?['full_name'] as String? ?? json['sent_by_name'] as String?,
      receivedDate: json['received_date'] != null
          ? DateTime.parse(json['received_date'] as String)
          : null,
      receivedBy: json['received_by'] as String?,
      status: json['status'] as String? ?? 'pending',
      feedbackRating: (json['feedback_rating'] as num?)?.toInt(),
      feedbackNotes: json['feedback_notes'] as String?,
      feedbackDate: json['feedback_date'] != null
          ? DateTime.parse(json['feedback_date'] as String)
          : null,
      convertedToOrder: json['converted_to_order'] as bool? ?? false,
      orderId: json['order_id'] as String?,
      notes: json['notes'] as String?,
      deliveryNotes: json['delivery_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'customer_id': customerId,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'unit': unit,
      'sent_date': sentDate.toIso8601String(),
      'sent_by_id': sentById,
      'sent_by_name': sentByName,
      'received_date': receivedDate?.toIso8601String(),
      'received_by': receivedBy,
      'status': status,
      'feedback_rating': feedbackRating,
      'feedback_notes': feedbackNotes,
      'feedback_date': feedbackDate?.toIso8601String(),
      'converted_to_order': convertedToOrder,
      'order_id': orderId,
      'notes': notes,
      'delivery_notes': deliveryNotes,
    };
  }

  /// For insert - excludes id and timestamps
  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      'customer_id': customerId,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'unit': unit,
      'sent_date': sentDate.toIso8601String(),
      'sent_by_id': sentById,
      'sent_by_name': sentByName,
      'status': status,
      'notes': notes,
    };
  }

  ProductSample copyWith({
    String? id,
    String? companyId,
    String? customerId,
    String? customerName,
    String? productId,
    String? productName,
    String? productSku,
    int? quantity,
    String? unit,
    DateTime? sentDate,
    String? sentById,
    String? sentByName,
    DateTime? receivedDate,
    String? receivedBy,
    String? status,
    int? feedbackRating,
    String? feedbackNotes,
    DateTime? feedbackDate,
    bool? convertedToOrder,
    String? orderId,
    String? notes,
    String? deliveryNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductSample(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      sentDate: sentDate ?? this.sentDate,
      sentById: sentById ?? this.sentById,
      sentByName: sentByName ?? this.sentByName,
      receivedDate: receivedDate ?? this.receivedDate,
      receivedBy: receivedBy ?? this.receivedBy,
      status: status ?? this.status,
      feedbackRating: feedbackRating ?? this.feedbackRating,
      feedbackNotes: feedbackNotes ?? this.feedbackNotes,
      feedbackDate: feedbackDate ?? this.feedbackDate,
      convertedToOrder: convertedToOrder ?? this.convertedToOrder,
      orderId: orderId ?? this.orderId,
      notes: notes ?? this.notes,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Filter options for product samples
class ProductSampleFilters {
  final String? status;
  final String? customerId;
  final String? productId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? search;

  const ProductSampleFilters({
    this.status,
    this.customerId,
    this.productId,
    this.fromDate,
    this.toDate,
    this.search,
  });
}
