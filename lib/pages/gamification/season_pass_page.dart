import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';

class SeasonPassPage extends ConsumerWidget {
  const SeasonPassPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passAsync = ref.watch(seasonPassProvider);
    final tiersAsync = ref.watch(seasonTiersProvider);
    final hasPremiumAsync = ref.watch(hasPremiumPassProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Season Pass'),
        actions: [
          passAsync.whenOrNull(
            data: (info) => info != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        '${info.daysRemaining} ngày',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: info.daysRemaining < 7 ? Colors.red : null,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ].whereType<Widget>().toList(),
      ),
      body: passAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (info) {
          if (info == null) {
            return const Center(
              child: Text('Không có season nào đang hoạt động'),
            );
          }

          final hasPremium = hasPremiumAsync is AsyncData<bool> ? hasPremiumAsync.value : false;

          return tiersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
            data: (tiers) => _SeasonPassContent(info: info, tiers: tiers, hasPremium: hasPremium),
          );
        },
      ),
    );
  }
}

class _SeasonPassContent extends ConsumerWidget {
  final SeasonPassInfo info;
  final List<SeasonPassTier> tiers;
  final bool hasPremium;

  const _SeasonPassContent({required this.info, required this.tiers, this.hasPremium = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, theme)),
        SliverToBoxAdapter(child: _buildProgressBar(theme)),
        if (!hasPremium)
          SliverToBoxAdapter(child: _buildPremiumBanner(context, ref, theme)),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) => _TierCard(
                tier: tiers[index],
                seasonXp: info.seasonXp,
                isClaimed: info.claimedTiers.contains(tiers[index].tier),
                onClaim: () async {
                  final actions = ref.read(gamificationActionsProvider);
                  final result = await actions.claimSeasonTier(tiers[index].tier);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: result.success ? Colors.green : Colors.orange,
                      ),
                    );
                  }
                },
              ),
              childCount: tiers.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBanner(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFF57C00)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Text('👑', style: TextStyle(fontSize: 28)),
        title: const Text(
          'Premium Pass',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Mở khóa rewards đặc biệt! 200 Uy Tín',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: FilledButton(
          onPressed: () async {
            final actions = ref.read(gamificationActionsProvider);
            final result = await actions.buyPremiumPass();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message),
                  backgroundColor: result.success ? Colors.green : Colors.orange,
                ),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange.shade800,
          ),
          child: const Text('Mua'),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.seasonName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Season ${info.seasonNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'x${info.bonusMultiplier}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatBadge(label: 'Season XP', value: '${info.seasonXp}'),
              _StatBadge(label: 'Tier', value: '${info.currentTier}/10'),
              _StatBadge(label: 'Còn lại', value: '${info.daysRemaining}d'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final maxXp = tiers.isEmpty ? 1 : tiers.last.xpRequired;
    final progress = (info.seasonXp / maxXp).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${info.seasonXp} / $maxXp Season XP',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final SeasonPassTier tier;
  final int seasonXp;
  final bool isClaimed;
  final VoidCallback onClaim;

  const _TierCard({
    required this.tier,
    required this.seasonXp,
    required this.isClaimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = seasonXp >= tier.xpRequired;
    final canClaim = isUnlocked && !isClaimed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isClaimed
            ? BorderSide(color: Colors.green.shade300, width: 2)
            : canClaim
                ? BorderSide(color: theme.colorScheme.primary, width: 2)
                : BorderSide.none,
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isClaimed
                ? Colors.green.withAlpha(51)
                : isUnlocked
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: isClaimed
                ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                : Text(
                    tier.iconEmoji,
                    style: TextStyle(
                      fontSize: 22,
                      color: isUnlocked ? null : Colors.grey,
                    ),
                  ),
          ),
        ),
        title: Text(
          'Tier ${tier.tier}: ${tier.rewardName}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${tier.xpRequired} Season XP',
          style: TextStyle(
            color: isUnlocked ? theme.colorScheme.primary : Colors.grey,
          ),
        ),
        trailing: canClaim
            ? FilledButton(
                onPressed: onClaim,
                child: const Text('Nhận'),
              )
            : isClaimed
                ? const Icon(Icons.check, color: Colors.green)
                : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
}
