import 'package:flutter/material.dart';
import '../../../../../../../../core/theme/app_colors.dart';

enum BusinessType {
  // Corporation / Holding — parent company with multiple business units
  corporation('Tổng Công Ty', Icons.domain, Color(0xFF0F172A)),

  // Entertainment / F&B
  billiards('Quán Bida', Icons.sports_bar, AppColors.info),
  restaurant('Nhà Hàng', Icons.restaurant, AppColors.success),
  hotel('Khách Sạn', Icons.hotel, AppColors.warning),
  cafe('Quán Cafe', Icons.coffee, AppColors.primary),
  retail('Cửa Hàng', Icons.store, AppColors.error),
  
  // Distribution / Manufacturing (Odori)
  distribution('Phân Phối', Icons.local_shipping, Color(0xFF0EA5E9)),
  manufacturing('Sản Xuất', Icons.factory, Color(0xFF22C55E));

  final String label;
  final IconData icon;
  final Color color;
  const BusinessType(this.label, this.icon, this.color);

  /// Corporation — parent company managing multiple divisions
  bool get isCorporation => this == BusinessType.corporation;

  /// Check if this is a distribution/delivery business type (like Odori)
  bool get isDistribution => this == BusinessType.distribution || this == BusinessType.manufacturing;

  /// Check if this is specifically manufacturing (not pure distribution)
  bool get isManufacturing => this == BusinessType.manufacturing;

  /// Entertainment/retail or corporation with entertainment operations
  bool get isEntertainment => !isDistribution;

  /// CEO-facing label
  String get ceoLabel {
    if (isCorporation) return 'Tổng Công Ty';
    if (isManufacturing) return 'Sản Xuất';
    if (isDistribution) return 'Phân Phối';
    return 'Vận Hành';
  }
}
