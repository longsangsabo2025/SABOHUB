import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../constants/gym_quick_actions.dart';
import '../models/gym_coach_message.dart';
import '../viewmodels/gym_coach_view_model.dart';

/// Gym Coach Chat Page — Full-page AI gym coaching chat.
///
/// Replicates the Travis AI chat pattern but specialized for gym coaching.
class GymCoachChatPage extends ConsumerStatefulWidget {
  const GymCoachChatPage({super.key});

  @override
  ConsumerState<GymCoachChatPage> createState() => _GymCoachChatPageState();
}

class _GymCoachChatPageState extends ConsumerState<GymCoachChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  static const _gymColor = Color(0xFF10B981); // Emerald green

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(gymCoachViewModelProvider.notifier).sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(gymCoachViewModelProvider);

    return chatState.when(
      data: (data) {
        _scrollToBottom();
        return Column(
          children: [
            Expanded(
              child: data.messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(data),
            ),
            if (data.isSending) _buildTypingIndicator(),
            _buildQuickActions(data),
            _buildInput(data),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $e', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(gymCoachViewModelProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _gymColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center, size: 64, color: _gymColor),
          ),
          const SizedBox(height: 24),
          Text(
            'Gym Coach AI',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Huấn luyện viên cá nhân AI của bạn',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(GymCoachState data) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: data.messages.length,
      itemBuilder: (context, index) {
        return _GymMessageBubble(message: data.messages[index]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _gymColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_gymColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Coach đang soạn bài tập...',
              style: TextStyle(
                color: _gymColor,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(GymCoachState data) {
    if (data.messages.length > 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: GymQuickActions.full.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = GymQuickActions.full[index];
          return ActionChip(
            avatar: Text(action.emoji, style: const TextStyle(fontSize: 14)),
            label: Text(action.label, style: const TextStyle(fontSize: 12)),
            onPressed: data.isSending
                ? null
                : () => ref
                    .read(gymCoachViewModelProvider.notifier)
                    .sendQuickAction(action.displayText),
            backgroundColor: _gymColor.withValues(alpha: 0.08),
            side: BorderSide(color: _gymColor.withValues(alpha: 0.2)),
          );
        },
      ),
    );
  }

  Widget _buildInput(GymCoachState data) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Hỏi Coach AI về tập luyện...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.08),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: data.isSending
                  ? Colors.grey
                  : _gymColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: data.isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual message bubble for gym coach chat.
class _GymMessageBubble extends StatelessWidget {
  final GymCoachMessage message;

  const _GymMessageBubble({required this.message});

  static const _gymColor = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _buildSystemMessage(context);

    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _gymColor,
              child: const Text('🏋️', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? _gymColor
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    )
                  : MarkdownWidget(
                      data: message.content,
                      shrinkWrap: true,
                      config: MarkdownConfig(
                        configs: [
                          const PConfig(
                            textStyle: TextStyle(fontSize: 15, height: 1.4),
                          ),
                          H1Config(
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          H2Config(
                            style: const TextStyle(
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
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: MarkdownWidget(
            data: message.content,
            shrinkWrap: true,
            config: MarkdownConfig(
              configs: [
                PConfig(
                  textStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
