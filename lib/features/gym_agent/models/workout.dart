import 'exercise.dart';

/// Workout Plan — A complete training session with exercises.
class Workout {
  final String id;
  final String name;
  final String? description;
  final WorkoutType type;
  final List<WorkoutExercise> exercises;
  final int estimatedMinutes;
  final ExerciseDifficulty difficulty;
  final DateTime createdAt;
  final bool isAiGenerated;

  const Workout({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.exercises = const [],
    this.estimatedMinutes = 60,
    this.difficulty = ExerciseDifficulty.intermediate,
    required this.createdAt,
    this.isAiGenerated = false,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: WorkoutType.fromString(json['type'] as String? ?? 'custom'),
      exercises: (json['exercises'] as List?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      estimatedMinutes: json['estimated_minutes'] as int? ?? 60,
      difficulty: ExerciseDifficulty.fromString(
        json['difficulty'] as String? ?? 'intermediate',
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'estimated_minutes': estimatedMinutes,
        'difficulty': difficulty.name,
        'created_at': createdAt.toIso8601String(),
        'is_ai_generated': isAiGenerated,
      };

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);
}

/// A single exercise entry within a workout plan.
class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final double? weight; // kg
  final int? restSeconds;
  final String? notes;
  final int order;

  const WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = 3,
    this.reps = 10,
    this.weight,
    this.restSeconds = 90,
    this.notes,
    this.order = 0,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exercise_id'] as String? ?? '',
      exerciseName: json['exercise_name'] as String? ?? '',
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as int? ?? 10,
      weight: (json['weight'] as num?)?.toDouble(),
      restSeconds: json['rest_seconds'] as int?,
      notes: json['notes'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'rest_seconds': restSeconds,
        'notes': notes,
        'order': order,
      };
}

enum WorkoutType {
  push,
  pull,
  legs,
  upper,
  lower,
  fullBody,
  cardio,
  custom;

  static WorkoutType fromString(String value) {
    return WorkoutType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkoutType.custom,
    );
  }

  String get label {
    switch (this) {
      case push:
        return 'Push (Đẩy)';
      case pull:
        return 'Pull (Kéo)';
      case legs:
        return 'Legs (Chân)';
      case upper:
        return 'Upper Body';
      case lower:
        return 'Lower Body';
      case fullBody:
        return 'Full Body';
      case cardio:
        return 'Cardio';
      case custom:
        return 'Tự tạo';
    }
  }

  String get emoji {
    switch (this) {
      case push:
        return '💪';
      case pull:
        return '🏋️';
      case legs:
        return '🦵';
      case upper:
        return '👆';
      case lower:
        return '👇';
      case fullBody:
        return '🏃';
      case cardio:
        return '❤️';
      case custom:
        return '⚡';
    }
  }
}
