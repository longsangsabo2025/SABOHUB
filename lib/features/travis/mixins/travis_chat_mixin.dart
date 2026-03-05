import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/viewmodels/travis_chat_view_model.dart';

/// Mixin providing shared chat behavior for Travis AI widgets.
///
/// Eliminates duplicate `_scrollToBottom()` and `_handleSend()` code
/// across TravisChatPage, TravisChatTab, and TravisFloatingChat.
///
/// Usage:
/// ```dart
/// class _MyState extends ConsumerState<MyWidget> with TravisChatMixin {
///   @override
///   ScrollController get chatScrollController => _scrollController;
///   @override
///   TextEditingController get chatTextController => _textController;
/// }
/// ```
mixin TravisChatMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Override to provide the scroll controller.
  ScrollController get chatScrollController;

  /// Override to provide the text controller.
  TextEditingController get chatTextController;

  /// Scroll the messages list to bottom with animation.
  void scrollToBottom({
    Duration duration = const Duration(milliseconds: 300),
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Send the current text input to Travis AI.
  void handleSendMessage() {
    final text = chatTextController.text.trim();
    if (text.isEmpty) return;

    chatTextController.clear();
    ref.read(travisChatViewModelProvider.notifier).sendMessage(text);
    scrollToBottom();
  }

  /// Send a quick action to Travis AI.
  void handleQuickAction(String action) {
    ref.read(travisChatViewModelProvider.notifier).sendQuickAction(action);
    scrollToBottom();
  }
}
