import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

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
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.surface70,
                    ),
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ],
              ),
            ),
            if (xpAmount != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$xpAmount XP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.surface,
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
        return _NotifInfo('⚔️', 'QUEST HOÀN THÀNH', Color(0xFF2E7D32));
      case QuestNotificationType.xpGain:
        return _NotifInfo('⚡', 'XP', AppColors.warning);
      case QuestNotificationType.levelUp:
        return _NotifInfo('🎉', 'LEVEL UP!', AppColors.primary);
      case QuestNotificationType.achievementUnlock:
        return _NotifInfo('🏆', 'THÀNH TỰU MỚI', Color(0xFFE65100));
      case QuestNotificationType.streakMilestone:
        return _NotifInfo('🔥', 'STREAK', Color(0xFFFF6D00));
      case QuestNotificationType.dailyCombo:
        return _NotifInfo('💥', 'DAILY COMBO!', Color(0xFFC62828));
    }
  }
}

class _NotifInfo {
  final String emoji;
  final String label;
  final Color color;
  const _NotifInfo(this.emoji, this.label, this.color);
}
