import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';

class GameNotificationsPage extends ConsumerStatefulWidget {
  const GameNotificationsPage({super.key});

  @override
  ConsumerState<GameNotificationsPage> createState() => _GameNotificationsPageState();
}

class _GameNotificationsPageState extends ConsumerState<GameNotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationActionsProvider).markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(gameNotificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: () {
              ref.read(gamificationActionsProvider).markNotificationsRead();
            },
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Không có thông báo',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (ctx, i) => _NotificationTile(notification: notifs[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final GameNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = DateTime.now().difference(notification.createdAt);

    return Card(
      elevation: notification.isRead ? 0 : 1,
      color: notification.isRead ? null : theme.colorScheme.primaryContainer.withAlpha(51),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : BorderSide(color: theme.colorScheme.primary.withAlpha(51)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _bgColor(notification.type).withAlpha(25),
          ),
          child: Center(
            child: Text(notification.icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          notification.body,
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatAge(age),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }

  Color _bgColor(String type) {
    const map = {
      'streak_warning': Colors.orange,
      'quest_reminder': Colors.blue,
      'achievement_near': Colors.amber,
      'level_up': Colors.green,
      'season_ending': Colors.red,
      'weekly_summary': Colors.purple,
      'prestige_ready': Colors.deepPurple,
    };
    return map[type] ?? Colors.grey;
  }

  String _formatAge(Duration age) {
    if (age.inMinutes < 1) return 'vừa xong';
    if (age.inMinutes < 60) return '${age.inMinutes}p';
    if (age.inHours < 24) return '${age.inHours}h';
    if (age.inDays < 7) return '${age.inDays}d';
    return '${(age.inDays / 7).floor()}w';
  }
}
