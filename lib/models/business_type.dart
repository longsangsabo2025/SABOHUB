import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum BusinessType {
  // Corporation / Holding — parent company with multiple business units
  // NOTE: 'corporation' is client-only — NOT in DB CHECK constraint for business_type
  @Deprecated('Not in DB CHECK constraint — used for UI grouping only')
  corporation('Tổng Công Ty', Icons.domain, AppColors.backgroundDark),

  // Entertainment / F&B
  billiards('Quán Bida', Icons.sports_bar, AppColors.info),
  restaurant('Nhà Hàng', Icons.restaurant, AppColors.success),
  hotel('Khách Sạn', Icons.hotel, AppColors.warning),
  cafe('Quán Cafe', Icons.coffee, AppColors.primary),
  retail('Cửa Hàng', Icons.store, AppColors.error),
  
  // Distribution / Manufacturing (Odori)
  distribution('Phân Phối', Icons.local_shipping, Color(0xFF0EA5E9)),
  manufacturing('Sản Xuất', Icons.factory, AppColors.success),

  // AI Assistant — Travis AI dedicated space
  aiAssistant('AI Assistant', Icons.smart_toy, Color(0xFF8B5CF6));

  final String label;
  final IconData icon;
  final Color color;
  const BusinessType(this.label, this.icon, this.color);

  /// Corporation — parent company managing multiple divisions
  // ignore: deprecated_member_use_from_same_package
  bool get isCorporation => this == BusinessType.corporation;

  /// Check if this is a distribution/delivery business type (like Odori)
  bool get isDistribution => this == BusinessType.distribution || this == BusinessType.manufacturing;

  /// Check if this is specifically manufacturing (not pure distribution)
  bool get isManufacturing => this == BusinessType.manufacturing;

  /// AI Assistant — Travis AI dedicated workspace
  bool get isAiAssistant => this == BusinessType.aiAssistant;

  /// Service businesses (billiards, restaurant, hotel, cafe, retail)
  bool get isService => !isDistribution && !isAiAssistant;

  /// Backward compatibility alias
  bool get isEntertainment => isService;

  /// CEO-facing label
  String get ceoLabel {
    if (isCorporation) return 'Tổng Công Ty';
    if (isManufacturing) return 'Sản Xuất';
    if (isDistribution) return 'Phân Phối';
    if (isAiAssistant) return 'AI Assistant';
    return 'Vận Hành';
  }
}
