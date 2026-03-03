/// Media Project model — CEO-level project management
/// Groups content, channels, and campaigns under a single project

class MediaProject {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String status; // planning, active, paused, completed, cancelled
  final String priority; // low, medium, high, urgent
  final List<String> platforms;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budget;
  final double spent;
  final String? managerId;
  final List<String> tags;
  final String color;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed
  int contentCount;
  int completedCount;

  MediaProject({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.status = 'active',
    this.priority = 'medium',
    this.platforms = const [],
    this.startDate,
    this.endDate,
    this.budget = 0,
    this.spent = 0,
    this.managerId,
    this.tags = const [],
    this.color = '#7C3AED',
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.contentCount = 0,
    this.completedCount = 0,
  });

  factory MediaProject.fromJson(Map<String, dynamic> json) {
    return MediaProject(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'active',
      priority: json['priority'] ?? 'medium',
      platforms: json['platforms'] != null
          ? List<String>.from(json['platforms'])
          : [],
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      budget: (json['budget'] ?? 0).toDouble(),
      spent: (json['spent'] ?? 0).toDouble(),
      managerId: json['manager_id'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      color: json['color'] ?? '#7C3AED',
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'name': name,
        'description': description,
        'status': status,
        'priority': priority,
        'platforms': platforms,
        'start_date': startDate?.toIso8601String().substring(0, 10),
        'end_date': endDate?.toIso8601String().substring(0, 10),
        'budget': budget,
        'spent': spent,
        'manager_id': managerId,
        'tags': tags,
        'color': color,
        'notes': notes,
      };

  /// Status display label (Vietnamese)
  String get statusLabel {
    switch (status) {
      case 'planning':
        return 'Lên kế hoạch';
      case 'active':
        return 'Đang chạy';
      case 'paused':
        return 'Tạm dừng';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  /// Priority display label
  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      case 'urgent':
        return 'Khẩn cấp';
      default:
        return priority;
    }
  }

  /// Platform icons list
  List<String> get platformIcons {
    const icons = {
      'youtube': '🔴',
      'tiktok': '🎵',
      'facebook': '🔵',
      'instagram': '📸',
      'twitter': '🐦',
      'linkedin': '💼',
    };
    return platforms.map((p) => icons[p] ?? '📱').toList();
  }

  /// Progress (0.0 - 1.0)
  double get progress {
    if (contentCount == 0) return 0;
    return completedCount / contentCount;
  }

  /// Budget usage (0.0 - 1.0)
  double get budgetUsage {
    if (budget <= 0) return 0;
    return (spent / budget).clamp(0.0, 2.0);
  }

  /// Is overdue
  bool get isOverdue {
    if (endDate == null) return false;
    if (status == 'completed' || status == 'cancelled') return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Days remaining
  int? get daysRemaining {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }

  MediaProject copyWith({
    String? name,
    String? description,
    String? status,
    String? priority,
    List<String>? platforms,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    double? spent,
    String? managerId,
    List<String>? tags,
    String? color,
    String? notes,
  }) {
    return MediaProject(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      platforms: platforms ?? this.platforms,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      managerId: managerId ?? this.managerId,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      contentCount: contentCount,
      completedCount: completedCount,
    );
  }
}
