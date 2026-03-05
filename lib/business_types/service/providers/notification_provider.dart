import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'session_provider.dart';

/// In-app notification — generated from business rules, no Firebase needed
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String icon;
  final DateTime createdAt;
  final NotificationPriority priority;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.createdAt,
    this.priority = NotificationPriority.info,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority.name,
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    icon: json['icon'],
    createdAt: DateTime.parse(json['createdAt']),
    priority: NotificationPriority.values.firstWhere(
      (e) => e.name == json['priority'],
      orElse: () => NotificationPriority.info,
    ),
    isRead: json['isRead'] ?? false,
  );
}

enum NotificationPriority { urgent, warning, info }

class NotificationNotifier extends AsyncNotifier<List<AppNotification>> {
  static const _prefKey = 'sabohub_notifications';

  @override
  Future<List<AppNotification>> build() async {
    return await _loadFromPrefs();
  }

  Future<List<AppNotification>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _save(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(notifications.map((n) => n.toJson()).toList()));
  }

  Future<void> addNotification(AppNotification notification) async {
    final current = await future;
    // Avoid duplicates on same day with same id-prefix
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = current.any((n) => n.id.startsWith('${notification.id}_$today'));
    if (existing) return;

    final updated = [
      AppNotification(
        id: '${notification.id}_$today',
        title: notification.title,
        body: notification.body,
        icon: notification.icon,
        createdAt: notification.createdAt,
        priority: notification.priority,
      ),
      ...current,
    ];

    // Keep max 50 notifications
    final trimmed = updated.take(50).toList();
    state = AsyncValue.data(trimmed);
    await _save(trimmed);
  }

  Future<void> markAllRead() async {
    final current = await future;
    final updated = current
        .map((n) => AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              icon: n.icon,
              createdAt: n.createdAt,
              priority: n.priority,
              isRead: true,
            ))
        .toList();
    state = AsyncValue.data(updated);
    await _save(updated);
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, List<AppNotification>>(() {
  return NotificationNotifier();
});

/// Auto-generates notifications based on session stats
final notificationGeneratorProvider = Provider.autoDispose<void>((ref) {
  final statsAsync = ref.watch(sessionStatsProvider);
  final notifier = ref.read(notificationProvider.notifier);

  statsAsync.whenData((stats) {
    final now = DateTime.now();
    final activeSessions = stats['activeSessions'] as int? ?? 0;
    final todayRevenue = (stats['todayRevenue'] as num?)?.toDouble() ?? 0.0;
    final completedToday = stats['completedToday'] as int? ?? 0;

    // Alert: revenue milestone
    if (todayRevenue >= 5000000) {
      notifier.addNotification(AppNotification(
        id: 'revenue_5m',
        title: '🎉 Doanh thu đạt 5 triệu!',
        body:
            'Hôm nay đã đạt ${(todayRevenue / 1000000).toStringAsFixed(1)}M. Xuất sắc!',
        icon: '💰',
        createdAt: now,
        priority: NotificationPriority.info,
      ));
    }

    // Alert: many active sessions
    if (activeSessions >= 8) {
      notifier.addNotification(AppNotification(
        id: 'busy_session',
        title: '🔥 Đang bận: $activeSessions bàn đang chơi',
        body: 'Giờ cao điểm! Đảm bảo đủ nhân viên phục vụ.',
        icon: '🎱',
        createdAt: now,
        priority: NotificationPriority.warning,
      ));
    }

    // Info: daily summary (only after 6pm)
    if (now.hour >= 18 && completedToday >= 5) {
      notifier.addNotification(AppNotification(
        id: 'daily_summary',
        title: '📊 Tổng kết buổi chiều',
        body: 'Đã hoàn thành $completedToday phiên hôm nay.',
        icon: '📋',
        createdAt: now,
        priority: NotificationPriority.info,
      ));
    }
  });
});
