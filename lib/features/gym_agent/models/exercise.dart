/// Exercise Model — Based on wger exercise database structure.
///
/// Represents a gym exercise with muscle groups, equipment, and instructions.
class Exercise {
  final String id;
  final int? wgerId; // wger API exercise ID for detail fetch
  final String name;
  final String? nameVi;
  final String category;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final String? description;
  final String? imageUrl;
  final ExerciseDifficulty difficulty;
  final List<int> primaryMuscleIds; // wger muscle IDs for SVG lookup
  final List<int> secondaryMuscleIds;

  const Exercise({
    required this.id,
    this.wgerId,
    required this.name,
    this.nameVi,
    required this.category,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipment = const [],
    this.description,
    this.imageUrl,
    this.difficulty = ExerciseDifficulty.intermediate,
    this.primaryMuscleIds = const [],
    this.secondaryMuscleIds = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      wgerId: json['wger_id'] as int?,
      name: json['name'] as String,
      nameVi: json['name_vi'] as String?,
      category: json['category'] as String? ?? 'Other',
      primaryMuscles: _toStringList(json['primary_muscles']),
      secondaryMuscles: _toStringList(json['secondary_muscles']),
      equipment: _toStringList(json['equipment']),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      difficulty: ExerciseDifficulty.fromString(
        json['difficulty'] as String? ?? 'intermediate',
      ),
      primaryMuscleIds: _toIntList(json['primary_muscle_ids']),
      secondaryMuscleIds: _toIntList(json['secondary_muscle_ids']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wger_id': wgerId,
        'name': name,
        'name_vi': nameVi,
        'category': category,
        'primary_muscles': primaryMuscles,
        'secondary_muscles': secondaryMuscles,
        'equipment': equipment,
        'description': description,
        'image_url': imageUrl,
        'difficulty': difficulty.name,
        'primary_muscle_ids': primaryMuscleIds,
        'secondary_muscle_ids': secondaryMuscleIds,
      };

  String get displayName => nameVi ?? name;
  bool get isFromWger => wgerId != null;

  /// YouTube search query for this exercise
  String get youtubeSearchQuery => '$name exercise form tutorial';

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static List<int> _toIntList(dynamic value) {
    if (value is List) return value.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
    return const [];
  }
}

enum ExerciseDifficulty {
  beginner,
  intermediate,
  advanced;

  static ExerciseDifficulty fromString(String value) {
    return ExerciseDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseDifficulty.intermediate,
    );
  }

  String get label {
    switch (this) {
      case beginner:
        return 'Người mới';
      case intermediate:
        return 'Trung bình';
      case advanced:
        return 'Nâng cao';
    }
  }

  String get emoji {
    switch (this) {
      case beginner:
        return '🟢';
      case intermediate:
        return '🟡';
      case advanced:
        return '🔴';
    }
  }
}

/// Exercise category enum matching wger categories
class ExerciseCategory {
  ExerciseCategory._();

  static const chest = 'Ngực';
  static const back = 'Lưng';
  static const shoulders = 'Vai';
  static const biceps = 'Tay trước';
  static const triceps = 'Tay sau';
  static const legs = 'Chân';
  static const abs = 'Bụng';
  static const cardio = 'Cardio';
  static const compound = 'Compound';

  static const all = [
    chest,
    back,
    shoulders,
    biceps,
    triceps,
    legs,
    abs,
    cardio,
    compound,
  ];
}
