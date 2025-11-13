import '../core/services/supabase_service.dart';
import '../models/kpi_target.dart';
import 'performance_metrics_service.dart';

/// KPI Service
/// Manages KPI targets and evaluates employee performance
class KPIService {
  final _supabase = supabase.client;
  final _metricsService = PerformanceMetricsService();

  /// Create a new KPI target
  Future<KPITarget> createTarget({
    String? userId,
    String? role,
    required String metricName,
    required String metricType,
    required double targetValue,
    String period = 'weekly',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.from('kpi_targets').insert({
        'user_id': userId,
        'role': role,
        'metric_name': metricName,
        'metric_type': metricType,
        'target_value': targetValue,
        'period': period,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'is_active': true,
      }).select().single();

      return KPITarget.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create KPI target: $e');
    }
  }

  /// Get all active KPI targets for a user
  Future<List<KPITarget>> getUserTargets(String userId) async {
    try {
      final response = await _supabase
          .from('kpi_targets')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => KPITarget.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user targets: $e');
    }
  }

  /// Get all active KPI targets for a role
  Future<List<KPITarget>> getRoleTargets(String role) async {
    try {
      final response = await _supabase
          .from('kpi_targets')
          .select()
          .eq('role', role)
          .eq('is_active', true)
          .isFilter('user_id', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => KPITarget.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get role targets: $e');
    }
  }

  /// Evaluate employee performance against KPI targets
  Future<Map<String, dynamic>> evaluatePerformance({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get user's KPI targets
      final targets = await getUserTargets(userId);

      // Get employee info for role-based targets
      final employee = await _supabase
          .from('employees')
          .select('role, full_name')
          .eq('id', userId)
          .maybeSingle();

      final role = employee?['role'] as String?;
      final userName = employee?['full_name'] as String? ?? 'Unknown';

      // Get role-based targets if no user-specific targets
      if (targets.isEmpty && role != null) {
        final roleTargets = await getRoleTargets(role);
        targets.addAll(roleTargets);
      }

      if (targets.isEmpty) {
        return {
          'user_id': userId,
          'user_name': userName,
          'targets_met': 0,
          'total_targets': 0,
          'overall_score': 0.0,
          'evaluation': 'Chưa có KPI',
          'details': [],
        };
      }

      // Get performance metrics
      final metrics = await _metricsService.getMetrics(
        userId: userId,
        startDate: startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        endDate: endDate ?? DateTime.now(),
      );

      if (metrics.isEmpty) {
        return {
          'user_id': userId,
          'user_name': userName,
          'targets_met': 0,
          'total_targets': targets.length,
          'overall_score': 0.0,
          'evaluation': 'Chưa có dữ liệu',
          'details': [],
        };
      }

      // Calculate average performance metrics
      double avgCompletionRate = 0;
      double avgQualityScore = 0;
      double avgOnTimeRate = 0;
      double avgPhotoSubmission = 0;
      int countCompletion = 0;
      int countQuality = 0;
      int countOnTime = 0;
      int countPhoto = 0;

      for (var metric in metrics) {
        if (metric.completionRate != null) {
          avgCompletionRate += metric.completionRate!;
          countCompletion++;
        }
        if (metric.avgQualityScore != null) {
          avgQualityScore += metric.avgQualityScore!;
          countQuality++;
        }
        if (metric.onTimeRate != null) {
          avgOnTimeRate += metric.onTimeRate!;
          countOnTime++;
        }
        if (metric.photoSubmissionRate != null) {
          avgPhotoSubmission += metric.photoSubmissionRate!;
          countPhoto++;
        }
      }

      avgCompletionRate = countCompletion > 0 ? avgCompletionRate / countCompletion : 0;
      avgQualityScore = countQuality > 0 ? avgQualityScore / countQuality : 0;
      avgOnTimeRate = countOnTime > 0 ? avgOnTimeRate / countOnTime : 0;
      avgPhotoSubmission = countPhoto > 0 ? avgPhotoSubmission / countPhoto : 0;

      // Evaluate each target
      final List<Map<String, dynamic>> targetEvaluations = [];
      int targetsMet = 0;
      double totalScore = 0;

      for (var target in targets) {
        double actualValue = 0;
        String unit = '%';

        switch (target.metricType) {
          case 'completion_rate':
            actualValue = avgCompletionRate;
            break;
          case 'quality_score':
            actualValue = avgQualityScore * 10; // Convert to percentage
            unit = '/10';
            break;
          case 'timeliness':
            actualValue = avgOnTimeRate;
            break;
          case 'photo_submission':
            actualValue = avgPhotoSubmission;
            break;
        }

        final achievement = (actualValue / target.targetValue * 100).clamp(0, 100);
        final isMet = actualValue >= target.targetValue;

        if (isMet) targetsMet++;
        totalScore += achievement;

        targetEvaluations.add({
          'metric_name': target.metricName,
          'metric_type': target.metricType,
          'target_value': target.targetValue,
          'actual_value': actualValue,
          'achievement_percent': achievement,
          'is_met': isMet,
          'unit': unit,
        });
      }

      final overallScore = targets.isNotEmpty ? totalScore / targets.length : 0.0;
      String evaluation;
      if (overallScore >= 90) {
        evaluation = 'Xuất sắc';
      } else if (overallScore >= 80) {
        evaluation = 'Tốt';
      } else if (overallScore >= 70) {
        evaluation = 'Khá';
      } else if (overallScore >= 60) {
        evaluation = 'Trung bình';
      } else {
        evaluation = 'Cần cải thiện';
      }

      return {
        'user_id': userId,
        'user_name': userName,
        'targets_met': targetsMet,
        'total_targets': targets.length,
        'overall_score': overallScore,
        'evaluation': evaluation,
        'avg_completion_rate': avgCompletionRate,
        'avg_quality_score': avgQualityScore,
        'avg_on_time_rate': avgOnTimeRate,
        'details': targetEvaluations,
      };
    } catch (e) {
      throw Exception('Failed to evaluate performance: $e');
    }
  }

  /// Get company-wide KPI performance
  Future<List<Map<String, dynamic>>> getCompanyPerformance({
    required String companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get all employees in company
      final employees = await _supabase
          .from('employees')
          .select('id, full_name, role')
          .eq('company_id', companyId)
          .eq('is_active', true) as List;

      final List<Map<String, dynamic>> results = [];

      for (var employee in employees) {
        try {
          final evaluation = await evaluatePerformance(
            userId: employee['id'] as String,
            startDate: startDate,
            endDate: endDate,
          );
          evaluation['role'] = employee['role'];
          results.add(evaluation);
        } catch (e) {
          print('Failed to evaluate ${employee['id']}: $e');
        }
      }

      // Sort by overall score
      results.sort((a, b) =>
          (b['overall_score'] as double).compareTo(a['overall_score'] as double));

      return results;
    } catch (e) {
      throw Exception('Failed to get company performance: $e');
    }
  }

  /// Update KPI target
  Future<KPITarget> updateTarget({
    required String targetId,
    String? metricName,
    double? targetValue,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (metricName != null) updates['metric_name'] = metricName;
      if (targetValue != null) updates['target_value'] = targetValue;
      if (period != null) updates['period'] = period;
      if (startDate != null) {
        updates['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        updates['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (isActive != null) updates['is_active'] = isActive;

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('kpi_targets')
          .update(updates)
          .eq('id', targetId)
          .select()
          .single();

      return KPITarget.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update KPI target: $e');
    }
  }

  /// Delete KPI target (soft delete by setting is_active = false)
  Future<void> deleteTarget(String targetId) async {
    try {
      await _supabase
          .from('kpi_targets')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', targetId);
    } catch (e) {
      throw Exception('Failed to delete KPI target: $e');
    }
  }

  /// Create default KPI targets for a role
  Future<List<KPITarget>> createDefaultTargetsForRole(String role) async {
    try {
      final List<Map<String, dynamic>> defaultTargets = [];

      // Default targets based on role
      switch (role.toUpperCase()) {
        case 'STAFF':
          defaultTargets.addAll([
            {
              'role': role,
              'metric_name': 'Tỷ lệ hoàn thành nhiệm vụ',
              'metric_type': 'completion_rate',
              'target_value': 90.0,
              'period': 'weekly',
            },
            {
              'role': role,
              'metric_name': 'Đúng giờ',
              'metric_type': 'timeliness',
              'target_value': 95.0,
              'period': 'weekly',
            },
            {
              'role': role,
              'metric_name': 'Gửi hình ảnh báo cáo',
              'metric_type': 'photo_submission',
              'target_value': 100.0,
              'period': 'weekly',
            },
          ]);
          break;

        case 'MANAGER':
          defaultTargets.addAll([
            {
              'role': role,
              'metric_name': 'Tỷ lệ hoàn thành nhiệm vụ quản lý',
              'metric_type': 'completion_rate',
              'target_value': 95.0,
              'period': 'weekly',
            },
            {
              'role': role,
              'metric_name': 'Chất lượng quản lý',
              'metric_type': 'quality_score',
              'target_value': 85.0,
              'period': 'monthly',
            },
          ]);
          break;

        case 'SHIFT_LEADER':
          defaultTargets.addAll([
            {
              'role': role,
              'metric_name': 'Tỷ lệ hoàn thành nhiệm vụ ca',
              'metric_type': 'completion_rate',
              'target_value': 92.0,
              'period': 'weekly',
            },
            {
              'role': role,
              'metric_name': 'Đánh giá chất lượng',
              'metric_type': 'quality_score',
              'target_value': 80.0,
              'period': 'weekly',
            },
          ]);
          break;
      }

      if (defaultTargets.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('kpi_targets')
          .insert(defaultTargets)
          .select();

      return (response as List)
          .map((json) => KPITarget.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to create default targets: $e');
    }
  }
}
