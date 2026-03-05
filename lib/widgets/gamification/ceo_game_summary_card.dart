import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/token_provider.dart';
import 'level_badge.dart';
import 'xp_progress_bar.dart';
import 'streak_counter.dart';

class CeoGameSummaryCard extends ConsumerWidget {
  final VoidCallback? onTap;

  CeoGameSummaryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(ceoProfileProvider);
    final profile = profileState.profile;

    if (profileState.isLoading) {
      return _buildSkeleton();
    }

    if (profile == null) return SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                _tierColor(profile.level).withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  LevelBadge(level: profile.level, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.currentTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StreakCounter(
                              streakDays: profile.streakDays,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        XpProgressBar(profile: profile, compact: true),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statChip('⚡', '${profile.totalXp} XP', AppColors.warning),
                  const SizedBox(width: 8),
                  _statChip('⭐', '${profile.reputationPoints} Uy Tín', AppColors.info),
                  const SizedBox(width: 8),
                  _tokenChip(ref),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String emoji, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tokenChip(WidgetRef ref) {
    final balance = ref.watch(currentBalanceProvider);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFFFF8F00).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              '${balance.toInt()} SABO',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF8F00),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Color _tierColor(int level) {
    if (level >= 76) return Color(0xFFFF8F00);
    if (level >= 51) return Color(0xFF7B1FA2);
    if (level >= 31) return Color(0xFF0097A7);
    if (level >= 16) return Color(0xFF2E7D32);
    if (level >= 6) return Color(0xFF1565C0);
    return Color(0xFF455A64);
  }
}
