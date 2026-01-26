import 'package:flutter/material.dart';

enum BusinessType {
  // Entertainment / F&B
  billiards('Quán Bida', Icons.sports_bar, Color(0xFF3B82F6)),
  restaurant('Nhà Hàng', Icons.restaurant, Color(0xFF10B981)),
  hotel('Khách Sạn', Icons.hotel, Color(0xFFF59E0B)),
  cafe('Quán Cafe', Icons.coffee, Color(0xFF8B5CF6)),
  retail('Cửa Hàng', Icons.store, Color(0xFFEF4444)),
  
  // Distribution / Manufacturing (Odori)
  distribution('Phân Phối', Icons.local_shipping, Color(0xFF0EA5E9)),
  manufacturing('Sản Xuất', Icons.factory, Color(0xFF22C55E));

  final String label;
  final IconData icon;
  final Color color;
  const BusinessType(this.label, this.icon, this.color);

  /// Check if this is a distribution/delivery business type (like Odori)
  bool get isDistribution => this == BusinessType.distribution || this == BusinessType.manufacturing;

  /// Check if this is an entertainment/retail business type (like SABO Billiards)
  bool get isEntertainment => !isDistribution;
}
