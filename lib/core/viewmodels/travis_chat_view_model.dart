import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  static const _messagesKey = 'travis_chat_messages';
  static const _sessionKey = 'travis_chat_session';
  static const _maxPersistedMessages = 50;

  @override
  Future<TravisChatState> build() async {
    final service = ref.read(travisServiceProvider);

    // Stable sessionId: reuse persisted or derive from userId
    final prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString(_sessionKey) ?? '';
    if (sessionId.isEmpty) {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      sessionId = uid != null ? 'sabohub-$uid' : const Uuid().v4();
      await prefs.setString(_sessionKey, sessionId);
    }

    // Load persisted messages
    final savedMessages = _loadMessages(prefs);

    // Check health on init
    bool isOnline = false;
    TravisHealth? health;
    try {
      health = await service.health();
      isOnline = health.isOnline;
    } catch (_) {
      // Travis offline — still show chat, messages will show error
    }

    if (savedMessages.isNotEmpty) {
      return TravisChatState(
        sessionId: sessionId,
        isOnline: isOnline,
        health: health,
        messages: savedMessages,
      );
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

  /// Load messages from SharedPreferences.
  List<TravisMessage> _loadMessages(SharedPreferences prefs) {
    final raw = prefs.getString(_messagesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TravisMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persist current messages to SharedPreferences.
  Future<void> _saveMessages(List<TravisMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep only recent messages to avoid bloating storage
    final toSave = messages.length > _maxPersistedMessages
        ? messages.sublist(messages.length - _maxPersistedMessages)
        : messages;
    final json = jsonEncode(toSave.map((m) => m.toJson()).toList());
    await prefs.setString(_messagesKey, json);
  }

  /// Send a message to Travis AI.
  ///
  /// [forceSpecialist] bypasses auto-routing (e.g. 'ops', 'life', 'ceo').
  /// [forceTool] hints OpenAI to call a specific tool immediately.
  Future<void> sendMessage(
    String text, {
    String? forceSpecialist,
    String? forceTool,
  }) async {
    if (text.trim().isEmpty) return;

    final current = state.value;
    if (current == null) return;

    // Add user message immediately
    final userMsg = TravisMessage.user(text.trim());
    final messagesWithUser = [...current.messages, userMsg];
    state = AsyncData(current.copyWith(
      messages: messagesWithUser,
      isSending: true,
      errorMessage: null,
    ));
    _saveMessages(messagesWithUser);

    // Call Travis API
    final service = ref.read(travisServiceProvider);
    final result = await service
        .chat(
          message: text.trim(),
          sessionId: current.sessionId,
          forceSpecialist: forceSpecialist,
          forceTool: forceTool,
        )
        .toResult();

    final updated = state.value;
    if (updated == null) return;

    result.when(
      success: (response) {
        final newMessages = [...updated.messages, response];
        state = AsyncData(updated.copyWith(
          messages: newMessages,
          isSending: false,
          isOnline: true,
        ));
        _saveMessages(newMessages);
      },
      failure: (error) {
        final errorMsg = TravisMessage.system(
          '❌ Không thể gửi tin nhắn: ${error.userMessage}',
        );
        final newMessages = [...updated.messages, errorMsg];
        state = AsyncData(updated.copyWith(
          messages: newMessages,
          isSending: false,
          errorMessage: error.userMessage,
        ));
        _saveMessages(newMessages);
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
  Future<void> clearChat() async {
    final current = state.value;
    if (current == null) return;

    final newSessionId = const Uuid().v4();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
    await prefs.setString(_sessionKey, newSessionId);

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
