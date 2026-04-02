import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/roles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../pages/gym_coach_chat_page.dart';
import '../pages/exercise_library_page.dart';
import '../pages/gym_progress_page.dart';
import '../pages/today_plan_page.dart';
import '../viewmodels/gym_coach_view_model.dart';
import '../pages/weekly_plan_page.dart';

/// Gym Agent Layout — 3-tab workspace for Gym Coach AI.
///
/// Tabs: Chat, Dashboard, Bài tập
/// CEO-only: requires authenticated CEO role.
class GymAgentLayout extends ConsumerStatefulWidget {
  const GymAgentLayout({super.key});

  @override
  ConsumerState<GymAgentLayout> createState() => _GymAgentLayoutState();
}

class _GymAgentLayoutState extends ConsumerState<GymAgentLayout> {
  int _currentIndex = 0;

  static const _gymColor = Color(0xFF10B981);

    final _pages = const <Widget>[
      TodayPlanPage(),
      GymCoachChatPage(),
      WeeklyPlanPage(),
      ExerciseLibraryPage(),
      GymProgressPage(),
    ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Auth guard: must be authenticated CEO
    if (!isAuthenticated || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gym Coach AI')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Vui lòng đăng nhập để sử dụng Gym Coach AI'),
            ],
          ),
        ),
      );
    }

    if (user.role != SaboRole.ceo && user.role != SaboRole.superAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gym Coach AI')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('Tính năng này chỉ dành cho CEO'),
            ],
          ),
        ),
      );
    }

    final userName = user.name ?? 'Boss';

    return Scaffold(
      appBar: _currentIndex == 1
          ? _buildChatAppBar(context, userName)
          : _buildDefaultAppBar(context),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: _gymColor.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today, color: _gymColor),
              label: 'Hôm nay',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: _gymColor),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: _gymColor),
              label: 'Lịch',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center, color: _gymColor),
              label: 'Bài tập',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart, color: _gymColor),
              label: 'Tiến bộ',
            ),
          ],
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar(BuildContext context, String userName) {
    final chatState = ref.watch(gymCoachViewModelProvider);

    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gymColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center, color: _gymColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gym Coach AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '🏋️ $userName',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        chatState.when(
          data: (data) => data.isSending
              ? const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) =>
              const Icon(Icons.circle, size: 10, color: Colors.red),
        ),
        IconButton(
          icon: const Icon(Icons.add_comment_outlined),
          tooltip: 'Cuộc trò chuyện mới',
          onPressed: () {
            ref.read(gymCoachViewModelProvider.notifier).clearChat();
          },
        ),
        const RealtimeNotificationBell(),
      ],
    );
  }

  PreferredSizeWidget _buildDefaultAppBar(BuildContext context) {
    final titles = ['Hôm nay', 'Chat', 'Lịch', 'Bài tập', 'Tiến bộ'];
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gymColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center, color: _gymColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Gym Coach — ${titles[_currentIndex]}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: const [RealtimeNotificationBell()],
    );
  }
}
