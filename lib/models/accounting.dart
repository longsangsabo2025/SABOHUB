import 'package:intl/intl.dart';

/// Transaction Type Enum
enum TransactionType {
  revenue('Thu nhập', 'revenue'),
  expense('Chi phí', 'expense'),
  salary('Lương', 'salary'),
  utility('Tiện ích', 'utility'),
  maintenance('Bảo trì', 'maintenance'),
  other('Khác', 'other');

  final String label;
  final String value;
  const TransactionType(this.label, this.value);
}

/// Payment Method Enum
enum PaymentMethod {
  cash('Tiền mặt', 'cash'),
  bank('Chuyển khoản', 'bank'),
  transfer('Chuyển khoản', 'transfer'),
  card('Thẻ', 'card'),
  momo('MoMo', 'momo'),
  debt('Công nợ', 'debt'),
  other('Khác', 'other');

  final String label;
  final String value;
  const PaymentMethod(this.label, this.value);
}

/// Accounting Transaction Model
class AccountingTransaction {
  final String id;
  final String companyId;
  final String? branchId;
  final TransactionType type;
  final double amount;
  final String description;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String? category;
  final String? referenceId;
  final String? notes;
  final String? status;
  final String? counterpartyName;
  final String? itemsSummary;
  final String? createdBy;
  final DateTime? createdAt;

  const AccountingTransaction({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.type,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    required this.date,
    this.category,
    this.referenceId,
    this.notes,
    this.status,
    this.counterpartyName,
    this.itemsSummary,
    this.createdBy,
    this.createdAt,
  });

  factory AccountingTransaction.fromJson(Map<String, dynamic> json) {
    return AccountingTransaction(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      branchId: json['branch_id'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => TransactionType.other,
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.value == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String?,
      referenceId: json['reference_id'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String?,
      counterpartyName: json['counterparty_name'] as String?,
      itemsSummary: json['items_summary'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'branch_id': branchId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'payment_method': paymentMethod.value,
      'date': date.toIso8601String(),
      'category': category,
      'reference_id': referenceId,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// Accounting Summary Model
class AccountingSummary {
  final double totalRevenue;
  final double totalExpense;
  final double netProfit;
  final double profitMargin;
  final int transactionCount;
  final DateTime startDate;
  final DateTime endDate;
  // Extended fields for real data
  final double totalReceivable;
  final int paidOrderCount;
  final int unpaidOrderCount;

  const AccountingSummary({
    required this.totalRevenue,
    required this.totalExpense,
    required this.netProfit,
    required this.profitMargin,
    required this.transactionCount,
    required this.startDate,
    required this.endDate,
    this.totalReceivable = 0,
    this.paidOrderCount = 0,
    this.unpaidOrderCount = 0,
  });

  String get formattedRevenue => NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      ).format(totalRevenue);

  String get formattedExpense => NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      ).format(totalExpense);

  String get formattedNetProfit => NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      ).format(netProfit);

  String get formattedProfitMargin => '${profitMargin.toStringAsFixed(1)}%';

  String get formattedReceivable => NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      ).format(totalReceivable);
}

/// Daily Revenue Model
class DailyRevenue {
  final String id;
  final String companyId;
  final String? branchId;
  final DateTime date;
  final double amount;
  final int tableCount;
  final int customerCount;
  final int orderCount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailyRevenue({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.date,
    required this.amount,
    this.tableCount = 0,
    this.customerCount = 0,
    this.orderCount = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      branchId: json['branch_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      tableCount: json['table_count'] as int? ?? 0,
      customerCount: json['customer_count'] as int? ?? 0,
      orderCount: json['order_count'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'branch_id': branchId,
      'date': date.toIso8601String(),
      'amount': amount,
      'table_count': tableCount,
      'customer_count': customerCount,
      'order_count': orderCount,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedAmount => NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      ).format(amount);
}

/// Expense Category Model
class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final double budget;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.budget,
  });
}
