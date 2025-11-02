import 'package:flutter/material.dart';

enum BusinessType {
  billiards('Quán Bida', Icons.sports_bar, Color(0xFF3B82F6)),
  restaurant('Nhà Hàng', Icons.restaurant, Color(0xFF10B981)),
  hotel('Khách Sạn', Icons.hotel, Color(0xFFF59E0B)),
  cafe('Quán Cafe', Icons.coffee, Color(0xFF8B5CF6)),
  retail('Cửa Hàng', Icons.store, Color(0xFFEF4444));

  final String label;
  final IconData icon;
  final Color color;
  const BusinessType(this.label, this.icon, this.color);
}
