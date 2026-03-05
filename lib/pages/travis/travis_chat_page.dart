import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../core/theme/app_colors.dart';
import '../../core/viewmodels/travis_chat_view_model.dart';
import '../../features/travis/constants/travis_quick_actions.dart';
import '../../features/travis/mixins/travis_chat_mixin.dart';
import '../../models/travis_message.dart';

/// Full-page Travis AI Chat — accessible from CEO routes.
///
/// Features:
/// - Real-time chat with Travis AI backend
/// - Online/offline status indicator
/// - Quick action buttons (empire status, alerts, metrics...)
/// - Specialist info & confidence for each response
/// - Markdown rendering for AI responses
/// - New session / clear chat
class TravisChatPage extends ConsumerStatefulWidget {
  const TravisChatPage({super.key});

  @override
  ConsumerState<TravisChatPage> createState() => _TravisChatPageState();
}

class _TravisChatPageState extends ConsumerState<TravisChatPage>
    with TravisChatMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  ScrollController get chatScrollController => _scrollController;

  @override
  TextEditingController get chatTextController => _controller;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(travisChatViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travis AI'),
        centerTitle: true,
        actions: [
          // Online status indicator
          chatState.when(
            data: (data) => _StatusDot(isOnline: data.isOnline),
            loading: () => const _StatusDot(isOnline: false),
            error: (_, __) => const _StatusDot(isOnline: false),
          ),
          // Health check button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Kiểm tra kết nối',
            onPressed: () {
              ref.read(travisChatViewModelProvider.notifier).checkHealth();
            },
          ),
          // New chat button
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: () {
              ref.read(travisChatViewModelProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: chatState.when(
        data: (data) => ChatContentBody(
          state: data,
          controller: _controller,
          scrollController: _scrollController,
          focusNode: _focusNode,
          onSend: handleSendMessage,
          onQuickAction: handleQuickAction,
        ),
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang kết nối Travis AI...'),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Lỗi: $e'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(travisChatViewModelProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chat Body ──────────────────────────────────────────────────────────────

/// Chat content body — public so [TravisChatTab] can reuse it.
class ChatContentBody extends StatelessWidget {
  final TravisChatState state;
  final TextEditingController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final void Function(String action) onQuickAction;

  const ChatContentBody({
    super.key,
    required this.state,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    required this.onSend,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status bar
        _TravisStatusBar(state: state),

        // Quick actions
        if (state.messages.length <= 2) _QuickActions(onAction: onQuickAction),

        // Messages list
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: state.messages.length + (state.isSending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.messages.length && state.isSending) {
                return const _TypingIndicator();
              }
              return _TravisMessageBubble(message: state.messages[index]);
            },
          ),
        ),

        // Input
        _TravisChatInput(
          controller: controller,
          focusNode: focusNode,
          isSending: state.isSending,
          onSend: onSend,
        ),
      ],
    );
  }
}

// ─── Status Bar ─────────────────────────────────────────────────────────────

class _TravisStatusBar extends StatelessWidget {
  final TravisChatState state;

  const _TravisStatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final health = state.health;
    if (health == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: state.isOnline
            ? AppColors.successLight
            : AppColors.warningLight,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isOnline ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: state.isOnline ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            state.isOnline
                ? '${health.totalTools} tools • ${health.uptimeFormatted}'
                : 'Offline — đang thử kết nối lại',
            style: TextStyle(
              fontSize: 12,
              color: state.isOnline
                  ? AppColors.successDark
                  : AppColors.warningDark,
            ),
          ),
          const Spacer(),
          if (health.version.isNotEmpty)
            Text(
              health.version,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ──────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final void Function(String action) onAction;

  const _QuickActions({required this.onAction});

  static const _actions = TravisQuickActions.full;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Hỏi nhanh:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _actions
                .map((a) => _QuickActionChip(
                      emoji: a.emoji,
                      label: a.label,
                      onTap: () => onAction(a.label),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            '$emoji $label',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────────────────────

class _TravisMessageBubble extends StatelessWidget {
  final TravisMessage message;

  const _TravisMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _SystemMessage(message: message);

    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text('T', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        )
                      : MarkdownWidget(
                          data: message.content,
                          shrinkWrap: true,
                          config: MarkdownConfig(
                            configs: [
                              const PConfig(
                                textStyle:
                                    TextStyle(fontSize: 15, height: 1.4),
                              ),
                              const H1Config(
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const H2Config(
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              CodeConfig(
                                style: TextStyle(
                                  backgroundColor: Colors.grey[200],
                                  fontFamily: 'monospace',
                                ),
                              ),
                              PreConfig(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Specialist info + metadata
                if (!isUser && message.specialist != null) ...[
                  const SizedBox(height: 4),
                  _MetadataRow(message: message),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Specialist + confidence + latency metadata
class _MetadataRow extends StatelessWidget {
  final TravisMessage message;

  const _MetadataRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        if (message.specialist != null)
          _MetaChip(
            icon: Icons.psychology,
            text: message.specialist!,
            color: AppColors.primary,
          ),
        if (message.confidence != null)
          _MetaChip(
            icon: Icons.trending_up,
            text: '${(message.confidence! * 100).toInt()}%',
            color: message.confidence! >= 0.8
                ? AppColors.success
                : AppColors.warning,
          ),
        if (message.latencyMs != null)
          _MetaChip(
            icon: Icons.speed,
            text: '${message.latencyMs}ms',
            color: AppColors.textTertiary,
          ),
        if (message.toolsUsed.isNotEmpty)
          _MetaChip(
            icon: Icons.build,
            text: '${message.toolsUsed.length} tools',
            color: AppColors.info,
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

/// System messages (status, errors)
class _SystemMessage extends StatelessWidget {
  final TravisMessage message;

  const _SystemMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Typing Indicator ───────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text('T',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Travis đang suy nghĩ...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat Input ─────────────────────────────────────────────────────────────

class _TravisChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  const _TravisChatInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isSending,
              decoration: InputDecoration(
                hintText: 'Nói gì đó với Travis...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: isSending ? null : onSend,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                    : Icon(Icons.send_rounded,
                        color: Theme.of(context).colorScheme.surface, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Dot ─────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final bool isOnline;

  const _StatusDot({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? AppColors.success : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
