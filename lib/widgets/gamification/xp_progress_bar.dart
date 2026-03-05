import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/gamification/ceo_profile.dart';

class XpProgressBar extends StatelessWidget {
  final CeoProfile profile;
  final bool showLabel;
  final bool compact;

  const XpProgressBar({
    super.key,
    required this.profile,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 8.0 : 14.0;
    final progress = profile.levelProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lv.${profile.level}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 11 : 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  profile.isMaxLevel
                      ? 'MAX LEVEL'
                      : '${profile.xpInCurrentLevel} / ${profile.xpNeededForNext} XP',
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradientForLevel(profile.level),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _gradientForLevel(int level) {
    if (level >= 76) return [Color(0xFFFFD700), Color(0xFFFFA500)];
    if (level >= 51) return [Color(0xFFE040FB), Color(0xFF7C4DFF)];
    if (level >= 31) return [Color(0xFF00BCD4), AppColors.info];
    if (level >= 16) return [AppColors.success, Color(0xFF8BC34A)];
    if (level >= 6) return [Color(0xFF42A5F5), Color(0xFF1E88E5)];
    return [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)];
  }
}
