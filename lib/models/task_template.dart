import 'package:flutter/material.dart';

/// Recurrence pattern for recurring tasks
enum RecurrencePattern {
  daily('daily', 'Hằng ngày'),
  weekly('weekly', 'Hằng tuần'),
  monthly('monthly', 'Hằng tháng'),
  custom('custom', 'Tùy chỉnh');

  const RecurrencePattern(this.value, this.label);
  final String value;
  final String label;

  static RecurrencePattern fromString(String value) {
    return RecurrencePattern.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecurrencePattern.daily,
    );
  }
}

/// Role assignment for tasks
enum AssignedRole {
  ceo('ceo', 'CEO'),
  manager('manager', 'Quản lý'),
  shiftLeader('shift_leader', 'Trưởng ca'),
  staff('staff', 'Nhân viên'),
  any('any', 'Bất kỳ');

  const AssignedRole(this.value, this.label);
  final String value;
  final String label;

  static AssignedRole fromString(String value) {
    return AssignedRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AssignedRole.any,
    );
  }
}

/// Template for recurring tasks
class TaskTemplate {
  final String id;
  final String companyId;
  final String? branchId;

  // Template Info
  final String title;
  final String description;
  final String category; // TaskCategory enum value
  final String priority; // TaskPriority enum value

  // Recurrence
  final RecurrencePattern recurrencePattern;
  final TimeOfDay? scheduledTime;
  final List<int>? scheduledDays; // For weekly: [1-7], monthly: [1-31]

  // Assignment
  final AssignedRole? assignedRole;
  final String? assignedUserId;

  // Task Details
  final int? estimatedDuration; // minutes
  final List<String>? checklistItems;

  // Status
  final bool isActive;
  final DateTime? lastGeneratedAt;

  // Metadata
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // AI Source
  final String? aiSuggestionId;
  final double? aiConfidence;

  TaskTemplate({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.title,
    this.description = '',
    required this.category,
    required this.priority,
    required this.recurrencePattern,
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
    this.aiSuggestionId,
    this.aiConfidence,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      branchId: json['branch_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String,
      priority: json['priority'] as String,
      recurrencePattern:
          RecurrencePattern.fromString(json['recurrence_pattern'] as String),
      scheduledTime: json['scheduled_time'] != null
          ? _parseTime(json['scheduled_time'] as String)
          : null,
      scheduledDays: json['scheduled_days'] != null
          ? (json['scheduled_days'] as List).cast<int>()
          : null,
      assignedRole: json['assigned_role'] != null
          ? AssignedRole.fromString(json['assigned_role'] as String)
          : null,
      assignedUserId: json['assigned_user_id'] as String?,
      estimatedDuration: json['estimated_duration'] as int?,
      checklistItems: json['checklist_items'] != null
          ? (json['checklist_items'] as List).cast<String>()
          : null,
      isActive: json['is_active'] as bool? ?? true,
      lastGeneratedAt: json['last_generated_at'] != null
          ? DateTime.parse(json['last_generated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      aiSuggestionId: json['ai_suggestion_id'] as String?,
      aiConfidence: json['ai_confidence'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'branch_id': branchId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'recurrence_pattern': recurrencePattern.value,
      'scheduled_time': scheduledTime != null
          ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'scheduled_days': scheduledDays,
      'assigned_role': assignedRole?.value,
      'assigned_user_id': assignedUserId,
      'estimated_duration': estimatedDuration,
      'checklist_items': checklistItems,
      'is_active': isActive,
      'last_generated_at': lastGeneratedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'ai_suggestion_id': aiSuggestionId,
      'ai_confidence': aiConfidence,
    };
  }

  static TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  TaskTemplate copyWith({
    String? id,
    String? companyId,
    String? branchId,
    String? title,
    String? description,
    String? category,
    String? priority,
    RecurrencePattern? recurrencePattern,
    TimeOfDay? scheduledTime,
    List<int>? scheduledDays,
    AssignedRole? assignedRole,
    String? assignedUserId,
    int? estimatedDuration,
    List<String>? checklistItems,
    bool? isActive,
    DateTime? lastGeneratedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? aiSuggestionId,
    double? aiConfidence,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      assignedRole: assignedRole ?? this.assignedRole,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      checklistItems: checklistItems ?? this.checklistItems,
      isActive: isActive ?? this.isActive,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiSuggestionId: aiSuggestionId ?? this.aiSuggestionId,
      aiConfidence: aiConfidence ?? this.aiConfidence,
    );
  }
}
