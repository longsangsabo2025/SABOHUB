// Inventory module constants and shared utilities

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client instance
final supabase = Supabase.instance.client;

/// Currency formatter for Vietnamese Dong
final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

/// Warehouse type configuration
class WarehouseTypeConfig {
  final Color color;
  final String label;
  final IconData icon;
  
  const WarehouseTypeConfig({
    required this.color,
    required this.label,
    required this.icon,
  });
  
  /// Get warehouse type configuration from type string
  static WarehouseTypeConfig fromType(String? type) {
    switch (type) {
      case 'main':
        return WarehouseTypeConfig(
          color: Colors.blue,
          label: 'Kho chính',
          icon: Icons.home_work,
        );
      case 'transit':
        return WarehouseTypeConfig(
          color: Colors.orange,
          label: 'Kho phụ',
          icon: Icons.warehouse,
        );
      case 'vehicle':
        return WarehouseTypeConfig(
          color: Colors.green,
          label: 'Xe giao hàng',
          icon: Icons.local_shipping,
        );
      case 'virtual':
        return WarehouseTypeConfig(
          color: Colors.purple,
          label: 'Kho ảo',
          icon: Icons.cloud_outlined,
        );
      default:
        return WarehouseTypeConfig(
          color: Colors.grey,
          label: type ?? 'Không xác định',
          icon: Icons.warehouse,
        );
    }
  }
}

/// Movement type configuration
class MovementTypeConfig {
  final Color color;
  final IconData icon;
  final String label;
  
  const MovementTypeConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
  
  /// Get movement type configuration from type string
  static MovementTypeConfig fromType(String? type) {
    switch (type) {
      case 'in':
        return MovementTypeConfig(
          color: Colors.green,
          icon: Icons.arrow_downward,
          label: 'Nhập kho',
        );
      case 'out':
        return MovementTypeConfig(
          color: Colors.red,
          icon: Icons.arrow_upward,
          label: 'Xuất kho',
        );
      case 'transfer':
        return MovementTypeConfig(
          color: Colors.blue,
          icon: Icons.swap_horiz,
          label: 'Chuyển kho',
        );
      case 'adjustment':
        return MovementTypeConfig(
          color: Colors.orange,
          icon: Icons.edit,
          label: 'Điều chỉnh',
        );
      default:
        return MovementTypeConfig(
          color: Colors.grey,
          icon: Icons.sync,
          label: type ?? 'Không xác định',
        );
    }
  }
}

/// Get category icon based on category name
IconData getCategoryIcon(String? categoryName) {
  final name = (categoryName ?? '').toLowerCase();
  if (name.contains('đồ uống') || name.contains('nước')) return Icons.local_drink;
  if (name.contains('bánh') || name.contains('snack')) return Icons.cookie;
  if (name.contains('rau') || name.contains('củ')) return Icons.eco;
  if (name.contains('thịt') || name.contains('cá')) return Icons.set_meal;
  if (name.contains('sữa')) return Icons.water_drop;
  if (name.contains('gia vị')) return Icons.restaurant;
  return Icons.inventory_2;
}

/// Format date for display
String formatDate(String? dateString) {
  if (dateString == null) return '';
  try {
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  } catch (e) {
    return dateString;
  }
}
