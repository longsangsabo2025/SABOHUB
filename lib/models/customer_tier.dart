// Customer Tier Classification - Phân loại khách hàng theo doanh số
// Dựa trên view v_sales_by_customer từ database
import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Tier phân loại khách hàng theo doanh số
enum CustomerTier {
  bronze,   // Đồng: < 5 triệu
  silver,   // Bạc: 5 - 20 triệu
  gold,     // Vàng: 20 - 100 triệu
  diamond,  // Kim Cương: > 100 triệu
  none,     // Chưa có đơn hàng
}

extension CustomerTierExtension on CustomerTier {
  /// Tên hiển thị tiếng Việt
  String get displayName {
    switch (this) {
      case CustomerTier.diamond:
        return 'Kim Cương';
      case CustomerTier.gold:
        return 'Vàng';
      case CustomerTier.silver:
        return 'Bạc';
      case CustomerTier.bronze:
        return 'Đồng';
      case CustomerTier.none:
        return 'Mới';
    }
  }

  /// Emoji/icon cho tier
  String get emoji {
    switch (this) {
      case CustomerTier.diamond:
        return '💎';
      case CustomerTier.gold:
        return '🥇';
      case CustomerTier.silver:
        return '🥈';
      case CustomerTier.bronze:
        return '🥉';
      case CustomerTier.none:
        return '🆕';
    }
  }

  /// Màu sắc đại diện
  Color get color {
    switch (this) {
      case CustomerTier.diamond:
        return Color(0xFF00BCD4); // Cyan/Diamond blue
      case CustomerTier.gold:
        return Color(0xFFFFD700); // Gold
      case CustomerTier.silver:
        return Color(0xFFC0C0C0); // Silver
      case CustomerTier.bronze:
        return AppColors.tierBronze; // Bronze
      case CustomerTier.none:
        return Colors.grey;
    }
  }

  /// Màu text trên badge
  Color get textColor {
    switch (this) {
      case CustomerTier.diamond:
        return Colors.white;
      case CustomerTier.gold:
        return const Color(0xDD000000);
      case CustomerTier.silver:
        return const Color(0xDD000000);
      case CustomerTier.bronze:
        return Colors.white;
      case CustomerTier.none:
        return Colors.white;
    }
  }

  /// Ngưỡng tối thiểu (VND)
  double get minRevenue {
    switch (this) {
      case CustomerTier.diamond:
        return 100000000; // 100 triệu
      case CustomerTier.gold:
        return 20000000;  // 20 triệu
      case CustomerTier.silver:
        return 5000000;   // 5 triệu
      case CustomerTier.bronze:
        return 1;         // > 0
      case CustomerTier.none:
        return 0;
    }
  }

  /// Tính tier dựa trên tổng doanh số
  static CustomerTier fromRevenue(double? totalRevenue) {
    if (totalRevenue == null || totalRevenue <= 0) {
      return CustomerTier.none;
    }
    if (totalRevenue >= 100000000) {
      return CustomerTier.diamond;
    }
    if (totalRevenue >= 20000000) {
      return CustomerTier.gold;
    }
    if (totalRevenue >= 5000000) {
      return CustomerTier.silver;
    }
    return CustomerTier.bronze;
  }
  
  /// Parse tier từ string (từ database)
  static CustomerTier fromString(String? value) {
    if (value == null) return CustomerTier.bronze;
    switch (value.toLowerCase()) {
      case 'diamond':
        return CustomerTier.diamond;
      case 'gold':
        return CustomerTier.gold;
      case 'silver':
        return CustomerTier.silver;
      case 'bronze':
        return CustomerTier.bronze;
      case 'none':
        return CustomerTier.none;
      default:
        return CustomerTier.bronze;
    }
  }
}

/// Model chứa thông tin doanh số của khách hàng từ v_sales_by_customer
class CustomerRevenue {
  final String customerId;
  final String? companyId;
  final String? customerName;
  final String? customerType;
  final String? channel;
  final String? assignedSaleId;
  final int totalOrders;
  final int completedOrders;
  final double totalRevenue;
  final double paidAmount;
  final double outstandingAmount;
  final DateTime? lastOrderDate;

  const CustomerRevenue({
    required this.customerId,
    this.companyId,
    this.customerName,
    this.customerType,
    this.channel,
    this.assignedSaleId,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.totalRevenue = 0,
    this.paidAmount = 0,
    this.outstandingAmount = 0,
    this.lastOrderDate,
  });

  /// Tier của khách hàng dựa trên tổng doanh số
  CustomerTier get tier => CustomerTierExtension.fromRevenue(totalRevenue);

  /// Tỷ lệ hoàn thành đơn hàng
  double get completionRate {
    if (totalOrders == 0) return 0;
    return completedOrders / totalOrders * 100;
  }

  /// Tỷ lệ thanh toán
  double get paymentRate {
    if (totalRevenue == 0) return 0;
    return paidAmount / totalRevenue * 100;
  }

  factory CustomerRevenue.fromJson(Map<String, dynamic> json) {
    return CustomerRevenue(
      customerId: json['customer_id'] as String,
      companyId: json['company_id'] as String?,
      customerName: json['customer_name'] as String?,
      customerType: json['customer_type'] as String?,
      channel: json['channel'] as String?,
      assignedSaleId: json['assigned_sale_id'] as String?,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completed_orders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0,
      lastOrderDate: json['last_order_date'] != null
          ? DateTime.tryParse(json['last_order_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'company_id': companyId,
      'customer_name': customerName,
      'customer_type': customerType,
      'channel': channel,
      'assigned_sale_id': assignedSaleId,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'total_revenue': totalRevenue,
      'paid_amount': paidAmount,
      'outstanding_amount': outstandingAmount,
      'last_order_date': lastOrderDate?.toIso8601String(),
    };
  }
}
