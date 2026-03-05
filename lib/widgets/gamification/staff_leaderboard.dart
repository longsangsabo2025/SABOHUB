import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/gamification/employee_game_profile.dart';
import '../../providers/gamification_provider.dart';

class StaffLeaderboard extends ConsumerWidget {
  final bool compact;
  const StaffLeaderboard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(staffLeaderboardProvider);

    return leaderboard.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _emptyState();
        }

        final displayEntries = compact ? entries.take(5).toList() : entries;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('👥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                const Text(
                  'Staff Leaderboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (!compact)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(gamificationActionsProvider).recalculateStaffScores();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Tính lại'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...displayEntries.map((e) => _buildEntryTile(context, e)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Lỗi: $e', style: const TextStyle(color: AppColors.error)),
    );
  }

  Widget _buildEntryTile(BuildContext context, StaffLeaderboardEntry entry) {
    final isTop3 = entry.rank <= 3;
    final tierColor = _tierColor(entry.level);

    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop3 ? tierColor.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Center(
              child: isTop3
                  ? Text(_rankEmoji(entry.rank), style: const TextStyle(fontSize: 18))
                  : Text(
                      '#${entry.rank}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tierColor.withValues(alpha: 0.12),
              border: Border.all(color: tierColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                '${entry.level}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: tierColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.currentTitle,
                  style: TextStyle(fontSize: 11, color: tierColor),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            _miniStat('📋', '${entry.attendanceScore.toInt()}%'),
            const SizedBox(width: 8),
            _miniStat('✅', '${entry.taskScore.toInt()}%'),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalXp} XP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              if (entry.streakDays > 0)
                Text(
                  '🔥 ${entry.streakDays}',
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Text('👥', style: TextStyle(fontSize: 40)),
          SizedBox(height: 8),
          Text(
            'Chưa có dữ liệu nhân viên',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            'Nhân viên sẽ tự động được chấm điểm dựa trên attendance & tasks',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  Color _tierColor(int level) {
    if (level >= 50) return Color(0xFFC62828);
    if (level >= 40) return Color(0xFF00BCD4);
    if (level >= 30) return Color(0xFF9C27B0);
    if (level >= 20) return Color(0xFFFFD700);
    if (level >= 15) return Color(0xFFC0C0C0);
    if (level >= 10) return AppColors.tierBronze;
    if (level >= 5) return Color(0xFF607D8B);
    return AppColors.grey500;
  }
}
