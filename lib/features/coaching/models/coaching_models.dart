/// Coaching Message — Chat message for the Self-Improvement Coaching AI.
class CoachingMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;

  const CoachingMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory CoachingMessage.user(String content) {
    return CoachingMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory CoachingMessage.assistant(String content) {
    return CoachingMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory CoachingMessage.system(String content) {
    return CoachingMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'system',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
}

/// A coaching program category.
class CoachingProgram {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final String color;
  final int defaultDays;
  final bool isCustom;

  const CoachingProgram({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.defaultDays,
    this.isCustom = false,
  });

  factory CoachingProgram.fromJson(Map<String, dynamic> json) {
    return CoachingProgram(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      color: json['color'] as String,
      defaultDays: json['defaultDays'] as int? ?? 30,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  /// Parse hex color string to Color int value.
  int get colorValue {
    final hex = color.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }
}
