import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/viewmodels/travis_chat_view_model.dart';
import '../../features/travis/mixins/travis_chat_mixin.dart';
import 'travis_chat_page.dart';

/// Embeddable Travis AI Chat — dùng bên trong TabBarView (không có Scaffold/AppBar riêng).
///
/// Khác với [TravisChatPage] (full-page với Scaffold + AppBar),
/// widget này chỉ có body content + action bar nhỏ ở trên.
class TravisChatTab extends ConsumerWidget {
  const TravisChatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(travisChatViewModelProvider);

    return Column(
      children: [
        // Mini action bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Online status
              chatState.when(
                data: (data) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: data.isOnline
                            ? AppColors.success
                            : AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.isOnline ? 'Travis Online' : 'Travis Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: data.isOnline
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                    ),
                    if (data.health != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${data.health!.totalTools} tools',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                loading: () => const Text('Đang kết nối...',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                error: (_, __) => const Text('Lỗi kết nối',
                    style: TextStyle(fontSize: 12, color: AppColors.error)),
              ),
              const Spacer(),
              // Refresh health
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Kiểm tra kết nối',
                onPressed: () {
                  ref.read(travisChatViewModelProvider.notifier).checkHealth();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // New chat
              IconButton(
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                tooltip: 'Chat mới',
                onPressed: () {
                  ref.read(travisChatViewModelProvider.notifier).clearChat();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Open full page
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: 'Mở toàn màn hình',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TravisChatPage(),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),

        // Reuse the full chat body from TravisChatPage
        Expanded(
          child: TravisChatBody(ref: ref),
        ),
      ],
    );
  }
}

/// Standalone chat body — extracted so both TravisChatPage and TravisChatTab
/// can reuse it without duplicating code.
class TravisChatBody extends ConsumerStatefulWidget {
  const TravisChatBody({super.key, required WidgetRef ref});

  @override
  ConsumerState<TravisChatBody> createState() => _TravisChatBodyState();
}

class _TravisChatBodyState extends ConsumerState<TravisChatBody>
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

    return chatState.when(
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
    );
  }
}
