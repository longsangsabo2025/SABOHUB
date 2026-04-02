import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../utils/app_logger.dart';
import '../models/gym_coach_message.dart';
import '../services/gym_coach_service.dart';
import '../services/gym_repository.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final gymCoachServiceProvider = Provider<GymCoachService>((ref) {
  return GymCoachService();
});

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepository.instance;
});

final gymCoachViewModelProvider =
    AsyncNotifierProvider<GymCoachViewModel, GymCoachState>(
  GymCoachViewModel.new,
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class GymCoachState {
  final List<GymCoachMessage> messages;
  final bool isSending;
  final String? errorMessage;
  final GymUserProfile? userProfile;

  const GymCoachState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
    this.userProfile,
  });

  GymCoachState copyWith({
    List<GymCoachMessage>? messages,
    bool? isSending,
    String? errorMessage,
    GymUserProfile? userProfile,
  }) {
    return GymCoachState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

/// User's gym profile for context-aware coaching.
class GymUserProfile {
  final String level; // beginner, intermediate, advanced
  final String goal; // muscle_gain, fat_loss, strength, health
  final double? weight; // kg
  final double? height; // cm
  final int? age;
  final int trainingDaysPerWeek;
  final List<String> injuries; // known injuries to avoid

  const GymUserProfile({
    this.level = 'intermediate',
    this.goal = 'muscle_gain',
    this.weight,
    this.height,
    this.age,
    this.trainingDaysPerWeek = 4,
    this.injuries = const [],
  });

  String toContextString() {
    final parts = <String>[];
    parts.add('Level: $level');
    parts.add('Mục tiêu: $goal');
    if (weight != null) parts.add('Cân nặng: ${weight}kg');
    if (height != null) parts.add('Chiều cao: ${height}cm');
    if (age != null) parts.add('Tuổi: $age');
    parts.add('Tập $trainingDaysPerWeek ngày/tuần');
    if (injuries.isNotEmpty) {
      parts.add('Chấn thương: ${injuries.join(", ")}');
    }
    return parts.join('\n');
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VIEWMODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class GymCoachViewModel extends AsyncNotifier<GymCoachState> {
  @override
  Future<GymCoachState> build() async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(gymRepositoryProvider);
    final userName = user?.name ?? 'Boss';

    // Load profile from Supabase if authenticated
    GymUserProfile? savedProfile;
    List<GymCoachMessage> previousMessages = [];
    try {
      savedProfile = await repo.getProfile();

      // Load recent chat history
      final chatHistory = await repo.getChatHistory(limit: 30);
      if (chatHistory.isNotEmpty) {
        previousMessages = chatHistory.reversed.map((row) {
          final role = row['role'] as String;
          final content = row['content'] as String;
          final typeStr = row['message_type'] as String? ?? 'text';
          final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now();
          return GymCoachMessage(
            id: row['id'] as String? ?? createdAt.millisecondsSinceEpoch.toString(),
            role: role,
            content: content,
            timestamp: createdAt,
            messageType: GymMessageType.values.firstWhere(
              (t) => t.name == typeStr,
              orElse: () => GymMessageType.text,
            ),
          );
        }).toList();
      }
    } catch (e) {
      AppLogger.warn('GymCoach: Could not load from Supabase: $e');
    }

    final welcome = GymCoachMessage.system(
      '🏋️ **Gym Coach AI** sẵn sàng, $userName!\n\n'
      'Tôi là huấn luyện viên cá nhân AI của bạn. '
      'Hỏi bất cứ điều gì về tập luyện, dinh dưỡng, hay recovery.\n\n'
      '${savedProfile != null ? '📋 *Profile đã load: ${savedProfile.level} — ${savedProfile.goal}*' : '💡 *Tip: Cho tôi biết level và mục tiêu để tôi tư vấn chính xác hơn!*'}',
    );

    return GymCoachState(
      messages: previousMessages.isNotEmpty ? [...previousMessages, welcome] : [welcome],
      userProfile: savedProfile,
    );
  }

  /// Send a message to Gym Coach AI.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final current = state.value;
    if (current == null) return;

    // Add user message immediately
    final userMsg = GymCoachMessage.user(text.trim());
    state = AsyncData(current.copyWith(
      messages: [...current.messages, userMsg],
      isSending: true,
      errorMessage: null,
    ));

    final service = ref.read(gymCoachServiceProvider);
    final repo = ref.read(gymRepositoryProvider);
    final user = ref.read(currentUserProvider);

    // Build rich context: user profile + name
    String? fullContext;
    final parts = <String>[];
    if (user != null) parts.add('Tên user: ${user.name}');
    if (current.userProfile != null) {
      parts.add(current.userProfile!.toContextString());
    }
    if (parts.isNotEmpty) fullContext = parts.join('\n');

    // Persist user message to Supabase
    try {
      await repo.saveChatMessage(role: 'user', content: text.trim());
    } catch (_) {}

    try {
      final response = await service.chat(
        message: text.trim(),
        userContext: fullContext,
      );

      final updated = state.value;
      if (updated == null) return;

      state = AsyncData(updated.copyWith(
        messages: [...updated.messages, response],
        isSending: false,
      ));

      // Persist assistant response
      try {
        await repo.saveChatMessage(
          role: 'assistant',
          content: response.content,
          messageType: response.messageType?.name ?? 'text',
        );
      } catch (_) {}
    } catch (e) {
      final updated = state.value;
      if (updated == null) return;

      final errorMsg = GymCoachMessage.system(
        '❌ $e',
      );
      state = AsyncData(updated.copyWith(
        messages: [...updated.messages, errorMsg],
        isSending: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Send a quick action.
  Future<void> sendQuickAction(String action) => sendMessage(action);

  /// Update user profile for contextual coaching.
  void updateProfile(GymUserProfile profile) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(userProfile: profile));

    // Persist profile to Supabase
    final repo = ref.read(gymRepositoryProvider);
    repo.upsertProfile(profile).catchError((e) {
      AppLogger.warn('GymCoach: Could not save profile: $e');
    });

    // Inform coach about profile
    sendMessage(
      'Cập nhật profile: ${profile.toContextString()}. '
      'Hãy ghi nhớ thông tin này cho các lần tư vấn tiếp theo.',
    );
  }

  /// Clear chat and start new session.
  void clearChat() {
    final service = ref.read(gymCoachServiceProvider);
    service.clearHistory();

    final user = ref.read(currentUserProvider);
    final userName = user?.name ?? 'Boss';

    final welcome = GymCoachMessage.system(
      '🔄 Phiên mới! Gym Coach AI sẵn sàng hỗ trợ bạn, $userName.',
    );

    final current = state.value;
    state = AsyncData(GymCoachState(
      messages: [welcome],
      userProfile: current?.userProfile,
    ));
  }
}
