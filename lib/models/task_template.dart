class TaskTemplate {
  final String id;
  final String? companyId;
  final String? branchId;
  final String title;
  final String? description;
  final String? category;
  final String priority;
  final String? recurrencePattern;
  final String? scheduledTime;
  final List<int>? scheduledDays;
  final String? assignedRole;
  final String? assignedUserId;
  final int? estimatedDuration;
  final List<Map<String, dynamic>>? checklistItems;
  final bool isActive;
  final DateTime? lastGeneratedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskTemplate({
    required this.id,
    this.companyId,
    this.branchId,
    required this.title,
    this.description,
    this.category,
    this.priority = 'medium',
    this.recurrencePattern,
    this.scheduledTime,
    this.scheduledDays,
    this.assignedRole,
    this.assignedUserId,
    this.estimatedDuration,
    this.checklistItems,
    this.isActive = true,
    this.lastGeneratedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      branchId: json['branch_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      recurrencePattern: json['recurrence_pattern'] as String?,
      scheduledTime: json['scheduled_time'] as String?,
      scheduledDays: json['scheduled_days'] != null
          ? List<int>.from(json['scheduled_days'] as List)
          : null,
      assignedRole: json['assigned_role'] as String?,
      assignedUserId: json['assigned_user_id'] as String?,
      estimatedDuration: (json['estimated_duration'] as num?)?.toInt(),
      checklistItems: json['checklist_items'] != null
          ? List<Map<String, dynamic>>.from(
              (json['checklist_items'] as List).map((e) => Map<String, dynamic>.from(e as Map)))
          : null,
      isActive: json['is_active'] as bool? ?? true,
      lastGeneratedAt: json['last_generated_at'] != null
          ? DateTime.parse(json['last_generated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'recurrence_pattern': recurrencePattern,
        'scheduled_time': scheduledTime,
        'scheduled_days': scheduledDays,
        'assigned_role': assignedRole,
        'assigned_user_id': assignedUserId,
        'estimated_duration': estimatedDuration,
        'checklist_items': checklistItems,
        'is_active': isActive,
        if (companyId != null) 'company_id': companyId,
        if (branchId != null) 'branch_id': branchId,
        if (createdBy != null) 'created_by': createdBy,
      };

  String get recurrenceLabel {
    switch (recurrencePattern) {
      case 'daily':
        return 'Hằng ngày';
      case 'weekly':
        return 'Hằng tuần';
      case 'monthly':
        return 'Hằng tháng';
      default:
        return 'Một lần';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'critical':
        return 'Khẩn cấp';
      case 'high':
        return 'Cao';
      case 'low':
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }

  int get checklistCount => checklistItems?.length ?? 0;
}
