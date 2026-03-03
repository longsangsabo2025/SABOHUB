import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/gamification/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.isUnlocked = false,
    this.unlockedAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarityInfo = _rarityInfo(achievement.rarity);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked
                  ? rarityInfo.color.withValues(alpha: 0.4)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              _buildIcon(rarityInfo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.isSecret && !isUnlocked
                                ? '???'
                                : achievement.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isUnlocked
                                  ? AppColors.textPrimary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: rarityInfo.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rarityInfo.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: rarityInfo.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.isSecret && !isUnlocked
                          ? 'Thành tựu ẩn — khám phá để mở khóa!'
                          : achievement.description ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked
                            ? AppColors.textSecondary
                            : Colors.grey.shade300,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(_RarityInfo rarityInfo) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked
            ? rarityInfo.color.withValues(alpha: 0.15)
            : Colors.grey.shade100,
        border: Border.all(
          color: isUnlocked ? rarityInfo.color : Colors.grey.shade300,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Center(
        child: isUnlocked
            ? Text(
                _iconForAchievement(achievement.icon),
                style: const TextStyle(fontSize: 20),
              )
            : Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400),
      ),
    );
  }

  String _iconForAchievement(String iconName) {
    const iconMap = {
      'star': '⭐',
      'fire': '🔥',
      'trophy': '🏆',
      'medal': '🎖️',
      'crown': '👑',
      'shield': '🛡️',
      'sword': '⚔️',
      'diamond': '💎',
      'rocket': '🚀',
      'heart': '❤️',
      'bolt': '⚡',
      'target': '🎯',
      'ghost': '👻',
      'moon': '🌙',
      'phoenix': '🔥',
    };
    return iconMap[iconName] ?? '🎖️';
  }

  _RarityInfo _rarityInfo(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return _RarityInfo('Phổ thông', const Color(0xFF78909C));
      case AchievementRarity.rare:
        return _RarityInfo('Hiếm', const Color(0xFF1E88E5));
      case AchievementRarity.epic:
        return _RarityInfo('Sử thi', const Color(0xFF7B1FA2));
      case AchievementRarity.legendary:
        return _RarityInfo('Huyền thoại', const Color(0xFFFF8F00));
      case AchievementRarity.mythic:
        return _RarityInfo('Thần thoại', const Color(0xFFC62828));
    }
  }
}

class _RarityInfo {
  final String label;
  final Color color;
  const _RarityInfo(this.label, this.color);
}
