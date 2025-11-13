/// KPI Target Model
/// Defines performance targets for employees and roles
class KPITarget {
  final String id;
  final String? userId;
  final String? role;
  final String metricName;
  final String metricType; // completion_rate, quality_score, timeliness, photo_submission, custom
  final double targetValue;
  final String period; // daily, weekly, monthly
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  KPITarget({
    required this.id,
    this.userId,
    this.role,
    required this.metricName,
    required this.metricType,
    required this.targetValue,
    this.period = 'weekly',
    this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KPITarget.fromJson(Map<String, dynamic> json) {
    return KPITarget(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      role: json['role'] as String?,
      metricName: json['metric_name'] as String,
      metricType: json['metric_type'] as String,
      targetValue: (json['target_value'] as num).toDouble(),
      period: json['period'] as String? ?? 'weekly',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'metric_name': metricName,
      'metric_type': metricType,
      'target_value': targetValue,
      'period': period,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if target is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;

    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    return true;
  }

  /// Get metric type display name
  String get metricTypeDisplay {
    switch (metricType) {
      case 'completion_rate':
        return 'Tỷ lệ hoàn thành';
      case 'quality_score':
        return 'Điểm chất lượng';
      case 'timeliness':
        return 'Đúng giờ';
      case 'photo_submission':
        return 'Gửi hình ảnh';
      case 'custom':
        return 'Tùy chỉnh';
      default:
        return metricType;
    }
  }

  /// Get period display name
  String get periodDisplay {
    switch (period) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      default:
        return period;
    }
  }
}
