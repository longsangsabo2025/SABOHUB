class Referrer {
  final String id;
  final String companyId;
  final String name;
  final String? phone;
  final String? email;
  final String? bankName;
  final String? bankAccount;
  final String? bankHolder;
  final double commissionRate; // % hoa hồng
  final String commissionType; // 'first_order' hoặc 'all_orders'
  final String? notes;
  final String status;
  final double totalEarned;
  final double totalPaid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Referrer({
    required this.id,
    required this.companyId,
    required this.name,
    this.phone,
    this.email,
    this.bankName,
    this.bankAccount,
    this.bankHolder,
    this.commissionRate = 0,
    this.commissionType = 'all_orders',
    this.notes,
    this.status = 'active',
    this.totalEarned = 0,
    this.totalPaid = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Referrer.fromJson(Map<String, dynamic> json) {
    return Referrer(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      bankName: json['bank_name'],
      bankAccount: json['bank_account'],
      bankHolder: json['bank_holder'],
      commissionRate: (json['commission_rate'] ?? 0).toDouble(),
      commissionType: json['commission_type'] ?? 'all_orders',
      notes: json['notes'],
      status: json['status'] ?? 'active',
      totalEarned: (json['total_earned'] ?? 0).toDouble(),
      totalPaid: (json['total_paid'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'phone': phone,
      'email': email,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'bank_holder': bankHolder,
      'commission_rate': commissionRate,
      'commission_type': commissionType,
      'notes': notes,
      'status': status,
      'total_earned': totalEarned,
      'total_paid': totalPaid,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      'name': name,
      'phone': phone,
      'email': email,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'bank_holder': bankHolder,
      'commission_rate': commissionRate,
      'commission_type': commissionType,
      'notes': notes,
      'status': status,
    };
  }

  Referrer copyWith({
    String? id,
    String? companyId,
    String? name,
    String? phone,
    String? email,
    String? bankName,
    String? bankAccount,
    String? bankHolder,
    double? commissionRate,
    String? commissionType,
    String? notes,
    String? status,
    double? totalEarned,
    double? totalPaid,
  }) {
    return Referrer(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankHolder: bankHolder ?? this.bankHolder,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionType: commissionType ?? this.commissionType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      totalEarned: totalEarned ?? this.totalEarned,
      totalPaid: totalPaid ?? this.totalPaid,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get commissionTypeText {
    switch (commissionType) {
      case 'first_order':
        return 'Chỉ đơn đầu';
      case 'all_orders':
        return 'Tất cả đơn';
      default:
        return commissionType;
    }
  }

  double get pendingAmount => totalEarned - totalPaid;
}

class Commission {
  final String id;
  final String companyId;
  final String referrerId;
  final String customerId;
  final String? orderId;
  final String? orderCode;
  final double orderAmount;
  final double commissionRate;
  final double commissionAmount;
  final String status;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? paidAt;
  final String? paidBy;
  final String? paymentNote;
  final DateTime? createdAt;
  
  // Joined data
  final String? referrerName;
  final String? customerName;

  Commission({
    required this.id,
    required this.companyId,
    required this.referrerId,
    required this.customerId,
    this.orderId,
    this.orderCode,
    required this.orderAmount,
    required this.commissionRate,
    required this.commissionAmount,
    this.status = 'pending',
    this.approvedAt,
    this.approvedBy,
    this.paidAt,
    this.paidBy,
    this.paymentNote,
    this.createdAt,
    this.referrerName,
    this.customerName,
  });

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      referrerId: json['referrer_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      orderId: json['order_id'],
      orderCode: json['order_code'],
      orderAmount: (json['order_amount'] ?? 0).toDouble(),
      commissionRate: (json['commission_rate'] ?? 0).toDouble(),
      commissionAmount: (json['commission_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      approvedBy: json['approved_by'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      paidBy: json['paid_by'],
      paymentNote: json['payment_note'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      referrerName: json['referrers']?['name'],
      customerName: json['customers']?['name'],
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'paid':
        return 'Đã trả';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
