/// Commission Rule Model - Quy tắc hoa hồng do CEO thiết lập
class CommissionRule {
  final String id;
  final String companyId;
  final String ruleName;
  final String? description;
  final String appliesTo; // all, role, individual
  final String? role; // ceo, manager, staff, etc.
  final String? userId; // Nếu appliesTo = individual
  final double commissionPercentage; // 0-100
  final double minBillAmount;
  final double? maxBillAmount;
  final bool isActive;
  final int priority;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommissionRule({
    required this.id,
    required this.companyId,
    required this.ruleName,
    this.description,
    this.appliesTo = 'all',
    this.role,
    this.userId,
    required this.commissionPercentage,
    this.minBillAmount = 0,
    this.maxBillAmount,
    this.isActive = true,
    this.priority = 0,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionRule.fromJson(Map<String, dynamic> json) {
    return CommissionRule(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      ruleName: json['rule_name'] as String,
      description: json['description'] as String?,
      appliesTo: json['applies_to'] as String? ?? 'all',
      role: json['role'] as String?,
      userId: json['user_id'] as String?,
      commissionPercentage: (json['commission_percentage'] as num).toDouble(),
      minBillAmount: (json['min_bill_amount'] as num?)?.toDouble() ?? 0,
      maxBillAmount: (json['max_bill_amount'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : null,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'rule_name': ruleName,
      'description': description,
      'applies_to': appliesTo,
      'role': role,
      'user_id': userId,
      'commission_percentage': commissionPercentage,
      'min_bill_amount': minBillAmount,
      'max_bill_amount': maxBillAmount,
      'is_active': isActive,
      'priority': priority,
      'effective_from': effectiveFrom.toIso8601String().split('T')[0],
      'effective_to': effectiveTo?.toIso8601String().split('T')[0],
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CommissionRule copyWith({
    String? id,
    String? companyId,
    String? ruleName,
    String? description,
    String? appliesTo,
    String? role,
    String? userId,
    double? commissionPercentage,
    double? minBillAmount,
    double? maxBillAmount,
    bool? isActive,
    int? priority,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommissionRule(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      ruleName: ruleName ?? this.ruleName,
      description: description ?? this.description,
      appliesTo: appliesTo ?? this.appliesTo,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      minBillAmount: minBillAmount ?? this.minBillAmount,
      maxBillAmount: maxBillAmount ?? this.maxBillAmount,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Applies To Enum
enum AppliesTo {
  all('all', 'Tất cả nhân viên', '👥'),
  role('role', 'Theo vai trò', '🎭'),
  individual('individual', 'Cá nhân cụ thể', '👤');

  final String value;
  final String label;
  final String emoji;

  const AppliesTo(this.value, this.label, this.emoji);

  static AppliesTo fromString(String value) {
    return AppliesTo.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AppliesTo.all,
    );
  }
}
