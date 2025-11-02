import 'package:flutter/material.dart';

/// Payment method enum
enum PaymentMethod {
  cash('Tiền mặt', Color(0xFF10B981)), // Green
  card('Thẻ ATM/Credit', Color(0xFF3B82F6)), // Blue
  qr('QR Code', Color(0xFF8B5CF6)), // Purple
  transfer('Chuyển khoản', Color(0xFF06B6D4)); // Cyan

  final String label;
  final Color color;
  const PaymentMethod(this.label, this.color);
}

/// Payment status enum
enum PaymentStatus {
  pending('Đang chờ', Color(0xFFF59E0B)),
  completed('Hoàn thành', Color(0xFF10B981)),
  failed('Thất bại', Color(0xFFEF4444)),
  refunded('Đã hoàn tiền', Color(0xFF6B7280));

  final String label;
  final Color color;
  const PaymentStatus(this.label, this.color);
}

/// Payment model - represents a payment transaction
class Payment {
  final String id;
  final String sessionId;
  final String companyId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime paidAt;
  final String? notes;
  final String? referenceNumber; // Mã giao dịch
  final String? customerName;

  const Payment({
    required this.id,
    required this.sessionId,
    required this.companyId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
    this.notes,
    this.referenceNumber,
    this.customerName,
  });

  // Alias for backward compatibility
  DateTime get createdAt => paidAt;

  Payment copyWith({
    String? id,
    String? sessionId,
    String? companyId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? paidAt,
    String? notes,
    String? referenceNumber,
    String? customerName,
  }) {
    return Payment(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      companyId: companyId ?? this.companyId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      customerName: customerName ?? this.customerName,
    );
  }
}
