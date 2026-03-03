import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StreakCounter extends StatelessWidget {
  final int streakDays;
  final int longestStreak;
  final int freezeRemaining;
  final bool compact;

  const StreakCounter({
    super.key,
    required this.streakDays,
    this.longestStreak = 0,
    this.freezeRemaining = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: streakDays > 0
              ? [const Color(0xFFFF6D00), const Color(0xFFFF9100)]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            streakDays > 0 ? '🔥' : '❄️',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '$streakDays',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                streakDays > 0 ? '🔥' : '❄️',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streakDays ngày liên tiếp',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Kỷ lục: $longestStreak ngày',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (freezeRemaining > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🛡️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '$freezeRemaining',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWeekDots(),
        ],
      ),
    );
  }

  Widget _buildWeekDots() {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final todayIndex = DateTime.now().weekday - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final isActive = i <= todayIndex && streakDays > (todayIndex - i);
        final isToday = i == todayIndex;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFFFF6D00)
                    : isToday
                        ? const Color(0xFFFF6D00).withValues(alpha: 0.2)
                        : Colors.grey.shade100,
                border: isToday
                    ? Border.all(color: const Color(0xFFFF6D00), width: 2)
                    : null,
              ),
              child: Center(
                child: isActive
                    ? const Text('✓',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              days[i],
              style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFFFF6D00) : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}
