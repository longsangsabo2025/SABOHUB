/// Performance Metrics Model
/// Stores daily performance data for employees
class PerformanceMetrics {
  final String id;
  final String userId;
  final String? userName;
  final DateTime metricDate;
  final int tasksAssigned;
  final int tasksCompleted;
  final int tasksOverdue;
  final int tasksCancelled;
  final double? completionRate;
  final double? avgQualityScore;
  final double? onTimeRate;
  final double? photoSubmissionRate;
  final int totalWorkDuration; // minutes
  final int checklistsCompleted;
  final int incidentsReported;
  final DateTime createdAt;

  PerformanceMetrics({
    required this.id,
    required this.userId,
    this.userName,
    required this.metricDate,
    this.tasksAssigned = 0,
    this.tasksCompleted = 0,
    this.tasksOverdue = 0,
    this.tasksCancelled = 0,
    this.completionRate,
    this.avgQualityScore,
    this.onTimeRate,
    this.photoSubmissionRate,
    this.totalWorkDuration = 0,
    this.checklistsCompleted = 0,
    this.incidentsReported = 0,
    required this.createdAt,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      metricDate: DateTime.parse(json['metric_date'] as String),
      tasksAssigned: json['tasks_assigned'] as int? ?? 0,
      tasksCompleted: json['tasks_completed'] as int? ?? 0,
      tasksOverdue: json['tasks_overdue'] as int? ?? 0,
      tasksCancelled: json['tasks_cancelled'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble(),
      avgQualityScore: (json['avg_quality_score'] as num?)?.toDouble(),
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble(),
      photoSubmissionRate: (json['photo_submission_rate'] as num?)?.toDouble(),
      totalWorkDuration: json['total_work_duration'] as int? ?? 0,
      checklistsCompleted: json['checklists_completed'] as int? ?? 0,
      incidentsReported: json['incidents_reported'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'metric_date': metricDate.toIso8601String().split('T')[0],
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Calculate overall performance score (0-100)
  double get overallScore {
    double score = 0.0;
    int components = 0;

    if (completionRate != null) {
      score += completionRate!;
      components++;
    }
    if (avgQualityScore != null) {
      score += avgQualityScore! * 10; // Convert 0-10 to 0-100
      components++;
    }
    if (onTimeRate != null) {
      score += onTimeRate!;
      components++;
    }
    if (photoSubmissionRate != null) {
      score += photoSubmissionRate!;
      components++;
    }

    return components > 0 ? score / components : 0.0;
  }

  /// Get performance rating text
  String get performanceRating {
    final score = overallScore;
    if (score >= 90) return 'Xuất sắc';
    if (score >= 80) return 'Tốt';
    if (score >= 70) return 'Khá';
    if (score >= 60) return 'Trung bình';
    return 'Cần cải thiện';
  }

  /// Get performance rating color
  String get ratingColor {
    final score = overallScore;
    if (score >= 90) return 'green';
    if (score >= 80) return 'blue';
    if (score >= 70) return 'orange';
    if (score >= 60) return 'amber';
    return 'red';
  }
}
