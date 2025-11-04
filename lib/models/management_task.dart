/// Management Task Model
/// For CEO and Manager task management system
/// Separate from operational tasks used by staff
library;

class ManagementTask {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final int progress;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String createdBy;
  final String? assignedTo;
  final String? companyId;
  final String? branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional user details (from join)
  final String? createdByName;
  final String? createdByRole;
  final String? assignedToName;
  final String? assignedToRole;
  final String? companyName;
  final String? branchName;

  const ManagementTask({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.progress,
    this.dueDate,
    this.completedAt,
    required this.createdBy,
    this.assignedTo,
    this.companyId,
    this.branchId,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
    this.createdByRole,
    this.assignedToName,
    this.assignedToRole,
    this.companyName,
    this.branchName,
  });

  factory ManagementTask.fromJson(Map<String, dynamic> json) {
    return ManagementTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.fromString(json['priority'] as String),
      status: TaskStatus.fromString(json['status'] as String),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      companyId: json['company_id'] as String?,
      branchId: json['branch_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdByName: json['created_by_name'] as String?,
      createdByRole: json['created_by_role'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      assignedToRole: json['assigned_to_role'] as String?,
      companyName: json['company_name'] as String?,
      branchName: json['branch_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': status.value,
      'progress': progress,
      'due_date': dueDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'company_id': companyId,
      'branch_id': branchId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ManagementTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    int? progress,
    DateTime? dueDate,
    DateTime? completedAt,
    String? createdBy,
    String? assignedTo,
    String? companyId,
    String? branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ManagementTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Task Priority Enum
enum TaskPriority {
  critical('critical', 'Khẩn cấp'),
  high('high', 'Cao'),
  medium('medium', 'Trung bình'),
  low('low', 'Thấp');

  final String value;
  final String label;

  const TaskPriority(this.value, this.label);

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Task Status Enum
enum TaskStatus {
  pending('pending', 'Chờ xử lý'),
  inProgress('in_progress', 'Đang thực hiện'),
  completed('completed', 'Hoàn thành'),
  overdue('overdue', 'Quá hạn'),
  cancelled('cancelled', 'Đã hủy');

  final String value;
  final String label;

  const TaskStatus(this.value, this.label);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

/// Task Approval Model
class TaskApproval {
  final String id;
  final String title;
  final String? description;
  final ApprovalType type;
  final String? taskId;
  final String submittedBy;
  final String? approvedBy;
  final ApprovalStatus status;
  final String? companyId;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional user details
  final String? submittedByName;
  final String? submittedByRole;
  final String? companyName;

  const TaskApproval({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.taskId,
    required this.submittedBy,
    this.approvedBy,
    required this.status,
    this.companyId,
    required this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.submittedByName,
    this.submittedByRole,
    this.companyName,
  });

  factory TaskApproval.fromJson(Map<String, dynamic> json) {
    return TaskApproval(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: ApprovalType.fromString(json['type'] as String),
      taskId: json['task_id'] as String?,
      submittedBy: json['submitted_by'] as String,
      approvedBy: json['approved_by'] as String?,
      status: ApprovalStatus.fromString(json['status'] as String),
      companyId: json['company_id'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      submittedByName: json['submitted_by_name'] as String?,
      submittedByRole: json['submitted_by_role'] as String?,
      companyName: json['company_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'task_id': taskId,
      'submitted_by': submittedBy,
      'approved_by': approvedBy,
      'status': status.value,
      'company_id': companyId,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Approval Type Enum
enum ApprovalType {
  report('report', 'Báo cáo'),
  budget('budget', 'Ngân sách'),
  proposal('proposal', 'Đề xuất'),
  other('other', 'Khác');

  final String value;
  final String label;

  const ApprovalType(this.value, this.label);

  static ApprovalType fromString(String value) {
    return ApprovalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ApprovalType.other,
    );
  }
}

/// Approval Status Enum
enum ApprovalStatus {
  pending('pending', 'Chờ duyệt'),
  approved('approved', 'Đã duyệt'),
  rejected('rejected', 'Từ chối');

  final String value;
  final String label;

  const ApprovalStatus(this.value, this.label);

  static ApprovalStatus fromString(String value) {
    return ApprovalStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ApprovalStatus.pending,
    );
  }
}
