import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum QuestNotificationType { questComplete, xpGain, levelUp, achievementUnlock, streakMilestone, dailyCombo }

class QuestNotificationBar {
  static void show(
    BuildContext context, {
    required QuestNotificationType type,
    required String message,
    int? xpAmount,
    Duration duration = const Duration(seconds: 3),
  }) {
    final info = _notificationInfo(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (xpAmount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$xpAmount XP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: info.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static _NotifInfo _notificationInfo(QuestNotificationType type) {
    switch (type) {
      case QuestNotificationType.questComplete:
        return _NotifInfo('⚔️', 'QUEST HOÀN THÀNH', const Color(0xFF2E7D32));
      case QuestNotificationType.xpGain:
        return _NotifInfo('⚡', 'XP', AppColors.warning);
      case QuestNotificationType.levelUp:
        return _NotifInfo('🎉', 'LEVEL UP!', AppColors.primary);
      case QuestNotificationType.achievementUnlock:
        return _NotifInfo('🏆', 'THÀNH TỰU MỚI', const Color(0xFFE65100));
      case QuestNotificationType.streakMilestone:
        return _NotifInfo('🔥', 'STREAK', const Color(0xFFFF6D00));
      case QuestNotificationType.dailyCombo:
        return _NotifInfo('💥', 'DAILY COMBO!', const Color(0xFFC62828));
    }
  }
}

class _NotifInfo {
  final String emoji;
  final String label;
  final Color color;
  const _NotifInfo(this.emoji, this.label, this.color);
}
