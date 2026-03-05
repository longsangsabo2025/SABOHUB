import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum TaskPriority {
  low('Thấp', AppColors.neutral500),
  medium('Trung bình', AppColors.info),
  high('Cao', AppColors.warning),
  urgent('Khẩn cấp', AppColors.error);

  final String label;
  final Color color;
  const TaskPriority(this.label, this.color);
}

enum TaskStatus {
  todo('Cần làm', AppColors.neutral500),
  inProgress('Đang làm', AppColors.info),
  completed('Hoàn thành', AppColors.success),
  cancelled('Đã hủy', AppColors.error);

  final String label;
  final Color color;
  const TaskStatus(this.label, this.color);

  /// Convert to database value
  String toDbValue() {
    switch (this) {
      case TaskStatus.todo:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Parse from database value
  static TaskStatus fromDbValue(String dbValue) {
    switch (dbValue) {
      case 'pending':
        return TaskStatus.todo;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.todo;
    }
  }
}

enum TaskCategory {
  operations('Vận hành', AppColors.info),
  maintenance('Bảo trì', AppColors.warning),
  inventory('Kho hàng', AppColors.primary),
  customerService('Khách hàng', AppColors.success),
  other('Khác', AppColors.neutral500);

  final String label;
  final Color color;
  const TaskCategory(this.label, this.color);
}

enum TaskRecurrence {
  none('Không lặp lại', Icons.event_note, AppColors.neutral500),
  daily('Hằng ngày', Icons.today, AppColors.success),
  weekly('Hằng tuần', Icons.date_range, AppColors.info),
  monthly('Hằng tháng', Icons.calendar_month, AppColors.primary),
  adhoc('Đột xuất', Icons.flash_on, AppColors.warning),
  project('Dự án', Icons.work, AppColors.secondary);

  final String label;
  final IconData icon;
  final Color color;
  const TaskRecurrence(this.label, this.icon, this.color);
}

class Task {
  final String id;
  final String?
      branchId; // Made nullable since branch_id is nullable in database
  final String? companyId; // Add company_id field
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskRecurrence recurrence; // NEW: Task recurrence type
  final String? assignedTo;
  final String? assignedToName;
  final String? assignedToRole; // NEW: Role of assigned user
  final String? assigneeId; // Add this field
  final DateTime? dueDate; // Made nullable to handle NULL from database
  final DateTime? completedAt;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String? notes;
  final String? projectName; // NEW: For project-based tasks
  final DateTime? deletedAt; // Soft delete timestamp

  const Task({
    required this.id,
    this.branchId, // Now optional
    this.companyId, // Add to constructor
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.recurrence = TaskRecurrence.none, // NEW: Default to none
    this.assignedTo,
    this.assignedToName,
    this.assignedToRole, // NEW: Role of assigned user
    this.assigneeId, // Add this field to constructor
    required this.dueDate,
    this.completedAt,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.notes,
    this.projectName, // NEW: For project-based tasks
    this.deletedAt, // Soft delete timestamp
  });

  bool get isOverdue =>
      dueDate != null &&
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled &&
      dueDate!.isBefore(DateTime.now());

  bool get isDueSoon =>
      dueDate != null &&
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled &&
      dueDate!.difference(DateTime.now()).inHours <= 24 &&
      !isOverdue;

  Task copyWith({
    String? id,
    String? branchId,
    String? companyId,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    TaskRecurrence? recurrence,
    String? assignedTo,
    String? assignedToName,
    String? assignedToRole, // NEW
    String? assigneeId,
    DateTime? dueDate,
    DateTime? completedAt,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    String? notes,
    String? projectName,
    DateTime? deletedAt, // NEW
  }) {
    return Task(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToRole: assignedToRole ?? this.assignedToRole, // NEW
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      projectName: projectName ?? this.projectName,
      deletedAt: deletedAt ?? this.deletedAt, // NEW
    );
  }
}
