import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';

class DailyQuestPanel extends ConsumerWidget {
  const DailyQuestPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyResults = ref.watch(dailyQuestResultsProvider);
    final todayLog = ref.watch(todayQuestLogProvider);

    return dailyResults.when(
      data: (results) {
        final completedCount = results.where((r) => r.isCompleted).length;
        final isCombo = completedCount >= 5;
        final totalXp = results.fold<int>(0, (sum, r) => sum + (r.isCompleted ? r.xpReward : 0));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildComboHeader(completedCount, isCombo, totalXp),
            const SizedBox(height: 12),
            ...results.map((r) => _buildDailyQuestTile(r)),
            if (isCombo) _buildComboBonus(),
            const SizedBox(height: 16),
            todayLog.when(
              data: (log) => log != null ? _buildDailyCalendar(log, ref) : const SizedBox(),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildComboHeader(int completed, bool isCombo, int totalXp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCombo
            ? const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFFF9100)])
            : LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade50]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCombo ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isCombo ? '💥' : '📅',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCombo ? 'DAILY COMBO!' : 'Daily Quests',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCombo ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$completed/5 hoàn thành • +$totalXp XP',
                  style: TextStyle(
                    fontSize: 13,
                    color: isCombo ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: completed / 5,
                  backgroundColor: isCombo ? Colors.white24 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    isCombo ? Colors.white : AppColors.primary,
                  ),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    '$completed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCombo ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuestTile(DailyQuestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: result.isCompleted ? AppColors.success.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.isCompleted ? AppColors.success.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(result.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: result.isCompleted ? AppColors.success : AppColors.textPrimary,
                    decoration: result.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  result.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: result.isCompleted
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.isCompleted ? '✓' : '+${result.xpReward}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: result.isCompleted ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboBonus() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6D00), Color(0xFFFF9100), Color(0xFFFFAB40)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💥', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text(
            'COMBO BONUS +50 XP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          SizedBox(width: 8),
          Text('💥', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildDailyCalendar(DailyQuestLog log, WidgetRef ref) {
    final calendar = ref.watch(loginCalendarProvider);

    return calendar.when(
      data: (logs) {
        if (logs.isEmpty) return const SizedBox();

        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử tuần này',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final day = startOfWeek.add(Duration(days: i));
                final dayStr = day.toIso8601String().substring(0, 10);
                final hasLog = logs.any((l) => l.logDate.toIso8601String().substring(0, 10) == dayStr);
                final isToday = day.day == now.day && day.month == now.month;
                final isFuture = day.isAfter(now);

                return Column(
                  children: [
                    Text(
                      _dayName(i),
                      style: TextStyle(
                        fontSize: 11,
                        color: isToday ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasLog
                            ? AppColors.success.withValues(alpha: 0.15)
                            : isFuture
                                ? Colors.grey.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          hasLog ? '✓' : isFuture ? '·' : '✗',
                          style: TextStyle(
                            fontSize: 16,
                            color: hasLog ? AppColors.success : isFuture ? Colors.grey.shade300 : Colors.red.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  String _dayName(int index) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return names[index];
  }
}
