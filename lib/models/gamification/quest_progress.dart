import 'quest_definition.dart';

enum QuestStatus {
  locked('locked', 'Khóa'),
  available('available', 'Có thể nhận'),
  inProgress('in_progress', 'Đang thực hiện'),
  completed('completed', 'Hoàn thành'),
  failed('failed', 'Thất bại');

  final String value;
  final String label;
  const QuestStatus(this.value, this.label);

  static QuestStatus fromString(String value) {
    return QuestStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => QuestStatus.locked,
    );
  }

  bool get isActive => this == available || this == inProgress;
  bool get isDone => this == completed;
}

class QuestProgress {
  final String id;
  final String userId;
  final String companyId;
  final String questId;
  final QuestStatus status;
  final int progressCurrent;
  final int progressTarget;
  final Map<String, dynamic> progressData;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Joined quest definition (populated when fetched with join)
  final QuestDefinition? quest;

  QuestProgress({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.questId,
    this.status = QuestStatus.locked,
    this.progressCurrent = 0,
    this.progressTarget = 1,
    this.progressData = const {},
    this.startedAt,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.quest,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get progressPercent =>
      progressTarget > 0 ? (progressCurrent / progressTarget).clamp(0.0, 1.0) : 0.0;

  bool get isComplete => progressCurrent >= progressTarget;

  factory QuestProgress.fromJson(Map<String, dynamic> json) {
    return QuestProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      questId: json['quest_id'] as String,
      status: QuestStatus.fromString(json['status'] as String? ?? 'locked'),
      progressCurrent: json['progress_current'] as int? ?? 0,
      progressTarget: json['progress_target'] as int? ?? 1,
      progressData: json['progress_data'] as Map<String, dynamic>? ?? {},
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      quest: json['quest_definitions'] != null
          ? QuestDefinition.fromJson(json['quest_definitions'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'company_id': companyId,
        'quest_id': questId,
        'status': status.value,
        'progress_current': progressCurrent,
        'progress_target': progressTarget,
        'progress_data': progressData,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  QuestProgress copyWith({
    QuestStatus? status,
    int? progressCurrent,
    int? progressTarget,
    Map<String, dynamic>? progressData,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return QuestProgress(
      id: id,
      userId: userId,
      companyId: companyId,
      questId: questId,
      status: status ?? this.status,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTarget: progressTarget ?? this.progressTarget,
      progressData: progressData ?? this.progressData,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      quest: quest,
    );
  }
}

