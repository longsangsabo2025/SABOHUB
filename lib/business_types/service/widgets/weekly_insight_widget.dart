import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mood_provider.dart';
import '../providers/session_provider.dart';

/// Weekly Insight Widget for Service Manager — Wisey inspired
/// Shows team performance summary for the current week
class WeeklyInsightWidget extends ConsumerWidget {
  const WeeklyInsightWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionStatsAsync = ref.watch(sessionStatsProvider);
    final moodAsync = ref.watch(weeklyMoodSummaryProvider);
    final now = DateTime.now();
    final weekday = _weekdayLabel(now.weekday);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('📊', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insight tuần này',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$weekday, ${now.day}/${now.month} · Tuần ${_weekNumber(now)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row from session provider
            sessionStatsAsync.when(
              data: (stats) => _buildStatsRow(stats),
              loading: () => const Center(
                child: SizedBox(
                  height: 40,
                  child: CircularProgressIndicator(
                    color: AppColors.textSecondary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (_, __) => _buildFallbackStats(),
            ),

            const SizedBox(height: 12),

            // Mood summary row
            moodAsync.when(
              data: (logs) {
                if (logs.isEmpty) return const SizedBox.shrink();
                final great = logs.where((l) => l['mood'] == 'great').length;
                final okay = logs.where((l) => l['mood'] == 'okay').length;
                final tired = logs.where((l) => l['mood'] == 'tired').length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('😊', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Team mood 7 ngày: 😊 $great · 😐 $okay · 😩 $tired',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Action insight
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getInsightTip(now),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    final completedToday = (stats['completedToday'] as num?)?.toInt() ?? 0;
    final revenue = (stats['todayRevenue'] as num?)?.toDouble() ?? 0;
    final active = (stats['activeSessions'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '✅',
            label: 'Xong hôm nay',
            value: '$completedToday',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            emoji: '🎱',
            label: 'Đang chơi',
            value: '$active',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            emoji: '💰',
            label: 'Doanh thu',
            value: revenue >= 1000000
                ? '${(revenue / 1000000).toStringAsFixed(1)}M'
                : revenue >= 1000
                    ? '${(revenue / 1000).toStringAsFixed(0)}K'
                    : '${revenue.toStringAsFixed(0)}đ',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackStats() {
    return const Row(
      children: [
        Expanded(child: _StatCard(emoji: '✅', label: 'Xong hôm nay', value: '—', color: AppColors.success)),
        SizedBox(width: 8),
        Expanded(child: _StatCard(emoji: '🎱', label: 'Đang chơi', value: '—', color: AppColors.info)),
        SizedBox(width: 8),
        Expanded(child: _StatCard(emoji: '💰', label: 'Doanh thu', value: '—', color: AppColors.warning)),
      ],
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = {
      1: 'Thứ Hai',
      2: 'Thứ Ba',
      3: 'Thứ Tư',
      4: 'Thứ Năm',
      5: 'Thứ Sáu',
      6: 'Thứ Bảy',
      7: 'Chủ Nhật',
    };
    return labels[weekday] ?? 'Hôm nay';
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(startOfYear).inDays;
    return (diff / 7).ceil() + 1;
  }

  String _getInsightTip(DateTime now) {
    final weekday = now.weekday;
    if (weekday == 1) return 'Đầu tuần: đặt mục tiêu rõ ràng cho từng ca, phân công phù hợp năng lực.';
    if (weekday >= 5) return 'Cuối tuần cao điểm: tăng cường giám sát, đảm bảo trải nghiệm khách VIP.';
    return 'Theo dõi hiệu suất theo giờ để phát hiện điểm cần cải thiện sớm nhất.';
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
