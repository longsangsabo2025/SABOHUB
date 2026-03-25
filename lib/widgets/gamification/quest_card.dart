import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/gamification/quest_definition.dart';
import '../../models/gamification/quest_progress.dart';

class QuestCard extends StatelessWidget {
  final QuestProgress progress;
  final VoidCallback? onTap;

  const QuestCard({
    super.key,
    required this.progress,
    this.onTap,
  });

  QuestDefinition? get quest => progress.quest;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(progress.status);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusInfo.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(statusInfo),
              const SizedBox(height: 8),
              if (quest?.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    quest!.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              _buildProgressSection(statusInfo),
              const SizedBox(height: 8),
              _buildRewards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_StatusInfo statusInfo) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusInfo.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            quest?.questType.icon ?? '📋',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            quest?.name ?? 'Quest',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusInfo.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(_StatusInfo statusInfo) {
    if (progress.status == QuestStatus.locked) {
      return Row(
        children: [
          Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            'Hoàn thành nhiệm vụ trước để mở khóa',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.progressPercent,
            minHeight: 6,
            backgroundColor: statusInfo.color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(statusInfo.color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.progressCurrent} / ${progress.progressTarget}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              '${(progress.progressPercent * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusInfo.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRewards() {
    final rewards = <Widget>[];

    if (quest != null && quest!.xpReward > 0) {
      rewards.add(_rewardChip('⚡ ${quest!.xpReward} XP', AppColors.warning));
    }
    if (quest?.badgeReward != null) {
      rewards.add(_rewardChip('🎖️ ${quest!.badgeReward}', AppColors.info));
    }
    if (quest?.titleReward != null) {
      rewards.add(_rewardChip('👑 ${quest!.titleReward}', AppColors.secondary));
    }

    if (rewards.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: rewards,
    );
  }

  Widget _rewardChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  _StatusInfo _statusInfo(QuestStatus status) {
    switch (status) {
      case QuestStatus.locked:
        return _StatusInfo('Khóa', Colors.grey);
      case QuestStatus.available:
        return _StatusInfo('Sẵn sàng', AppColors.info);
      case QuestStatus.inProgress:
        return _StatusInfo('Đang làm', AppColors.warning);
      case QuestStatus.completed:
        return _StatusInfo('Hoàn thành', AppColors.success);
      case QuestStatus.failed:
        return _StatusInfo('Thất bại', AppColors.error);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
