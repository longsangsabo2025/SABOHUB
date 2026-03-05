import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Payment method enum
enum PaymentMethod {
  cash('Tiền mặt', AppColors.success), // Green
  card('Thẻ ATM/Credit', AppColors.info), // Blue
  qr('QR Code', AppColors.primary), // Purple
  transfer('Chuyển khoản', AppColors.secondary); // Cyan

  final String label;
  final Color color;
  const PaymentMethod(this.label, this.color);
}

/// Payment status enum
enum PaymentStatus {
  pending('Đang chờ', AppColors.warning),
  completed('Hoàn thành', AppColors.success),
  failed('Thất bại', AppColors.error),
  refunded('Đã hoàn tiền', AppColors.neutral500);

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
