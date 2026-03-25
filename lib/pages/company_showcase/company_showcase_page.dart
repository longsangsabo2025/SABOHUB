import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/token_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Company Showcase page — CEO shares company KPIs and highlights
/// to attract other businesses to the SABOHUB ecosystem.
class CompanyShowcasePage extends ConsumerStatefulWidget {
  const CompanyShowcasePage({super.key});

  @override
  ConsumerState<CompanyShowcasePage> createState() =>
      _CompanyShowcasePageState();
}

class _CompanyShowcasePageState extends ConsumerState<CompanyShowcasePage> {
  bool _isPublic = false;
  bool _showRevenue = false;
  bool _showEmployeeCount = true;
  bool _showHealthScore = true;
  bool _showTokenStats = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final ceoState = ref.watch(ceoProfileProvider);
    final companyRanking = ref.watch(companyRankingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Showcase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Chia sẻ Showcase',
            onPressed: () => _shareShowcase(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            _ShowcaseBanner(
              companyName: user?.companyName ?? 'Công ty của bạn',
              businessType: user?.businessType?.name ?? '',
              theme: theme,
            ),
            const SizedBox(height: 24),

            // Visibility toggle
            _buildVisibilityCard(theme),
            const SizedBox(height: 16),

            // KPI Highlights
            Text(
              'KPI Highlights',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // CEO Profile stats
            _buildCeoProfileSection(ceoState),
            const SizedBox(height: 16),

            // Company Ranking position
            companyRanking.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (rankings) {
                if (rankings.isEmpty) return const SizedBox.shrink();
                final myCompany = rankings.where(
                    (r) => r.companyId == user?.companyId);
                if (myCompany.isEmpty) return const SizedBox.shrink();
                final entry = myCompany.first;
                return _RankingCard(
                  rank: entry.rank,
                  totalCompanies: rankings.length,
                  totalXp: entry.totalXp,
                  showEmployeeCount: _showEmployeeCount,
                  employeeCount: entry.totalEmployees,
                  theme: theme,
                );
              },
            ),
            const SizedBox(height: 16),

            // Token Economy stats
            if (_showTokenStats) ...[
              Text(
                'Token Economy',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _TokenStatsSection(ref: ref),
            ],
            const SizedBox(height: 16),

            // Achievements Showcase
            Text(
              'Thành tựu nổi bật',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _AchievementsShowcase(ref: ref),
            const SizedBox(height: 24),

            // Call to Action
            _JoinCTA(theme: theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCeoProfileSection(CeoProfileState ceoState) {
    if (ceoState.isLoading) return const _LoadingCard();
    if (ceoState.error != null) return _ErrorCard(message: ceoState.error!);
    final profile = ceoState.profile;
    if (profile == null) return const _ErrorCard(message: 'Chưa có profile CEO');
    return _KpiGrid(
      items: [
        if (_showHealthScore)
          _KpiItem(
            icon: Icons.favorite,
            label: 'Health Score',
            value: '${profile.businessHealthScore}',
            color: _healthColor(profile.businessHealthScore.toInt()),
          ),
        _KpiItem(
          icon: Icons.star,
          label: 'CEO Level',
          value: 'Lv.${profile.level}',
          color: Colors.amber,
        ),
        _KpiItem(
          icon: Icons.local_fire_department,
          label: 'Streak',
          value: '${profile.streakDays} ngày',
          color: Colors.deepOrange,
        ),
        _KpiItem(
          icon: Icons.emoji_events,
          label: 'Uy Tín',
          value: '${profile.reputationPoints}',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildVisibilityCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Cài đặt hiển thị',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Showcase công khai'),
              subtitle: const Text('Cho phép doanh nghiệp khác xem'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Hiển thị doanh thu'),
              value: _showRevenue,
              onChanged: (v) => setState(() => _showRevenue = v),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Hiển thị số nhân viên'),
              value: _showEmployeeCount,
              onChanged: (v) => setState(() => _showEmployeeCount = v),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Hiển thị Health Score'),
              value: _showHealthScore,
              onChanged: (v) => setState(() => _showHealthScore = v),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Hiển thị Token Stats'),
              value: _showTokenStats,
              onChanged: (v) => setState(() => _showTokenStats = v),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Color _healthColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _shareShowcase(BuildContext context) {
    final user = ref.read(currentUserProvider);
    final companyName = user?.companyName ?? 'Công ty';
    final shareText =
        '🏢 $companyName đang sử dụng SABOHUB!\n\n'
        '🚀 Quản lý doanh nghiệp thông minh với Gamification & Token Economy\n'
        '🎮 Quest System, Leaderboard, NFT Achievement\n'
        '💰 Earn SABO Token cho mỗi hoạt động\n\n'
        '👉 Tham gia ngay: https://sabohub.vercel.app\n'
        '#SABOHUB #BusinessGamification #Web3';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã copy nội dung chia sẻ! Paste lên mạng xã hội 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ========== Sub-widgets ==========

class _ShowcaseBanner extends StatelessWidget {
  final String companyName;
  final String businessType;
  final ThemeData theme;

  const _ShowcaseBanner({
    required this.companyName,
    required this.businessType,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(180),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business, color: Theme.of(context).colorScheme.surface, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (businessType.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          businessType.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.verified, color: Theme.of(context).colorScheme.surface70, size: 16),
              SizedBox(width: 4),
              Text(
                'Powered by SABOHUB Ecosystem',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface.withAlpha(200),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiItem> items;
  const _KpiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: items.map((item) => _KpiCard(item: item)).toList(),
    );
  }
}

class _KpiItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: item.color.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(item.icon, color: item.color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final int rank;
  final int totalCompanies;
  final int totalXp;
  final bool showEmployeeCount;
  final int employeeCount;
  final ThemeData theme;

  const _RankingCard({
    required this.rank,
    required this.totalCompanies,
    required this.totalXp,
    required this.showEmployeeCount,
    required this.employeeCount,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final medal = rank <= 3
        ? ['', '🥇', '🥈', '🥉'][rank]
        : '#$rank';

    return Card(
      elevation: rank <= 3 ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: rank <= 3
            ? BorderSide(color: theme.colorScheme.primary.withAlpha(77))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              medal,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xếp hạng Guild War',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Top $rank / $totalCompanies công ty',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalXp XP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (showEmployeeCount)
                  Text(
                    '$employeeCount nhân viên',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenStatsSection extends StatelessWidget {
  final WidgetRef ref;
  const _TokenStatsSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(tokenWalletProvider);
    if (walletState.isLoading) return const _LoadingCard();
    if (walletState.error != null) return _ErrorCard(message: walletState.error!);
    final wallet = walletState.wallet;
    if (wallet == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có ví SABO Token'),
        ),
      );
    }
    return _KpiGrid(
      items: [
        _KpiItem(
          icon: Icons.account_balance_wallet,
          label: 'Balance',
          value: '${wallet.balance} SABO',
          color: Colors.blue,
        ),
        _KpiItem(
          icon: Icons.trending_up,
          label: 'Tổng kiếm được',
          value: '${wallet.totalEarned} SABO',
          color: Colors.green,
        ),
        _KpiItem(
          icon: Icons.shopping_cart,
          label: 'Đã chi tiêu',
          value: '${wallet.totalSpent} SABO',
          color: Colors.orange,
        ),
        _KpiItem(
          icon: Icons.download,
          label: 'Đã rút on-chain',
          value: '${wallet.totalWithdrawn} SABO',
          color: Colors.teal,
        ),
      ],
    );
  }
}

class _AchievementsShowcase extends StatelessWidget {
  final WidgetRef ref;
  const _AchievementsShowcase({required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ceoState = ref.watch(ceoProfileProvider);
    if (ceoState.isLoading) return const _LoadingCard();
    final profile = ceoState.profile;
    if (profile == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có thành tựu'),
        ),
      );
    }
    final badges = profile.activeBadges;
    if (badges.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.grey[400]),
              const SizedBox(width: 8),
              const Text('Hoàn thành quest để nhận thành tựu!'),
            ],
          ),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges.take(6).map((badge) {
        return Chip(
          avatar: Icon(
            Icons.military_tech,
            color: theme.colorScheme.primary,
            size: 18,
          ),
          label: Text(badge),
          backgroundColor:
              theme.colorScheme.primaryContainer.withAlpha(100),
        );
      }).toList(),
    );
  }
}

class _JoinCTA extends StatelessWidget {
  final ThemeData theme;
  const _JoinCTA({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withAlpha(60),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.rocket_launch, size: 48, color: Colors.deepPurple),
          const SizedBox(height: 12),
          Text(
            'Bạn cũng muốn Gamify doanh nghiệp?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'SABOHUB giúp doanh nghiệp tăng năng suất nhân viên lên 40% '
            'với Quest System, Token Economy & NFT Achievement.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(
                text: 'https://sabohub.vercel.app',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã copy link! Chia sẻ cho bạn bè 🚀'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy link đăng ký'),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
