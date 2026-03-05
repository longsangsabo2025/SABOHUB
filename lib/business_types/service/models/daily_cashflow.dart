/// Report Status for daily cashflow workflow
enum ReportStatus {
  draft('draft', 'Nháp', 0xFF9E9E9E),
  pending('pending', 'Chờ duyệt', 0xFFFFA000),
  approved('approved', 'Đã duyệt', 0xFF4CAF50),
  rejected('rejected', 'Từ chối', 0xFFF44336);

  const ReportStatus(this.value, this.label, this.colorValue);
  final String value;
  final String label;
  final int colorValue;

  static ReportStatus fromString(String? value) {
    return ReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportStatus.approved,
    );
  }
}

/// Daily Cashflow Model - Báo cáo cuối ngày từ POS (KiotViet / Excel)
class DailyCashflow {
  final String id;
  final String companyId;
  final String? branchId;
  final DateTime reportDate;
  final String? branchName;

  // Revenue by payment method
  final double cashAmount;
  final double transferAmount;
  final double cardAmount;
  final double ewalletAmount;
  final double pointsAmount;
  final double totalRevenue;

  // Transaction counts
  final int totalOrders;
  final int cashOrders;
  final int transferOrders;
  final int cardOrders;
  final int pointsOrders;
  final int ewalletOrders;

  // Product info
  final int uniqueItems;
  final int totalQuantity;

  // Metadata
  final String? sourceFile;
  final String? importedBy;
  final String? notes;
  final Map<String, dynamic>? rawData;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Workflow fields
  final ReportStatus status;
  final String? submittedBy;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  DailyCashflow({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.reportDate,
    this.branchName,
    this.cashAmount = 0,
    this.transferAmount = 0,
    this.cardAmount = 0,
    this.ewalletAmount = 0,
    this.pointsAmount = 0,
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.cashOrders = 0,
    this.transferOrders = 0,
    this.cardOrders = 0,
    this.pointsOrders = 0,
    this.ewalletOrders = 0,
    this.uniqueItems = 0,
    this.totalQuantity = 0,
    this.sourceFile,
    this.importedBy,
    this.notes,
    this.rawData,
    required this.createdAt,
    this.updatedAt,
    this.status = ReportStatus.approved,
    this.submittedBy,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  factory DailyCashflow.fromJson(Map<String, dynamic> json) {
    return DailyCashflow(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      branchId: json['branch_id'] as String?,
      reportDate: DateTime.parse(json['report_date'] as String),
      branchName: json['branch_name'] as String?,
      cashAmount: (json['cash_amount'] as num?)?.toDouble() ?? 0,
      transferAmount: (json['transfer_amount'] as num?)?.toDouble() ?? 0,
      cardAmount: (json['card_amount'] as num?)?.toDouble() ?? 0,
      ewalletAmount: (json['ewallet_amount'] as num?)?.toDouble() ?? 0,
      pointsAmount: (json['points_amount'] as num?)?.toDouble() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      cashOrders: (json['cash_orders'] as num?)?.toInt() ?? 0,
      transferOrders: (json['transfer_orders'] as num?)?.toInt() ?? 0,
      cardOrders: (json['card_orders'] as num?)?.toInt() ?? 0,
      pointsOrders: (json['points_orders'] as num?)?.toInt() ?? 0,
      ewalletOrders: (json['ewallet_orders'] as num?)?.toInt() ?? 0,
      uniqueItems: (json['unique_items'] as num?)?.toInt() ?? 0,
      totalQuantity: (json['total_quantity'] as num?)?.toInt() ?? 0,
      sourceFile: json['source_file'] as String?,
      importedBy: json['imported_by'] as String?,
      notes: json['notes'] as String?,
      rawData: json['raw_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      status: ReportStatus.fromString(json['status'] as String?),
      submittedBy: json['submitted_by'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'branch_id': branchId,
        'report_date': reportDate.toIso8601String().substring(0, 10),
        'branch_name': branchName,
        'cash_amount': cashAmount,
        'transfer_amount': transferAmount,
        'card_amount': cardAmount,
        'ewallet_amount': ewalletAmount,
        'points_amount': pointsAmount,
        'total_revenue': totalRevenue,
        'total_orders': totalOrders,
        'cash_orders': cashOrders,
        'transfer_orders': transferOrders,
        'card_orders': cardOrders,
        'points_orders': pointsOrders,
        'ewallet_orders': ewalletOrders,
        'unique_items': uniqueItems,
        'total_quantity': totalQuantity,
        'source_file': sourceFile,
        'imported_by': importedBy,
        'notes': notes,
        'raw_data': rawData,
        'status': status.value,
        'submitted_by': submittedBy,
        'submitted_at': submittedAt?.toIso8601String(),
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
        'approved_by': approvedBy,
        'approved_at': approvedAt?.toIso8601String(),
        'rejection_reason': rejectionReason,
      };

  /// Copy with new values
  DailyCashflow copyWith({
    ReportStatus? status,
    String? submittedBy,
    DateTime? submittedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return DailyCashflow(
      id: id,
      companyId: companyId,
      branchId: branchId,
      reportDate: reportDate,
      branchName: branchName,
      cashAmount: cashAmount,
      transferAmount: transferAmount,
      cardAmount: cardAmount,
      ewalletAmount: ewalletAmount,
      pointsAmount: pointsAmount,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      cashOrders: cashOrders,
      transferOrders: transferOrders,
      cardOrders: cardOrders,
      pointsOrders: pointsOrders,
      ewalletOrders: ewalletOrders,
      uniqueItems: uniqueItems,
      totalQuantity: totalQuantity,
      sourceFile: sourceFile,
      importedBy: importedBy,
      notes: notes,
      rawData: rawData,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// Percentage of cash vs total
  double get cashPercent =>
      totalRevenue > 0 ? (cashAmount / totalRevenue * 100) : 0;

  double get transferPercent =>
      totalRevenue > 0 ? (transferAmount / totalRevenue * 100) : 0;

  double get cardPercent =>
      totalRevenue > 0 ? (cardAmount / totalRevenue * 100) : 0;
}
