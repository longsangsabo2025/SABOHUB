// Quality Inspection Models for Manufacturing QC
// Date: 2026-03-04

/// Mức độ nghiêm trọng của lỗi
enum DefectSeverity { low, medium, high, critical }

/// Trạng thái kiểm tra chất lượng
enum InspectionStatus { pending, inProgress, passed, failed, conditional }

// ===== DEFECT RECORD =====
class DefectRecord {
  final String type;
  final int count;
  final DefectSeverity severity;
  final String? description;

  DefectRecord({
    required this.type,
    required this.count,
    this.severity = DefectSeverity.medium,
    this.description,
  });

  factory DefectRecord.fromJson(Map<String, dynamic> json) {
    return DefectRecord(
      type: json['type'] as String,
      count: json['count'] as int? ?? 0,
      severity: DefectSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => DefectSeverity.medium,
      ),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'count': count,
        'severity': severity.name,
        'description': description,
      };

  DefectRecord copyWith({
    String? type,
    int? count,
    DefectSeverity? severity,
    String? description,
  }) {
    return DefectRecord(
      type: type ?? this.type,
      count: count ?? this.count,
      severity: severity ?? this.severity,
      description: description ?? this.description,
    );
  }
}

// ===== QUALITY INSPECTION =====
class QualityInspection {
  final String id;
  final String companyId;
  final String? productionOrderId;
  final String productName;
  final String? inspectorId;
  final String inspectorName;
  final DateTime inspectionDate;
  final InspectionStatus status;
  final int totalQuantity;
  final int passedQuantity;
  final int failedQuantity;
  final List<DefectRecord> defectTypes;
  final String? notes;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime? updatedAt;

  QualityInspection({
    required this.id,
    required this.companyId,
    this.productionOrderId,
    required this.productName,
    this.inspectorId,
    required this.inspectorName,
    required this.inspectionDate,
    this.status = InspectionStatus.pending,
    this.totalQuantity = 0,
    this.passedQuantity = 0,
    this.failedQuantity = 0,
    this.defectTypes = const [],
    this.notes,
    this.photos = const [],
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Tỉ lệ đạt (%)
  double get passRate =>
      totalQuantity > 0 ? (passedQuantity / totalQuantity) * 100 : 0;

  /// Tỉ lệ lỗi (%)
  double get failRate =>
      totalQuantity > 0 ? (failedQuantity / totalQuantity) * 100 : 0;

  /// Tự động xác định kết quả: lỗi > 10% → failed
  InspectionStatus get calculatedStatus {
    if (totalQuantity == 0) return InspectionStatus.pending;
    if (failRate > 10) return InspectionStatus.failed;
    if (failRate > 5) return InspectionStatus.conditional;
    return InspectionStatus.passed;
  }

  factory QualityInspection.fromJson(Map<String, dynamic> json) {
    final defects = json['defect_types'];
    List<DefectRecord> defectList = [];
    if (defects is List) {
      defectList =
          defects.map((d) => DefectRecord.fromJson(d as Map<String, dynamic>)).toList();
    }

    final photoData = json['photos'];
    List<String> photoList = [];
    if (photoData is List) {
      photoList = photoData.map((p) => p.toString()).toList();
    }

    return QualityInspection(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      productionOrderId: json['production_order_id'] as String?,
      productName: json['product_name'] as String? ?? '',
      inspectorId: json['inspector_id'] as String?,
      inspectorName: json['inspector_name'] as String? ?? '',
      inspectionDate: json['inspection_date'] != null
          ? DateTime.parse(json['inspection_date'] as String)
          : DateTime.now(),
      status: InspectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InspectionStatus.pending,
      ),
      totalQuantity: json['total_quantity'] as int? ?? 0,
      passedQuantity: json['passed_quantity'] as int? ?? 0,
      failedQuantity: json['failed_quantity'] as int? ?? 0,
      defectTypes: defectList,
      notes: json['notes'] as String?,
      photos: photoList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'production_order_id': productionOrderId,
        'product_name': productName,
        'inspector_id': inspectorId,
        'inspector_name': inspectorName,
        'inspection_date': inspectionDate.toIso8601String(),
        'status': status.name,
        'total_quantity': totalQuantity,
        'passed_quantity': passedQuantity,
        'failed_quantity': failedQuantity,
        'defect_types': defectTypes.map((d) => d.toJson()).toList(),
        'notes': notes,
        'photos': photos,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  QualityInspection copyWith({
    String? id,
    String? companyId,
    String? productionOrderId,
    String? productName,
    String? inspectorId,
    String? inspectorName,
    DateTime? inspectionDate,
    InspectionStatus? status,
    int? totalQuantity,
    int? passedQuantity,
    int? failedQuantity,
    List<DefectRecord>? defectTypes,
    String? notes,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QualityInspection(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      productionOrderId: productionOrderId ?? this.productionOrderId,
      productName: productName ?? this.productName,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      status: status ?? this.status,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      passedQuantity: passedQuantity ?? this.passedQuantity,
      failedQuantity: failedQuantity ?? this.failedQuantity,
      defectTypes: defectTypes ?? this.defectTypes,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Các loại lỗi phổ biến trong sản xuất
class QCDefectTypes {
  static const String kichThuoc = 'Kích thước';
  static const String beMat = 'Bề mặt';
  static const String vatLieu = 'Vật liệu';
  static const String mauSac = 'Màu sắc';
  static const String khac = 'Khác';

  static const List<String> all = [
    kichThuoc,
    beMat,
    vatLieu,
    mauSac,
    khac,
  ];
}

/// Helper cho hiển thị UI
class QCStatusHelper {
  static String statusText(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.pending:
        return 'Chờ kiểm tra';
      case InspectionStatus.inProgress:
        return 'Đang kiểm tra';
      case InspectionStatus.passed:
        return 'Đạt';
      case InspectionStatus.failed:
        return 'Không đạt';
      case InspectionStatus.conditional:
        return 'Đạt có điều kiện';
    }
  }

  static String severityText(DefectSeverity severity) {
    switch (severity) {
      case DefectSeverity.low:
        return 'Thấp';
      case DefectSeverity.medium:
        return 'Trung bình';
      case DefectSeverity.high:
        return 'Cao';
      case DefectSeverity.critical:
        return 'Nghiêm trọng';
    }
  }
}
