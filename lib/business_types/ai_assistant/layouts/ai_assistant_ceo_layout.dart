import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/viewmodels/travis_chat_view_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/error_boundary.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../../../pages/travis/travis_chat_page.dart';
import '../pages/travis_dashboard_page.dart';
import '../pages/travis_cost_page.dart';
import '../pages/travis_history_page.dart';
import '../pages/travis_settings_page.dart';

/// AI Assistant CEO Layout — Travis-centric workspace.
///
/// 4 tabs: Chat (main), Dashboard, History, Settings
class AiAssistantCeoLayout extends ConsumerStatefulWidget {
  const AiAssistantCeoLayout({super.key});

  @override
  ConsumerState<AiAssistantCeoLayout> createState() =>
      _AiAssistantCeoLayoutState();
}

class _AiAssistantCeoLayoutState extends ConsumerState<AiAssistantCeoLayout> {
  int _currentIndex = 0;

  static const _travisColor = Color(0xFF8B5CF6);

  final _pages = const <Widget>[
    _TravisChatTab(),
    TravisDashboardPage(),
    TravisCostPage(),
    TravisHistoryPage(),
    TravisSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'User';

    return ErrorBoundary(
      child: Scaffold(
        appBar: _currentIndex == 0
            ? _buildChatAppBar(context, userName)
            : _buildDefaultAppBar(context, userName),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          indicatorColor: _travisColor.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: _travisColor),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: _travisColor),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.attach_money_outlined),
              selectedIcon: Icon(Icons.attach_money, color: _travisColor),
              label: 'Cost',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: _travisColor),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: _travisColor),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar(BuildContext context, String userName) {
    final chatState = ref.watch(travisChatViewModelProvider);

    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _travisColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, color: _travisColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Travis AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '🤖 $userName',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Online indicator
        chatState.when(
          data: (data) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.circle,
              size: 10,
              color: data.isOnline ? AppColors.success : AppColors.warning,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Icon(Icons.circle, size: 10, color: AppColors.error),
        ),
        IconButton(
          icon: const Icon(Icons.add_comment_outlined),
          tooltip: 'Cuộc trò chuyện mới',
          onPressed: () {
            ref.read(travisChatViewModelProvider.notifier).clearChat();
          },
        ),
        const RealtimeNotificationBell(),
      ],
    );
  }

  PreferredSizeWidget _buildDefaultAppBar(BuildContext context, String userName) {
    final titles = ['Chat', 'Dashboard', 'History', 'Settings'];
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _travisColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, color: _travisColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Travis AI — ${titles[_currentIndex]}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: const [RealtimeNotificationBell()],
    );
  }
}

/// Chat tab — wraps the existing [TravisChatPage] body without its own Scaffold.
class _TravisChatTab extends ConsumerStatefulWidget {
  const _TravisChatTab();

  @override
  ConsumerState<_TravisChatTab> createState() => _TravisChatTabState();
}

class _TravisChatTabState extends ConsumerState<_TravisChatTab>
    with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(travisChatViewModelProvider.notifier).sendMessage(text);
    _controller.clear();
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleQuickAction(String action) {
    ref.read(travisChatViewModelProvider.notifier).sendMessage(action);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chatState = ref.watch(travisChatViewModelProvider);

    return chatState.when(
      data: (data) => ChatContentBody(
        state: data,
        controller: _controller,
        scrollController: _scrollController,
        focusNode: _focusNode,
        onSend: _handleSend,
        onQuickAction: _handleQuickAction,
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
