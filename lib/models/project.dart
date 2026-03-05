import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Project Status
enum ProjectStatus {
  active,
  onHold,
  completed,
  cancelled;

  String get label => switch (this) {
    ProjectStatus.active => 'Đang thực hiện',
    ProjectStatus.onHold => 'Tạm dừng',
    ProjectStatus.completed => 'Hoàn thành',
    ProjectStatus.cancelled => 'Đã hủy',
  };

  Color get color => switch (this) {
    ProjectStatus.active => AppColors.success,
    ProjectStatus.onHold => AppColors.warning,
    ProjectStatus.completed => Color(0xFF6366F1),
    ProjectStatus.cancelled => AppColors.neutral500,
  };

  IconData get icon => switch (this) {
    ProjectStatus.active => Icons.play_circle_outline,
    ProjectStatus.onHold => Icons.pause_circle_outline,
    ProjectStatus.completed => Icons.check_circle_outline,
    ProjectStatus.cancelled => Icons.cancel_outlined,
  };

  static ProjectStatus fromString(String? value) => switch (value) {
    'active' => ProjectStatus.active,
    'on_hold' || 'onHold' => ProjectStatus.onHold,
    'completed' => ProjectStatus.completed,
    'cancelled' => ProjectStatus.cancelled,
    _ => ProjectStatus.active,
  };

  String toDbString() => switch (this) {
    ProjectStatus.active => 'active',
    ProjectStatus.onHold => 'on_hold',
    ProjectStatus.completed => 'completed',
    ProjectStatus.cancelled => 'cancelled',
  };
}

/// Project Priority
enum ProjectPriority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
    ProjectPriority.low => 'Thấp',
    ProjectPriority.medium => 'Trung bình',
    ProjectPriority.high => 'Cao',
    ProjectPriority.urgent => 'Khẩn cấp',
  };

  Color get color => switch (this) {
    ProjectPriority.low => AppColors.neutral500,
    ProjectPriority.medium => AppColors.info,
    ProjectPriority.high => AppColors.warning,
    ProjectPriority.urgent => AppColors.error,
  };

  static ProjectPriority fromString(String? value) => switch (value) {
    'low' => ProjectPriority.low,
    'medium' => ProjectPriority.medium,
    'high' => ProjectPriority.high,
    'urgent' => ProjectPriority.urgent,
    _ => ProjectPriority.medium,
  };
}

/// Project Model
class Project {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final ProjectStatus status;
  final ProjectPriority priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int progress;
  final String? managerId;
  final String? managerName;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  /// Sub-projects (loaded separately)
  final List<SubProject> subProjects;
  
  /// Company name (joined)
  final String? companyName;

  const Project({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.status = ProjectStatus.active,
    this.priority = ProjectPriority.medium,
    this.startDate,
    this.endDate,
    this.progress = 0,
    this.managerId,
    this.managerName,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.subProjects = const [],
    this.companyName,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: ProjectStatus.fromString(json['status'] as String?),
      priority: ProjectPriority.fromString(json['priority'] as String?),
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String) 
          : null,
      progress: (json['progress'] as int?) ?? 0,
      managerId: json['manager_id'] as String?,
      managerName: json['manager']?['full_name'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      companyName: json['companies']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'name': name,
    'description': description,
    'status': status.toDbString(),
    'priority': priority.name,
    'start_date': startDate?.toIso8601String().split('T')[0],
    'end_date': endDate?.toIso8601String().split('T')[0],
    'progress': progress,
    'manager_id': managerId,
    'created_by': createdBy,
  };

  Project copyWith({
    String? name,
    String? description,
    ProjectStatus? status,
    ProjectPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? progress,
    String? managerId,
    List<SubProject>? subProjects,
  }) {
    return Project(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      managerId: managerId ?? this.managerId,
      managerName: managerName,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      subProjects: subProjects ?? this.subProjects,
      companyName: companyName,
    );
  }

  /// Calculate progress from sub-projects
  int get calculatedProgress {
    if (subProjects.isEmpty) return progress;
    final total = subProjects.fold<int>(0, (sum, sp) => sum + sp.progress);
    return (total / subProjects.length).round();
  }

  /// Check if project is overdue
  bool get isOverdue {
    if (endDate == null || status == ProjectStatus.completed) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Days remaining
  int? get daysRemaining {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }
}

/// SubProject Model
class SubProject {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final ProjectStatus status;
  final ProjectPriority priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int progress;
  final String? assignedTo;
  final String? assignedToName;
  final String? createdBy;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubProject({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.status = ProjectStatus.active,
    this.priority = ProjectPriority.medium,
    this.startDate,
    this.endDate,
    this.progress = 0,
    this.assignedTo,
    this.assignedToName,
    this.createdBy,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubProject.fromJson(Map<String, dynamic> json) {
    return SubProject(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: ProjectStatus.fromString(json['status'] as String?),
      priority: ProjectPriority.fromString(json['priority'] as String?),
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String) 
          : null,
      progress: (json['progress'] as int?) ?? 0,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assignee']?['full_name'] as String?,
      createdBy: json['created_by'] as String?,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'name': name,
    'description': description,
    'status': status.toDbString(),
    'priority': priority.name,
    'start_date': startDate?.toIso8601String().split('T')[0],
    'end_date': endDate?.toIso8601String().split('T')[0],
    'progress': progress,
    'assigned_to': assignedTo,
    'created_by': createdBy,
    'sort_order': sortOrder,
  };

  SubProject copyWith({
    String? name,
    String? description,
    ProjectStatus? status,
    ProjectPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? progress,
    String? assignedTo,
    int? sortOrder,
  }) {
    return SubProject(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName,
      createdBy: createdBy,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
