/// Odori B2B Receivables & Payment Models
class OdoriReceivable {
  final String id;
  final String companyId;
  final String customerId;
  final String? customerName;
  final String? orderId;
  final String? orderNumber;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double originalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status; // 'open', 'partial', 'paid', 'overdue', 'written_off'
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OdoriReceivable({
    required this.id,
    required this.companyId,
    required this.customerId,
    this.customerName,
    this.orderId,
    this.orderNumber,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.originalAmount,
    this.paidAmount = 0,
    required this.remainingAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue => status == 'overdue' || (status == 'open' && DateTime.now().isAfter(dueDate));
  int get daysOverdue => DateTime.now().difference(dueDate).inDays;
  
  String get agingBucket {
    if (status == 'paid') return 'paid';
    final days = daysOverdue;
    if (days <= 0) return 'current';
    if (days <= 30) return '1-30';
    if (days <= 60) return '31-60';
    if (days <= 90) return '61-90';
    return '90+';
  }

  factory OdoriReceivable.fromJson(Map<String, dynamic> json) {
    return OdoriReceivable(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customers']?['name'] as String?,
      orderId: json['order_id'] as String?,
      orderNumber: json['sales_orders']?['order_number'] as String?,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      originalAmount: (json['original_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
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
      'order_id': orderId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'original_amount': originalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'status': status,
      'notes': notes,
    };
  }
}

class OdoriPayment {
  final String id;
  final String companyId;
  final String? receivableId;
  final String customerId;
  final String? customerName;
  final String paymentNumber;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod; // 'cash', 'bank_transfer', 'check', 'mobile_payment'
  final String? referenceNumber;
  final String? collectedBy;
  final String? collectedByName;
  final String? notes;
  final String? proofImageUrl;
  final String status; // 'pending', 'confirmed', 'rejected'
  final DateTime createdAt;

  const OdoriPayment({
    required this.id,
    required this.companyId,
    this.receivableId,
    required this.customerId,
    this.customerName,
    required this.paymentNumber,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    this.collectedBy,
    this.collectedByName,
    this.notes,
    this.proofImageUrl,
    this.status = 'confirmed',
    required this.createdAt,
  });

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'cash':
        return 'Tiền mặt';
      case 'bank_transfer':
        return 'Chuyển khoản';
      case 'check':
        return 'Séc';
      case 'mobile_payment':
        return 'Ví điện tử';
      default:
        return paymentMethod;
    }
  }

  factory OdoriPayment.fromJson(Map<String, dynamic> json) {
    return OdoriPayment(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      receivableId: json['receivable_id'] as String?,
      customerId: json['customer_id'] as String,
      customerName: json['customers']?['name'] as String?,
      paymentNumber: json['payment_number'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      referenceNumber: json['reference_number'] as String?,
      collectedBy: json['collected_by'] as String?,
      collectedByName: json['employees']?['full_name'] as String?,
      notes: json['notes'] as String?,
      proofImageUrl: json['proof_image_url'] as String?,
      status: json['status'] as String? ?? 'confirmed',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'receivable_id': receivableId,
      'customer_id': customerId,
      'payment_number': paymentNumber,
      'payment_date': paymentDate.toIso8601String(),
      'amount': amount,
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'collected_by': collectedBy,
      'notes': notes,
      'proof_image_url': proofImageUrl,
      'status': status,
    };
  }
}
