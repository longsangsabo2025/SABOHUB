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

class Task {
  final String id;
  final String branchId;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime dueDate;
  final DateTime? completedAt;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String? notes;

  const Task({
    required this.id,
    required this.branchId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.assignedToName,
    required this.dueDate,
    this.completedAt,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.notes,
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
    String? assignedTo,
    String? assignedToName,
    DateTime? dueDate,
    DateTime? completedAt,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    String? notes,
  }) {
    return Task(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
