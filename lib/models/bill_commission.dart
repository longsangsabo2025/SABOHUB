/// Bill Commission Model - Hoa hồng từng nhân viên cho từng bill
class BillCommission {
  final String id;
  final String billId;
  final String employeeId;
  final String? commissionRuleId;
  final double commissionPercentage;
  final double baseAmount;
  final double commissionAmount;
  final String status; // pending, approved, rejected, paid
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? paidBy;
  final DateTime? paidAt;
  final String? paymentReference;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BillCommission({
    required this.id,
    required this.billId,
    required this.employeeId,
    this.commissionRuleId,
    required this.commissionPercentage,
    required this.baseAmount,
    required this.commissionAmount,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.paidBy,
    this.paidAt,
    this.paymentReference,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillCommission.fromJson(Map<String, dynamic> json) {
    return BillCommission(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      employeeId: json['employee_id'] as String,
      commissionRuleId: json['commission_rule_id'] as String?,
      commissionPercentage: (json['commission_percentage'] as num).toDouble(),
      baseAmount: (json['base_amount'] as num).toDouble(),
      commissionAmount: (json['commission_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      paidBy: json['paid_by'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      paymentReference: json['payment_reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_id': billId,
      'employee_id': employeeId,
      'commission_rule_id': commissionRuleId,
      'commission_percentage': commissionPercentage,
      'base_amount': baseAmount,
      'commission_amount': commissionAmount,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'paid_by': paidBy,
      'paid_at': paidAt?.toIso8601String(),
      'payment_reference': paymentReference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BillCommission copyWith({
    String? id,
    String? billId,
    String? employeeId,
    String? commissionRuleId,
    double? commissionPercentage,
    double? baseAmount,
    double? commissionAmount,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? paidBy,
    DateTime? paidAt,
    String? paymentReference,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillCommission(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      employeeId: employeeId ?? this.employeeId,
      commissionRuleId: commissionRuleId ?? this.commissionRuleId,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      baseAmount: baseAmount ?? this.baseAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      paidBy: paidBy ?? this.paidBy,
      paidAt: paidAt ?? this.paidAt,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Commission Status Enum
enum CommissionStatus {
  pending('pending', 'Chờ duyệt', '⏳'),
  approved('approved', 'Đã duyệt', '✅'),
  rejected('rejected', 'Từ chối', '❌'),
  paid('paid', 'Đã thanh toán', '💰');

  final String value;
  final String label;
  final String emoji;

  const CommissionStatus(this.value, this.label, this.emoji);

  static CommissionStatus fromString(String value) {
    return CommissionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CommissionStatus.pending,
    );
  }
}
