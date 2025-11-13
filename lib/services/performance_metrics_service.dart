import '../core/services/supabase_service.dart';
import '../models/performance_metrics.dart';

/// Performance Metrics Service
/// Automatically calculates and stores daily performance metrics
class PerformanceMetricsService {
  final _supabase = supabase.client;

  /// Calculate and store performance metrics for a specific date
  /// Called automatically at end of day or manually by managers
  Future<PerformanceMetrics> calculateDailyMetrics({
    required String userId,
    required DateTime date,
  }) async {
    try {
      // Get user info
      final userResponse = await _supabase
          .from('employees')
          .select('full_name, company_id')
          .eq('id', userId)
          .maybeSingle();

      final userName = userResponse?['full_name'] as String? ?? 'Unknown';
      final companyId = userResponse?['company_id'] as String?;

      // Calculate date range (start and end of day)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get tasks data for the day
      final tasksQuery = _supabase
          .from('tasks')
          .select('id, status, due_date, completed_at, created_at')
          .eq('assigned_to', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      if (companyId != null) {
        tasksQuery.eq('company_id', companyId);
      }

      final tasksData = await tasksQuery as List;

      // Calculate task metrics
      final tasksAssigned = tasksData.length;
      final tasksCompleted =
          tasksData.where((t) => t['status'] == 'completed').length;
      final tasksOverdue = tasksData
          .where((t) =>
              t['status'] != 'completed' &&
              t['due_date'] != null &&
              DateTime.parse(t['due_date'] as String).isBefore(DateTime.now()))
          .length;
      final tasksCancelled =
          tasksData.where((t) => t['status'] == 'cancelled').length;

      // Calculate completion rate
      final completionRate =
          tasksAssigned > 0 ? (tasksCompleted / tasksAssigned * 100) : 0.0;

      // Calculate on-time rate (tasks completed before due date)
      final completedTasks =
          tasksData.where((t) => t['status'] == 'completed').toList();
      int onTimeTasks = 0;
      for (var task in completedTasks) {
        if (task['due_date'] != null && task['completed_at'] != null) {
          final dueDate = DateTime.parse(task['due_date'] as String);
          final completedAt = DateTime.parse(task['completed_at'] as String);
          if (completedAt.isBefore(dueDate) ||
              completedAt.isAtSameMomentAs(dueDate)) {
            onTimeTasks++;
          }
        }
      }
      final onTimeRate = completedTasks.isNotEmpty
          ? (onTimeTasks / completedTasks.length * 100)
          : 0.0;

      // Get attendance data for work duration
      final attendanceQuery = _supabase
          .from('attendance')
          .select('check_in_time, check_out_time')
          .eq('employee_id', userId)
          .gte('check_in_time', startOfDay.toIso8601String())
          .lt('check_in_time', endOfDay.toIso8601String());

      if (companyId != null) {
        attendanceQuery.eq('company_id', companyId);
      }

      final attendanceData = await attendanceQuery as List;

      // Calculate total work duration in minutes
      int totalWorkDuration = 0;
      for (var record in attendanceData) {
        if (record['check_in_time'] != null &&
            record['check_out_time'] != null) {
          final checkIn = DateTime.parse(record['check_in_time'] as String);
          final checkOut = DateTime.parse(record['check_out_time'] as String);
          totalWorkDuration += checkOut.difference(checkIn).inMinutes;
        }
      }

      // Get checklist completion data (from task_checklists or similar)
      // For now, using a simple calculation based on completed tasks
      final checklistsCompleted = tasksCompleted;

      // Get incidents reported
      final incidentsData = await _supabase
          .from('incident_reports')
          .select('id')
          .eq('reported_by', userId)
          .gte('reported_at', startOfDay.toIso8601String())
          .lt('reported_at', endOfDay.toIso8601String()) as List;

      final incidentsReported = incidentsData.length;

      // Calculate photo submission rate (mock for now - would check task photos)
      final photoSubmissionRate = completionRate; // Simplified

      // Calculate average quality score (mock for now - would use actual ratings)
      final avgQualityScore = completionRate > 90
          ? 9.5
          : completionRate > 80
              ? 8.5
              : completionRate > 70
                  ? 7.5
                  : completionRate > 60
                      ? 6.5
                      : 5.0;

      // Insert or update in database
      final response = await _supabase.from('performance_metrics').upsert({
        'user_id': userId,
        'user_name': userName,
        'metric_date': startOfDay.toIso8601String().split('T')[0],
        'tasks_assigned': tasksAssigned,
        'tasks_completed': tasksCompleted,
        'tasks_overdue': tasksOverdue,
        'tasks_cancelled': tasksCancelled,
        'completion_rate': completionRate,
        'avg_quality_score': avgQualityScore,
        'on_time_rate': onTimeRate,
        'photo_submission_rate': photoSubmissionRate,
        'total_work_duration': totalWorkDuration,
        'checklists_completed': checklistsCompleted,
        'incidents_reported': incidentsReported,
      }).select().single();

      return PerformanceMetrics.fromJson(response);
    } catch (e) {
      throw Exception('Failed to calculate metrics: $e');
    }
  }

  /// Get performance metrics for a user within a date range
  Future<List<PerformanceMetrics>> getMetrics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('performance_metrics')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte(
            'metric_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query =
            query.lte('metric_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('metric_date', ascending: false);
      return (response as List)
          .map((json) => PerformanceMetrics.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get metrics: $e');
    }
  }

  /// Get metrics for all employees in a company
  Future<List<PerformanceMetrics>> getCompanyMetrics({
    required String companyId,
    DateTime? date,
  }) async {
    try {
      // Get all employees in company
      final employees = await _supabase
          .from('employees')
          .select('id')
          .eq('company_id', companyId) as List;

      final employeeIds = employees.map((e) => e['id'] as String).toList();

      if (employeeIds.isEmpty) {
        return [];
      }

      var query =
          _supabase.from('performance_metrics').select().inFilter('user_id', employeeIds);

      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        query = query.eq('metric_date', dateStr);
      }

      final response = await query.order('metric_date', ascending: false);
      return (response as List)
          .map((json) => PerformanceMetrics.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get company metrics: $e');
    }
  }

  /// Calculate metrics for all employees in a company for a specific date
  Future<List<PerformanceMetrics>> calculateCompanyDailyMetrics({
    required String companyId,
    required DateTime date,
  }) async {
    try {
      // Get all employees in company
      final employees = await _supabase
          .from('employees')
          .select('id')
          .eq('company_id', companyId)
          .eq('is_active', true) as List;

      final List<PerformanceMetrics> results = [];

      for (var employee in employees) {
        try {
          final metrics = await calculateDailyMetrics(
            userId: employee['id'] as String,
            date: date,
          );
          results.add(metrics);
        } catch (e) {
          // Continue with other employees if one fails
          print('Failed to calculate metrics for ${employee['id']}: $e');
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to calculate company metrics: $e');
    }
  }

  /// Get performance summary for a user (last 7 days, 30 days, etc.)
  Future<Map<String, dynamic>> getPerformanceSummary({
    required String userId,
    int days = 7,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final metrics = await getMetrics(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (metrics.isEmpty) {
        return {
          'avg_completion_rate': 0.0,
          'avg_quality_score': 0.0,
          'avg_on_time_rate': 0.0,
          'total_tasks_completed': 0,
          'total_work_hours': 0.0,
          'performance_trend': 'stable',
          'days_analyzed': 0,
        };
      }

      // Calculate averages
      double totalCompletionRate = 0;
      double totalQualityScore = 0;
      double totalOnTimeRate = 0;
      int totalTasksCompleted = 0;
      int totalWorkMinutes = 0;
      int countCompletionRate = 0;
      int countQualityScore = 0;
      int countOnTimeRate = 0;

      for (var metric in metrics) {
        if (metric.completionRate != null) {
          totalCompletionRate += metric.completionRate!;
          countCompletionRate++;
        }
        if (metric.avgQualityScore != null) {
          totalQualityScore += metric.avgQualityScore!;
          countQualityScore++;
        }
        if (metric.onTimeRate != null) {
          totalOnTimeRate += metric.onTimeRate!;
          countOnTimeRate++;
        }
        totalTasksCompleted += metric.tasksCompleted;
        totalWorkMinutes += metric.totalWorkDuration;
      }

      // Determine trend (comparing first half vs second half)
      String trend = 'stable';
      if (metrics.length >= 4) {
        final firstHalf = metrics.sublist(metrics.length ~/ 2);
        final secondHalf = metrics.sublist(0, metrics.length ~/ 2);

        final firstAvg = firstHalf
                .map((m) => m.completionRate ?? 0)
                .reduce((a, b) => a + b) /
            firstHalf.length;
        final secondAvg = secondHalf
                .map((m) => m.completionRate ?? 0)
                .reduce((a, b) => a + b) /
            secondHalf.length;

        if (secondAvg > firstAvg + 5) {
          trend = 'improving';
        } else if (secondAvg < firstAvg - 5) {
          trend = 'declining';
        }
      }

      return {
        'avg_completion_rate': countCompletionRate > 0
            ? totalCompletionRate / countCompletionRate
            : 0.0,
        'avg_quality_score':
            countQualityScore > 0 ? totalQualityScore / countQualityScore : 0.0,
        'avg_on_time_rate':
            countOnTimeRate > 0 ? totalOnTimeRate / countOnTimeRate : 0.0,
        'total_tasks_completed': totalTasksCompleted,
        'total_work_hours': totalWorkMinutes / 60.0,
        'performance_trend': trend,
        'days_analyzed': metrics.length,
      };
    } catch (e) {
      throw Exception('Failed to get performance summary: $e');
    }
  }

  /// Delete metrics for a specific date (for recalculation)
  Future<void> deleteMetrics({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      await _supabase
          .from('performance_metrics')
          .delete()
          .eq('user_id', userId)
          .eq('metric_date', dateStr);
    } catch (e) {
      throw Exception('Failed to delete metrics: $e');
    }
  }
}
