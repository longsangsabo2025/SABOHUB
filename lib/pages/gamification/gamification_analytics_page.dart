import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';

class GamificationAnalyticsPage extends ConsumerWidget {
  const GamificationAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(engagementMetricsProvider);
              ref.invalidate(xpAnalyticsProvider);
              ref.invalidate(questDropoffProvider);
              ref.invalidate(levelDistributionProvider);
              ref.invalidate(xpTrendProvider);
              ref.invalidate(weeklySummaryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(engagementMetricsProvider);
          ref.invalidate(xpAnalyticsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _WeeklySummaryCard(),
            SizedBox(height: 16),
            _EngagementGrid(),
            SizedBox(height: 16),
            _XpTrendChart(),
            SizedBox(height: 16),
            _XpBreakdownCard(),
            SizedBox(height: 16),
            _LevelDistributionCard(),
            SizedBox(height: 16),
            _QuestDropoffCard(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Weekly Summary
// ──────────────────────────────────────────────

class _WeeklySummaryCard extends ConsumerWidget {
  const _WeeklySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklySummaryProvider);
    final theme = Theme.of(context);

    return summaryAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(error: '$e'),
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.summarize, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Tổng kết tuần',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryStat(value: '${summary.xpEarned}', label: 'XP', icon: '⚡'),
                    _SummaryStat(value: '${summary.questsCompleted}', label: 'Quests', icon: '⚔️'),
                    _SummaryStat(value: '${summary.achievementsUnlocked}', label: 'Thành tựu', icon: '🏅'),
                    _SummaryStat(value: '${summary.streakDays}d', label: 'Streak', icon: '🔥'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summary.levelProgress,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (summary.topSource.isNotEmpty)
                  Text(
                    'Top nguồn XP: ${summary.topSource}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  final String icon;

  const _SummaryStat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Engagement Grid
// ──────────────────────────────────────────────

class _EngagementGrid extends ConsumerWidget {
  const _EngagementGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(engagementMetricsProvider);

    return metricsAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(error: '$e'),
      data: (metrics) {
        final keyMetrics = metrics.where((m) => [
          'total_ceos', 'active_today', 'dau_rate', 'wau_rate',
          'avg_streak', 'avg_level', 'xp_today', 'quests_completed',
          'avg_health', 'season_participants',
        ].contains(m.name)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Engagement', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: keyMetrics.length,
              itemBuilder: (ctx, i) {
                final m = keyMetrics[i];
                return _MetricTile(
                  value: _formatValue(m.name, m.value),
                  label: m.detail,
                  color: _colorForMetric(m.name),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatValue(String name, double value) {
    if (name.endsWith('_rate')) return '${value.toStringAsFixed(1)}%';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Color _colorForMetric(String name) {
    const colors = {
      'total_ceos': Color(0xFF1565C0),
      'active_today': Color(0xFF2E7D32),
      'dau_rate': Color(0xFF00838F),
      'wau_rate': Color(0xFF6A1B9A),
      'avg_streak': Color(0xFFE65100),
      'avg_level': Color(0xFF37474F),
      'xp_today': Color(0xFFF9A825),
      'quests_completed': Color(0xFF880E4F),
      'avg_health': Color(0xFF388E3C),
      'season_participants': Color(0xFF5C6BC0),
    };
    return colors[name] ?? const Color(0xFF455A64);
  }
}

class _MetricTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// XP Trend (simple bar chart)
// ──────────────────────────────────────────────

class _XpTrendChart extends ConsumerWidget {
  const _XpTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(xpTrendProvider);
    final theme = Theme.of(context);

    return trendAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(error: '$e'),
      data: (points) {
        if (points.isEmpty) return const SizedBox.shrink();
        final maxXp = points.map((p) => p.totalXp).reduce((a, b) => a > b ? a : b);
        final safeMax = maxXp > 0 ? maxXp : 1;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('XP Trend (14 ngày)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: points.map((p) {
                      final h = (p.totalXp / safeMax * 100).clamp(2.0, 100.0);
                      final isToday = p.day.day == DateTime.now().day && p.day.month == DateTime.now().month;
                      return Expanded(
                        child: Tooltip(
                          message: '${p.day.day}/${p.day.month}: ${p.totalXp} XP',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (p.totalXp > 0)
                                Text(
                                  '${p.totalXp}',
                                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                                ),
                              Container(
                                height: h,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isToday ? theme.colorScheme.primary : theme.colorScheme.primary.withAlpha(128),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.day.day}',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? theme.colorScheme.primary : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// XP Breakdown
// ──────────────────────────────────────────────

class _XpBreakdownCard extends ConsumerWidget {
  const _XpBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpAsync = ref.watch(xpAnalyticsProvider);
    final theme = Theme.of(context);

    return xpAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(error: '$e'),
      data: (analytics) {
        if (analytics.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Chưa có dữ liệu XP')),
            ),
          );
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phân bổ XP (30 ngày)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...analytics.map((a) => _XpSourceRow(analytics: a)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _XpSourceRow extends StatelessWidget {
  final XpAnalytics analytics;

  const _XpSourceRow({required this.analytics});

  static const _sourceEmoji = {
    'quest': '⚔️', 'daily': '📋', 'weekly': '🏆', 'boss': '🏰',
    'achievement': '🎖️', 'login': '🔑', 'bonus': '🎁', 'multiplier': '✨',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Text(_sourceEmoji[analytics.sourceType] ?? '📊', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  analytics.sourceType.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
              Text(
                '${analytics.totalXp} XP',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 45,
                child: Text(
                  '${analytics.percentage}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (analytics.percentage / 100).clamp(0, 1),
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Level Distribution
// ──────────────────────────────────────────────

class _LevelDistributionCard extends ConsumerWidget {
  const _LevelDistributionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distAsync = ref.watch(levelDistributionProvider);
    final theme = Theme.of(context);

    const tierColors = [
      Color(0xFF78909C), Color(0xFF1565C0), Color(0xFF2E7D32),
      Color(0xFF00838F), Color(0xFF6A1B9A), Color(0xFFE65100),
    ];

    return distAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(error: '$e'),
      data: (dist) {
        if (dist.isEmpty) return const SizedBox.shrink();

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phân bố Level', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...List.generate(dist.length, (i) {
                  final d = dist[i];
                  final color = i < tierColors.length ? tierColors[i] : Colors.grey;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(d.levelRange, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (d.percentage / 100).clamp(0, 1),
                              minHeight: 16,
                              backgroundColor: color.withAlpha(25),
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${d.playerCount} (${d.percentage}%)',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Quest Drop-off
// ──────────────────────────────────────────────

class _QuestDropoffCard extends ConsumerWidget {
  const _QuestDropoffCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dropAsync = ref.watch(questDropoffProvider);
    final theme = Theme.of(context);

    return dropAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(error: '$e'),
      data: (drops) {
        if (drops.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Không có quest bị bỏ dở')),
            ),
          );
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quest Drop-off', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Quests bị bỏ dở (>14 ngày)', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 12),
                ...drops.take(10).map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.questName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            Text(
                              '${d.startedCount} bắt đầu · ${d.completedCount} hoàn thành · ${d.abandonedCount} bỏ dở',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: d.dropoffRate > 50
                              ? Colors.red.withAlpha(25)
                              : d.dropoffRate > 25
                                  ? Colors.orange.withAlpha(25)
                                  : Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${d.dropoffRate}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: d.dropoffRate > 50 ? Colors.red : d.dropoffRate > 25 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Shared Widgets
// ──────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Lỗi: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
