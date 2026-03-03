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
      };

  /// Percentage of cash vs total
  double get cashPercent =>
      totalRevenue > 0 ? (cashAmount / totalRevenue * 100) : 0;

  double get transferPercent =>
      totalRevenue > 0 ? (transferAmount / totalRevenue * 100) : 0;

  double get cardPercent =>
      totalRevenue > 0 ? (cardAmount / totalRevenue * 100) : 0;
}
