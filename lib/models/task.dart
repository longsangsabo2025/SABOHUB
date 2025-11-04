import 'package:flutter/material.dart';

enum TaskPriority {
  low('Thấp', Color(0xFF6B7280)),
  medium('Trung bình', Color(0xFF3B82F6)),
  high('Cao', Color(0xFFF59E0B)),
  urgent('Khẩn cấp', Color(0xFFEF4444));

  final String label;
  final Color color;
  const TaskPriority(this.label, this.color);
}

enum TaskStatus {
  todo('Cần làm', Color(0xFF6B7280)),
  inProgress('Đang làm', Color(0xFF3B82F6)),
  completed('Hoàn thành', Color(0xFF10B981)),
  cancelled('Đã hủy', Color(0xFFEF4444));

  final String label;
  final Color color;
  const TaskStatus(this.label, this.color);
}

enum TaskCategory {
  operations('Vận hành', Color(0xFF3B82F6)),
  maintenance('Bảo trì', Color(0xFFF59E0B)),
  inventory('Kho hàng', Color(0xFF8B5CF6)),
  customerService('Khách hàng', Color(0xFF10B981)),
  other('Khác', Color(0xFF6B7280));

  final String label;
  final Color color;
  const TaskCategory(this.label, this.color);
}

enum TaskRecurrence {
  none('Không lặp lại', Icons.event_note, Color(0xFF6B7280)),
  daily('Hằng ngày', Icons.today, Color(0xFF10B981)),
  weekly('Hằng tuần', Icons.date_range, Color(0xFF3B82F6)),
  monthly('Hằng tháng', Icons.calendar_month, Color(0xFF8B5CF6)),
  adhoc('Đột xuất', Icons.flash_on, Color(0xFFF59E0B)),
  project('Dự án', Icons.work, Color(0xFF06B6D4));

  final String label;
  final IconData icon;
  final Color color;
  const TaskRecurrence(this.label, this.icon, this.color);
}

class Task {
  final String id;
  final String branchId;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskRecurrence recurrence; // NEW: Task recurrence type
  final String? assignedTo;
  final String? assignedToName;
  final String? assigneeId; // Add this field
  final DateTime dueDate;
  final DateTime? completedAt;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String? notes;
  final String? projectName; // NEW: For project-based tasks

  const Task({
    required this.id,
    required this.branchId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.recurrence = TaskRecurrence.none, // NEW: Default to none
    this.assignedTo,
    this.assignedToName,
    this.assigneeId, // Add this field to constructor
    required this.dueDate,
    this.completedAt,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.notes,
    this.projectName, // NEW: For project-based tasks
  });

  bool get isOverdue =>
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled &&
      dueDate.isBefore(DateTime.now());

  bool get isDueSoon =>
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled &&
      dueDate.difference(DateTime.now()).inHours <= 24 &&
      !isOverdue;

  Task copyWith({
    String? id,
    String? branchId,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    TaskRecurrence? recurrence,
    String? assignedTo,
    String? assignedToName,
    String? assigneeId,
    DateTime? dueDate,
    DateTime? completedAt,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    String? notes,
    String? projectName,
  }) {
    return Task(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      projectName: projectName ?? this.projectName,
    );
  }
}
