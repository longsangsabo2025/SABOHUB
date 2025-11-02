import 'company.dart';
import 'order.dart';
import 'payment.dart';
import 'session.dart';

/// Receipt model - represents a printed receipt
class Receipt {
  final String id;
  final String sessionId;
  final String companyId;
  final Company company;
  final TableSession session;
  final List<Order> orders;
  final List<Payment> payments;
  final DateTime createdAt;
  final String? cashierName;
  final String? notes;

  const Receipt({
    required this.id,
    required this.sessionId,
    required this.companyId,
    required this.company,
    required this.session,
    required this.orders,
    required this.payments,
    required this.createdAt,
    this.cashierName,
    this.notes,
  });

  // Calculate totals
  double get tableAmount => session.tableAmount;
  double get ordersAmount => session.ordersAmount;
  double get subtotal => tableAmount + ordersAmount;
  double get tax => subtotal * 0.1; // 10% VAT
  double get totalAmount => subtotal + tax;
  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get changeAmount => totalPaid - totalAmount;

  Receipt copyWith({
    String? id,
    String? sessionId,
    String? companyId,
    Company? company,
    TableSession? session,
    List<Order>? orders,
    List<Payment>? payments,
    DateTime? createdAt,
    String? cashierName,
    String? notes,
  }) {
    return Receipt(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      companyId: companyId ?? this.companyId,
      company: company ?? this.company,
      session: session ?? this.session,
      orders: orders ?? this.orders,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      cashierName: cashierName ?? this.cashierName,
      notes: notes ?? this.notes,
    );
  }
}
