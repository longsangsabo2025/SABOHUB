/// GymSession — A completed workout session with actual performance data.
class GymSession {
  final String id;
  final String userId;
  final String? workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<ExerciseLog> exerciseLogs;
  final String? notes;
  final int? moodRating; // 1-5
  final int? energyLevel; // 1-5
  final double? bodyWeight; // kg

  const GymSession({
    required this.id,
    required this.userId,
    this.workoutId,
    required this.workoutName,
    required this.startedAt,
    this.endedAt,
    this.exerciseLogs = const [],
    this.notes,
    this.moodRating,
    this.energyLevel,
    this.bodyWeight,
  });

  factory GymSession.fromJson(Map<String, dynamic> json) {
    return GymSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String?,
      workoutName: json['workout_name'] as String? ?? 'Workout',
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      exerciseLogs: (json['exercise_logs'] as List?)
              ?.map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      moodRating: json['mood_rating'] as int?,
      energyLevel: json['energy_level'] as int?,
      bodyWeight: (json['body_weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'workout_id': workoutId,
        'workout_name': workoutName,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'exercise_logs': exerciseLogs.map((e) => e.toJson()).toList(),
        'notes': notes,
        'mood_rating': moodRating,
        'energy_level': energyLevel,
        'body_weight': bodyWeight,
      };

  Duration? get duration =>
      endedAt?.difference(startedAt);

  String get durationText {
    final d = duration;
    if (d == null) return 'Đang tập...';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '$minutes phút';
  }

  int get totalSets => exerciseLogs.fold(0, (sum, e) => sum + e.sets.length);

  double get totalVolume => exerciseLogs.fold(
      0.0,
      (sum, e) =>
          sum +
          e.sets.fold(0.0, (s, set) => s + (set.weight ?? 0) * set.reps));
}

/// Log for a single exercise within a session.
class ExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final List<SetLog> sets;
  final String? notes;

  const ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = const [],
    this.notes,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseId: json['exercise_id'] as String? ?? '',
      exerciseName: json['exercise_name'] as String? ?? '',
      sets: (json['sets'] as List?)
              ?.map((e) => SetLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'sets': sets.map((e) => e.toJson()).toList(),
        'notes': notes,
      };
}

/// Log for a single set within an exercise.
class SetLog {
  final int setNumber;
  final int reps;
  final double? weight; // kg
  final bool isCompleted;
  final SetType type;

  const SetLog({
    required this.setNumber,
    required this.reps,
    this.weight,
    this.isCompleted = true,
    this.type = SetType.working,
  });

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      setNumber: json['set_number'] as int? ?? 1,
      reps: json['reps'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble(),
      isCompleted: json['is_completed'] as bool? ?? true,
      type: SetType.fromString(json['type'] as String? ?? 'working'),
    );
  }

  Map<String, dynamic> toJson() => {
        'set_number': setNumber,
        'reps': reps,
        'weight': weight,
        'is_completed': isCompleted,
        'type': type.name,
      };
}

enum SetType {
  warmup,
  working,
  dropset,
  failure;

  static SetType fromString(String value) {
    return SetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SetType.working,
    );
  }

  String get label {
    switch (this) {
      case warmup:
        return 'Khởi động';
      case working:
        return 'Working';
      case dropset:
        return 'Drop set';
      case failure:
        return 'Tới failure';
    }
  }
}
