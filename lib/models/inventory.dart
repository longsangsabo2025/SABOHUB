import 'package:flutter/material.dart';

enum InventoryCategory {
  food('Đồ ăn', Color(0xFFF59E0B)),
  beverage('Đồ uống', Color(0xFF3B82F6)),
  equipment('Thiết bị', Color(0xFF8B5CF6)),
  cleaning('Vệ sinh', Color(0xFF10B981)),
  other('Khác', Color(0xFF6B7280));

  final String label;
  final Color color;
  const InventoryCategory(this.label, this.color);
}

class InventoryItem {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final InventoryCategory category;
  final String unit;
  final double quantity; // Changed from currentStock for consistency
  final double minQuantity; // Changed from minThreshold for consistency
  final double unitPrice; // Changed from cost for clarity
  final String? supplier;
  final DateTime? lastRestocked;
  final DateTime createdAt;

  const InventoryItem({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.minQuantity,
    required this.unitPrice,
    this.supplier,
    this.lastRestocked,
    required this.createdAt,
  });

  bool get isLowStock => quantity <= minQuantity;
  double get totalValue => unitPrice * quantity;

  // Backward compatibility aliases
  double get currentStock => quantity;
  double get minThreshold => minQuantity;
  double get cost => unitPrice;

  InventoryItem copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    InventoryCategory? category,
    String? unit,
    double? quantity,
    double? minQuantity,
    double? unitPrice,
    String? supplier,
    DateTime? lastRestocked,
    DateTime? createdAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
