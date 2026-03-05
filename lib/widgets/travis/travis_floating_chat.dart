import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/viewmodels/travis_chat_view_model.dart';
import '../../features/travis/constants/travis_quick_actions.dart';
import '../../features/travis/mixins/travis_chat_mixin.dart';
import '../../models/travis_message.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Floating Travis AI chat widget — hiển thị trên mọi màn hình.
///
/// Gắn vào Scaffold bằng Stack hoặc Overlay:
/// ```dart
/// Stack(
///   children: [
///     Scaffold(...), // main content
///     const TravisFloatingChat(),
///   ],
/// )
/// ```
///
/// Hoặc dùng trong Widget tree bất kỳ:
/// ```dart
/// // Cách sử dụng trong bất kỳ page nào:
/// @override
/// Widget build(BuildContext context) {
///   return Stack(
///     children: [
///       Scaffold(
///         appBar: AppBar(title: const Text('Dashboard')),
///         body: const Center(child: Text('Main content')),
///       ),
///       const TravisFloatingChat(),
///     ],
///   );
/// }
/// ```
///
/// Nếu muốn hiển thị global (overlay trên tất cả pages):
/// ```dart
/// // Trong app_router.dart hoặc main layout:
/// MaterialApp.router(
///   builder: (context, child) {
///     return Stack(
///       children: [
///         child ?? const SizedBox.shrink(),
///         const TravisFloatingChat(),
///       ],
///     );
///   },
/// )
/// ```
class TravisFloatingChat extends ConsumerStatefulWidget {
  const TravisFloatingChat({super.key});

  @override
  ConsumerState<TravisFloatingChat> createState() => _TravisFloatingChatState();
}

class _TravisFloatingChatState extends ConsumerState<TravisFloatingChat>
    with SingleTickerProviderStateMixin, TravisChatMixin {
  bool _isExpanded = false;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  ScrollController get chatScrollController => _scrollController;

  @override
  TextEditingController get chatTextController => _textController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded chat panel
          if (_isExpanded)
            ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment.bottomRight,
              child: _FloatingChatPanel(
                textController: _textController,
                scrollController: _scrollController,
                onSend: handleSendMessage,
                onClose: _toggle,
              ),
            ),

          const SizedBox(height: 8),

          // FAB
          _TravisFab(
            isExpanded: _isExpanded,
            onTap: _toggle,
          ),
        ],
      ),
    );
  }
}

// ─── FAB ────────────────────────────────────────────────────────────────────

class _TravisFab extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _TravisFab({required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(travisChatViewModelProvider);
    final isOnline = chatState.value?.isOnline ?? false;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      color: AppColors.primary,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Stack(
            children: [
              Icon(
                isExpanded ? Icons.close : Icons.smart_toy_rounded,
                color: Theme.of(context).colorScheme.surface,
                size: 28,
              ),
              // Online dot
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.success : AppColors.textTertiary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating Chat Panel ────────────────────────────────────────────────────

class _FloatingChatPanel extends ConsumerWidget {
  final TextEditingController textController;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final VoidCallback onClose;

  const _FloatingChatPanel({
    required this.textController,
    required this.scrollController,
    required this.onSend,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(travisChatViewModelProvider);

    return Container(
      width: 340,
      height: 480,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _PanelHeader(
            isOnline: chatState.value?.isOnline ?? false,
            onClose: onClose,
            onNewChat: () {
              ref.read(travisChatViewModelProvider.notifier).clearChat();
            },
          ),

          // Messages
          Expanded(
            child: chatState.when(
              data: (data) => ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount:
                    data.messages.length + (data.isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == data.messages.length && data.isSending) {
                    return const _MiniTypingIndicator();
                  }
                  return _MiniMessageBubble(
                    message: data.messages[index],
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi: $e',
                      style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ),

          // Quick actions (only when few messages)
          if ((chatState.value?.messages.length ?? 0) <= 2)
            _MiniQuickActions(
              onAction: (action) {
                ref
                    .read(travisChatViewModelProvider.notifier)
                    .sendQuickAction(action);
              },
            ),

          // Input
          _MiniChatInput(
            controller: textController,
            isSending: chatState.value?.isSending ?? false,
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

// ─── Panel Header ───────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onClose;
  final VoidCallback onNewChat;

  const _PanelHeader({
    required this.isOnline,
    required this.onClose,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.surface24,
            child: Text('T',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travis AI',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isOnline ? 'Online • Sẵn sàng giúp bạn' : 'Offline',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_comment_outlined,
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7), size: 18),
            onPressed: onNewChat,
            tooltip: 'Chat mới',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7), size: 18),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Message Bubble (compact for floating panel) ───────────────────────

class _MiniMessageBubble extends StatelessWidget {
  final TravisMessage message;

  const _MiniMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: 260),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: isUser ? Theme.of(context).colorScheme.surface : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mini Typing Indicator ──────────────────────────────────────────────────

class _MiniTypingIndicator extends StatelessWidget {
  const _MiniTypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Đang suy nghĩ...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mini Quick Actions ─────────────────────────────────────────────────────

class _MiniQuickActions extends StatelessWidget {
  final void Function(String action) onAction;

  const _MiniQuickActions({required this.onAction});

  static const _actions = TravisQuickActions.compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: _actions
            .map((a) => InkWell(
                  onTap: () => onAction(a.label),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(a.displayText, style: const TextStyle(fontSize: 11)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Mini Chat Input ────────────────────────────────────────────────────────

class _MiniChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MiniChatInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              decoration: InputDecoration(
                hintText: 'Hỏi Travis...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: isSending ? null : onSend,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: isSending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                    : Icon(Icons.send_rounded,
                        color: Theme.of(context).colorScheme.surface, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
