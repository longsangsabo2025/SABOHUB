import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

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
  pending('Chờ xử lý', AppColors.warning),
  preparing('Đang chuẩn bị', AppColors.info),
  ready('Sẵn sàng', AppColors.success),
  completed('Hoàn thành', AppColors.neutral500),
  cancelled('Đã hủy', AppColors.error);

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
