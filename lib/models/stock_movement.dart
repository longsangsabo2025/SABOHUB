import 'package:flutter/material.dart';

enum StockMovementType {
  stockIn('Nhập kho', Color(0xFF10B981)),
  stockOut('Xuất kho', Color(0xFFEF4444)),
  adjustment('Điều chỉnh', Color(0xFF3B82F6)),
  damaged('Hư hỏng', Color(0xFF6B7280));

  final String label;
  final Color color;
  const StockMovementType(this.label, this.color);
}

class StockMovement {
  final String id;
  final String itemId;
  final String itemName;
  final String companyId;
  final StockMovementType type;
  final double quantity;
  final String reason;
  final String createdBy;
  final String createdByName;
  final DateTime date;

  const StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.companyId,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.createdBy,
    required this.createdByName,
    required this.date,
  });

  // Alias for backward compatibility
  DateTime get createdAt => date;

  StockMovement copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? companyId,
    StockMovementType? type,
    double? quantity,
    String? reason,
    String? createdBy,
    String? createdByName,
    DateTime? date,
  }) {
    return StockMovement(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      companyId: companyId ?? this.companyId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      date: date ?? this.date,
    );
  }
}
