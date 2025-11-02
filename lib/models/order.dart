import 'package:flutter/material.dart';

class OrderItem {
  final String menuItemId;
  final String menuItemName;
  final double price;
  final int quantity;
  final String? notes;

  const OrderItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.price,
    required this.quantity,
    this.notes,
  });

  double get totalPrice => price * quantity;

  OrderItem copyWith({
    String? menuItemId,
    String? menuItemName,
    double? price,
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

enum OrderStatus {
  pending('Chờ xử lý', Color(0xFFF59E0B)),
  preparing('Đang chuẩn bị', Color(0xFF3B82F6)),
  ready('Sẵn sàng', Color(0xFF10B981)),
  completed('Hoàn thành', Color(0xFF6B7280)),
  cancelled('Đã hủy', Color(0xFFEF4444));

  final String label;
  final Color color;
  const OrderStatus(this.label, this.color);
}

class Order {
  final String id;
  final String companyId;
  final String? tableId;
  final String? tableName;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final String? customerName;
  final String? notes;

  const Order({
    required this.id,
    required this.companyId,
    this.tableId,
    this.tableName,
    required this.items,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.notes,
  });

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get total => totalAmount; // Alias

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    String? companyId,
    String? tableId,
    String? tableName,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? createdAt,
    String? customerName,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }
}
