/// Bill Model - Hóa đơn từ Manager upload
class Bill {
  final String id;
  final String companyId;
  final String? storeName;
  final String billNumber;
  final DateTime billDate;
  final double totalAmount;
  final String? billImageUrl;
  final Map<String, dynamic>? ocrData;
  final String status; // pending, approved, rejected, paid
  final String uploadedBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bill({
    required this.id,
    required this.companyId,
    this.storeName,
    required this.billNumber,
    required this.billDate,
    required this.totalAmount,
    this.billImageUrl,
    this.ocrData,
    this.status = 'pending',
    required this.uploadedBy,
    this.approvedBy,
    this.approvedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      storeName: json['store_name'] as String?,
      billNumber: json['bill_number'] as String,
      billDate: DateTime.parse(json['bill_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      billImageUrl: json['bill_image_url'] as String?,
      ocrData: json['ocr_data'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      uploadedBy: json['uploaded_by'] as String,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'store_name': storeName,
      'bill_number': billNumber,
      'bill_date': billDate.toIso8601String(),
      'total_amount': totalAmount,
      'bill_image_url': billImageUrl,
      'ocr_data': ocrData,
      'status': status,
      'uploaded_by': uploadedBy,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Bill copyWith({
    String? id,
    String? companyId,
    String? storeName,
    String? billNumber,
    DateTime? billDate,
    double? totalAmount,
    String? billImageUrl,
    Map<String, dynamic>? ocrData,
    String? status,
    String? uploadedBy,
    String? approvedBy,
    DateTime? approvedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bill(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      storeName: storeName ?? this.storeName,
      billNumber: billNumber ?? this.billNumber,
      billDate: billDate ?? this.billDate,
      totalAmount: totalAmount ?? this.totalAmount,
      billImageUrl: billImageUrl ?? this.billImageUrl,
      ocrData: ocrData ?? this.ocrData,
      status: status ?? this.status,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Bill Status Enum
enum BillStatus {
  pending('pending', 'Chờ duyệt', '⏳'),
  approved('approved', 'Đã duyệt', '✅'),
  rejected('rejected', 'Từ chối', '❌'),
  paid('paid', 'Đã thanh toán', '💰');

  final String value;
  final String label;
  final String emoji;

  const BillStatus(this.value, this.label, this.emoji);

  static BillStatus fromString(String value) {
    return BillStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BillStatus.pending,
    );
  }
}
