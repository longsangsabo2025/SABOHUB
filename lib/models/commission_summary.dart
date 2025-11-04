/// Commission Summary Model - Tổng hợp hoa hồng cho dashboard
class CommissionSummary {
  final double totalCommission;
  final double pendingCommission;
  final double approvedCommission;
  final double paidCommission;
  final int totalBills;
  final int pendingBills;
  final int approvedBills;
  final int paidBills;

  CommissionSummary({
    required this.totalCommission,
    required this.pendingCommission,
    required this.approvedCommission,
    required this.paidCommission,
    required this.totalBills,
    required this.pendingBills,
    required this.approvedBills,
    required this.paidBills,
  });

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    return CommissionSummary(
      totalCommission: (json['total_commission'] as num?)?.toDouble() ?? 0,
      pendingCommission: (json['pending_commission'] as num?)?.toDouble() ?? 0,
      approvedCommission:
          (json['approved_commission'] as num?)?.toDouble() ?? 0,
      paidCommission: (json['paid_commission'] as num?)?.toDouble() ?? 0,
      totalBills: json['total_bills'] as int? ?? 0,
      pendingBills: json['pending_bills'] as int? ?? 0,
      approvedBills: json['approved_bills'] as int? ?? 0,
      paidBills: json['paid_bills'] as int? ?? 0,
    );
  }

  factory CommissionSummary.empty() {
    return CommissionSummary(
      totalCommission: 0,
      pendingCommission: 0,
      approvedCommission: 0,
      paidCommission: 0,
      totalBills: 0,
      pendingBills: 0,
      approvedBills: 0,
      paidBills: 0,
    );
  }
}
