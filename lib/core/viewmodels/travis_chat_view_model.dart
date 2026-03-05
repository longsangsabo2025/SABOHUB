import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/travis_message.dart';
import '../../services/travis_service.dart';
import '../common/result.dart';
import '../viewmodels/base_view_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Immutable state for Travis AI Chat.
class TravisChatState {
  final List<TravisMessage> messages;
  final bool isSending;
  final bool isOnline;
  final String sessionId;
  final TravisHealth? health;
  final String? errorMessage;

  const TravisChatState({
    this.messages = const [],
    this.isSending = false,
    this.isOnline = false,
    required this.sessionId,
    this.health,
    this.errorMessage,
  });

  TravisChatState copyWith({
    List<TravisMessage>? messages,
    bool? isSending,
    bool? isOnline,
    String? sessionId,
    TravisHealth? health,
    String? errorMessage,
  }) {
    return TravisChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isOnline: isOnline ?? this.isOnline,
      sessionId: sessionId ?? this.sessionId,
      health: health ?? this.health,
      errorMessage: errorMessage,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VIEWMODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// ViewModel for Travis AI Chat.
///
/// Manages conversation state, health checks, and message sending.
/// Uses [BaseViewModel] for Result-based error handling.
class TravisChatViewModel extends BaseViewModel<TravisChatState> {
  @override
  Future<TravisChatState> build() async {
    final service = ref.read(travisServiceProvider);
    final sessionId = const Uuid().v4();

    // Check health on init
    bool isOnline = false;
    TravisHealth? health;
    try {
      health = await service.health();
      isOnline = health.isOnline;
    } catch (_) {
      // Travis offline — still show chat, messages will show error
    }

    final welcomeMessage = isOnline
        ? TravisMessage.system(
            '🤖 Travis AI đang online! '
            '${health?.totalTools ?? 0} tools sẵn sàng. '
            'Hỏi bất cứ điều gì về business của bạn.',
          )
        : TravisMessage.system(
            '⚠️ Travis AI đang offline. Tin nhắn sẽ được gửi khi kết nối lại.',
          );

    return TravisChatState(
      sessionId: sessionId,
      isOnline: isOnline,
      health: health,
      messages: [welcomeMessage],
    );
  }

  /// Send a message to Travis AI.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final current = state.value;
    if (current == null) return;

    // Add user message immediately
    final userMsg = TravisMessage.user(text.trim());
    state = AsyncData(current.copyWith(
      messages: [...current.messages, userMsg],
      isSending: true,
      errorMessage: null,
    ));

    // Call Travis API
    final service = ref.read(travisServiceProvider);
    final result = await service
        .chat(message: text.trim(), sessionId: current.sessionId)
        .toResult();

    final updated = state.value;
    if (updated == null) return;

    result.when(
      success: (response) {
        state = AsyncData(updated.copyWith(
          messages: [...updated.messages, response],
          isSending: false,
          isOnline: true,
        ));
      },
      failure: (error) {
        final errorMsg = TravisMessage.system(
          '❌ Không thể gửi tin nhắn: ${error.userMessage}',
        );
        state = AsyncData(updated.copyWith(
          messages: [...updated.messages, errorMsg],
          isSending: false,
          errorMessage: error.userMessage,
        ));
      },
    );
  }

  /// Send a quick action command.
  Future<void> sendQuickAction(String action) => sendMessage(action);

  /// Re-check Travis health status.
  Future<void> checkHealth() async {
    final service = ref.read(travisServiceProvider);
    final result = await service.health().toResult();

    final current = state.value;
    if (current == null) return;

    result.when(
      success: (health) {
        state = AsyncData(current.copyWith(
          isOnline: health.isOnline,
          health: health,
        ));
      },
      failure: (_) {
        state = AsyncData(current.copyWith(isOnline: false));
      },
    );
  }

  /// Clear conversation and start new session.
  void clearChat() {
    final current = state.value;
    if (current == null) return;

    final newSessionId = const Uuid().v4();
    state = AsyncData(TravisChatState(
      sessionId: newSessionId,
      isOnline: current.isOnline,
      health: current.health,
      messages: [
        TravisMessage.system('🔄 Cuộc trò chuyện mới đã bắt đầu.'),
      ],
    ));
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Travis Service singleton provider.
final travisServiceProvider = Provider<TravisService>((ref) {
  return TravisService();
});

/// Travis Chat ViewModel provider.
final travisChatViewModelProvider =
    AsyncNotifierProvider<TravisChatViewModel, TravisChatState>(
  TravisChatViewModel.new,
);
