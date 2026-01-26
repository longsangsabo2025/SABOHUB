/// Odori B2B Delivery Model
class OdoriDelivery {
  final String id;
  final String companyId;
  final String deliveryNumber;
  final DateTime deliveryDate;
  final String? driverId;
  final String? driverName;
  final String? vehicle;
  final String? vehiclePlate;
  final int plannedStops;
  final int completedStops;
  final int failedStops;
  final double totalAmount;
  final double collectedAmount;
  final String status; // 'planned', 'loading', 'in_progress', 'completed', 'cancelled'
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OdoriDeliveryItem>? items;

  const OdoriDelivery({
    required this.id,
    required this.companyId,
    required this.deliveryNumber,
    required this.deliveryDate,
    this.driverId,
    this.driverName,
    this.vehicle,
    this.vehiclePlate,
    this.plannedStops = 0,
    this.completedStops = 0,
    this.failedStops = 0,
    this.totalAmount = 0,
    this.collectedAmount = 0,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.items,
  });

  int get remainingStops => plannedStops - completedStops - failedStops;
  double get successRate => plannedStops > 0 ? (completedStops / plannedStops * 100) : 0;
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  /// Status text in Vietnamese for display
  String get statusText {
    switch (status) {
      case 'planned':
        return 'Đã lên kế hoạch';
      case 'loading':
        return 'Đang xếp hàng';
      case 'in_progress':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  /// Status color for UI display
  int get statusColorValue {
    switch (status) {
      case 'planned':
        return 0xFF2196F3; // Blue
      case 'loading':
        return 0xFFFF9800; // Orange
      case 'in_progress':
        return 0xFF4CAF50; // Green
      case 'completed':
        return 0xFF8BC34A; // Light Green
      case 'cancelled':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Formatted delivery date for display
  String get formattedDeliveryDate {
    return '${deliveryDate.day.toString().padLeft(2, '0')}/${deliveryDate.month.toString().padLeft(2, '0')}/${deliveryDate.year}';
  }

  /// Get first delivery item's customer name (for tracking display)
  String? get firstCustomerName => items?.isNotEmpty == true ? items!.first.customerName : null;

  /// Get first delivery item's address (for tracking display)
  String? get firstCustomerAddress => items?.isNotEmpty == true ? items!.first.customerAddress : null;

  /// Get first delivery item's latitude (for tracking display)
  double? get firstLatitude => items?.isNotEmpty == true ? items!.first.latitude : null;

  /// Get first delivery item's longitude (for tracking display)
  double? get firstLongitude => items?.isNotEmpty == true ? items!.first.longitude : null;

  factory OdoriDelivery.fromJson(Map<String, dynamic> json) {
    return OdoriDelivery(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      deliveryNumber: json['delivery_number'] as String,
      deliveryDate: DateTime.parse(json['delivery_date'] as String),
      driverId: json['driver_id'] as String?,
      driverName: json['employees']?['full_name'] as String?,
      vehicle: json['vehicle'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      plannedStops: (json['planned_stops'] as num?)?.toInt() ?? 0,
      completedStops: (json['completed_stops'] as num?)?.toInt() ?? 0,
      failedStops: (json['failed_stops'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      collectedAmount: (json['collected_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'] as String) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      items: json['delivery_items'] != null
          ? (json['delivery_items'] as List)
              .map((item) => OdoriDeliveryItem.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'delivery_number': deliveryNumber,
      'delivery_date': deliveryDate.toIso8601String(),
      'driver_id': driverId,
      'vehicle': vehicle,
      'vehicle_plate': vehiclePlate,
      'planned_stops': plannedStops,
      'completed_stops': completedStops,
      'failed_stops': failedStops,
      'total_amount': totalAmount,
      'collected_amount': collectedAmount,
      'status': status,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}

class OdoriDeliveryItem {
  final String id;
  final String deliveryId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final double? latitude;
  final double? longitude;
  final int sequence;
  final double orderAmount;
  final double collectedAmount;
  final String status; // 'pending', 'in_transit', 'delivered', 'partial', 'failed', 'returned', 'rescheduled'
  final String? failureReason;
  final String? proofImageUrl;
  final String? signatureUrl;
  final DateTime? deliveredAt;
  final String? receiverName;
  final String? notes;
  final DateTime createdAt;

  const OdoriDeliveryItem({
    required this.id,
    required this.deliveryId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.latitude,
    this.longitude,
    required this.sequence,
    this.orderAmount = 0,
    this.collectedAmount = 0,
    required this.status,
    this.failureReason,
    this.proofImageUrl,
    this.signatureUrl,
    this.deliveredAt,
    this.receiverName,
    this.notes,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isDelivered => status == 'delivered';
  bool get isFailed => status == 'failed';

  factory OdoriDeliveryItem.fromJson(Map<String, dynamic> json) {
    return OdoriDeliveryItem(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['sales_orders']?['order_number'] as String?,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      customerAddress: json['customer_address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sequence: (json['sequence'] as num).toInt(),
      orderAmount: (json['order_amount'] as num?)?.toDouble() ?? 0,
      collectedAmount: (json['collected_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String,
      failureReason: json['failure_reason'] as String?,
      proofImageUrl: json['proof_image_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at'] as String) 
          : null,
      receiverName: json['receiver_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'order_id': orderId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
      'order_amount': orderAmount,
      'collected_amount': collectedAmount,
      'status': status,
      'failure_reason': failureReason,
      'proof_image_url': proofImageUrl,
      'signature_url': signatureUrl,
      'delivered_at': deliveredAt?.toIso8601String(),
      'receiver_name': receiverName,
      'notes': notes,
    };
  }
}

/// Delivery GPS Tracking
class OdoriDeliveryTracking {
  final String id;
  final String deliveryId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime recordedAt;

  const OdoriDeliveryTracking({
    required this.id,
    required this.deliveryId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.recordedAt,
  });

  factory OdoriDeliveryTracking.fromJson(Map<String, dynamic> json) {
    return OdoriDeliveryTracking(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}
