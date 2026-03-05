import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/gamification_provider.dart';

class LeaderboardPage extends ConsumerWidget {
  LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bảng Xếp Hạng CEO'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final actions = ref.read(gamificationActionsProvider);
                await actions.refreshLeaderboards();
                ref.invalidate(globalLeaderboardProvider);
                ref.invalidate(monthlyLeaderboardProvider);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.emoji_events), text: 'Tổng'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Tháng'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalTab(),
            _MonthlyTab(),
          ],
        ),
      ),
    );
  }
}

class _GlobalTab extends ConsumerWidget {
  const _GlobalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(globalLeaderboardProvider);

    return lbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (entries) {
        if (entries.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (ctx, i) => _CeoRankTile(data: entries[i], isMonthly: false),
        );
      },
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(monthlyLeaderboardProvider);

    return lbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (entries) {
        if (entries.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (ctx, i) => _CeoRankTile(data: entries[i], isMonthly: true),
        );
      },
    );
  }
}

class _CeoRankTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMonthly;

  const _CeoRankTile({required this.data, required this.isMonthly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rank = (data['rank'] as num).toInt();
    final name = data['full_name'] as String? ?? '';
    final company = data['company_name'] as String? ?? '';
    final level = data['level'] as int? ?? 0;
    final title = data['current_title'] as String? ?? '';
    final isTop3 = rank <= 3;

    final xpLabel = isMonthly
        ? '${data['monthly_xp'] ?? 0} XP'
        : '${data['total_xp'] ?? 0} XP';

    const medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: isTop3 ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isTop3
            ? BorderSide(color: theme.colorScheme.primary.withAlpha(77))
            : BorderSide.none,
      ),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: isTop3
                ? Text(medals[rank]!, style: const TextStyle(fontSize: 24))
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$title · Lv.$level · $company',
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          xpLabel,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
