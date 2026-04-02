/// Gym Coach Message — Chat message for the Gym AI Agent.
///
/// Extends the concept from TravisMessage but specialized for gym coaching.
class GymCoachMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final GymMessageType? messageType;
  final Map<String, dynamic>? actionData;

  const GymCoachMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.messageType,
    this.actionData,
  });

  factory GymCoachMessage.user(String content) {
    return GymCoachMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory GymCoachMessage.assistant(
    String content, {
    GymMessageType? type,
    Map<String, dynamic>? actionData,
  }) {
    return GymCoachMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
      messageType: type,
      actionData: actionData,
    );
  }

  factory GymCoachMessage.system(String content) {
    return GymCoachMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'system',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
  bool get hasAction => actionData != null;
}

/// Types of assistant messages that may trigger special UI.
enum GymMessageType {
  /// Plain text response
  text,

  /// Contains a workout plan that can be saved
  workoutPlan,

  /// Contains exercise recommendation
  exerciseRecommendation,

  /// Contains nutrition advice
  nutritionAdvice,

  /// Contains progress analysis
  progressAnalysis,

  /// Contains form correction tip
  formCorrection,
}
