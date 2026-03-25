import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';

class CompanyRankingPage extends ConsumerWidget {
  const CompanyRankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(companyRankingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guild War'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Cập nhật xếp hạng',
            onPressed: () async {
              final actions = ref.read(gamificationActionsProvider);
              await actions.refreshLeaderboards();
              ref.invalidate(companyRankingProvider);
            },
          ),
        ],
      ),
      body: rankingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (companies) {
          if (companies.isEmpty) {
            return const Center(
              child: Text('Chưa có dữ liệu xếp hạng'),
            );
          }

          return CustomScrollView(
            slivers: [
              if (companies.length >= 3)
                SliverToBoxAdapter(child: _TopThreePodium(companies: companies, theme: theme)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _CompanyRankCard(entry: companies[i]),
                    childCount: companies.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopThreePodium extends StatelessWidget {
  final List<CompanyRankEntry> companies;
  final ThemeData theme;

  const _TopThreePodium({required this.companies, required this.theme});

  @override
  Widget build(BuildContext context) {
    const medals = ['', '🥇', '🥈', '🥉'];
    const heights = [0.0, 120.0, 100.0, 80.0];
    const order = [1, 0, 2]; // 2nd, 1st, 3rd

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((idx) {
          if (idx >= companies.length) return const SizedBox.shrink();
          final entry = companies[idx];
          final rank = idx + 1;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  medals[rank],
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.companyName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.totalXp} XP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: heights[rank],
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: rank == 1
                          ? [Colors.amber.shade400, Colors.amber.shade700]
                          : rank == 2
                              ? [Colors.grey.shade300, Colors.grey.shade500]
                              : [Colors.brown.shade200, Colors.brown.shade400],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompanyRankCard extends StatelessWidget {
  final CompanyRankEntry entry;

  const _CompanyRankCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = entry.rank <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isTop3 ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTop3
            ? BorderSide(color: theme.colorScheme.primary.withAlpha(77))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTop3 ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.companyName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.businessType != null)
                    Text(
                      entry.businessType!,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalXp} XP',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniStat(icon: Icons.people, value: '${entry.totalEmployees}'),
                    const SizedBox(width: 8),
                    _MiniStat(icon: Icons.favorite, value: entry.avgHealth.toStringAsFixed(0)),
                    const SizedBox(width: 8),
                    _MiniStat(icon: Icons.star, value: entry.avgStaffRating.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 2),
        Text(value, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
