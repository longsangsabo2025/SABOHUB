import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/token/nft_achievement.dart';
import '../../providers/token_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class SaboAchievementsPage extends ConsumerStatefulWidget {
  const SaboAchievementsPage({super.key});

  @override
  ConsumerState<SaboAchievementsPage> createState() =>
      _SaboAchievementsPageState();
}

class _SaboAchievementsPageState extends ConsumerState<SaboAchievementsPage> {
  AchievementRarity? _filterRarity;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final wallet = ref.read(tokenWalletProvider).wallet;
      if (wallet?.walletAddress != null && wallet!.walletAddress!.isNotEmpty) {
        ref
            .read(nftAchievementProvider.notifier)
            .loadAchievements(wallet.walletAddress!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nftState = ref.watch(nftAchievementProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Thành Tích NFT'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final wallet = ref.read(tokenWalletProvider).wallet;
              if (wallet?.walletAddress != null) {
                ref
                    .read(nftAchievementProvider.notifier)
                    .refresh(wallet!.walletAddress!);
              }
            },
          ),
        ],
      ),
      body: nftState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : nftState.error != null
              ? _buildError(nftState.error!, theme)
              : _buildContent(nftState, theme, isDark),
    );
  }

  Widget _buildError(String error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Không thể tải thành tích',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              final wallet = ref.read(tokenWalletProvider).wallet;
              if (wallet?.walletAddress != null) {
                ref
                    .read(nftAchievementProvider.notifier)
                    .loadAchievements(wallet!.walletAddress!);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      NftAchievementState nftState, ThemeData theme, bool isDark) {
    final summary = nftState.summary;
    final allTypes = nftState.allTypes;

    // Filter achievements
    final filtered = _filterRarity != null
        ? summary.achievements
            .where((a) => a.rarity == _filterRarity)
            .toList()
        : summary.achievements;

    return RefreshIndicator(
      onRefresh: () async {
        final wallet = ref.read(tokenWalletProvider).wallet;
        if (wallet?.walletAddress != null) {
          await ref
              .read(nftAchievementProvider.notifier)
              .refresh(wallet!.walletAddress!);
        }
      },
      child: CustomScrollView(
        slivers: [
          // ── Summary Hero Card ──
          SliverToBoxAdapter(
            child: _buildSummaryCard(summary, theme, isDark),
          ),

          // ── Rarity Breakdown ──
          SliverToBoxAdapter(
            child: _buildRarityBreakdown(summary, theme),
          ),

          // ── Filter Chips ──
          SliverToBoxAdapter(
            child: _buildFilterChips(theme),
          ),

          // ── Achievement Grid or Empty State ──
          if (filtered.isEmpty && summary.total == 0)
            SliverToBoxAdapter(
              child: _buildEmptyState(allTypes, theme, isDark),
            )
          else if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Không có thành tích ${_filterRarity?.label ?? ''} nào',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildAchievementCard(filtered[index], theme, isDark),
                  childCount: filtered.length,
                ),
              ),
            ),

          // ── All Available Types ──
          if (allTypes.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildAvailableTypes(allTypes, summary, theme, isDark),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Summary Hero
  // ──────────────────────────────────────────────

  Widget _buildSummaryCard(
      AchievementSummary summary, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Color(0xFF1A237E), Color(0xFF311B92)]
              : [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 28)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bộ Sưu Tập NFT',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Soulbound — Không thể chuyển nhượng',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.surface70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${summary.total}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Completion bar
          if (summary.total > 0) ...[
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: summary.completionPercent / 100,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(Colors.amberAccent),
              ),
            ),
            SizedBox(height: 6),
            Text(
              '${summary.completionPercent.toStringAsFixed(0)}% hoàn thành',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.surface60),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Rarity Breakdown
  // ──────────────────────────────────────────────

  Widget _buildRarityBreakdown(AchievementSummary summary, ThemeData theme) {
    if (summary.total == 0) return const SizedBox.shrink();

    final rarities = [
      (AchievementRarity.common, summary.common),
      (AchievementRarity.rare, summary.rare),
      (AchievementRarity.epic, summary.epic),
      (AchievementRarity.legendary, summary.legendary),
      (AchievementRarity.mythic, summary.mythic),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: rarities
            .map((entry) => Expanded(
                  child: _rarityPill(entry.$1, entry.$2, theme),
                ))
            .toList(),
      ),
    );
  }

  Widget _rarityPill(AchievementRarity rarity, int count, ThemeData theme) {
    final color = Color(rarity.colorValue);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(rarity.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            rarity.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Filter Chips
  // ──────────────────────────────────────────────

  Widget _buildFilterChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(null, 'Tất cả', theme),
            const SizedBox(width: 6),
            ...AchievementRarity.values.map(
              (r) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _filterChip(r, '${r.emoji} ${r.label}', theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
      AchievementRarity? rarity, String label, ThemeData theme) {
    final selected = _filterRarity == rarity;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filterRarity = rarity),
      selectedColor: rarity != null
          ? Color(rarity.colorValue).withValues(alpha: 0.2)
          : theme.colorScheme.primaryContainer,
      checkmarkColor: rarity != null
          ? Color(rarity.colorValue)
          : theme.colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Achievement Card
  // ──────────────────────────────────────────────

  Widget _buildAchievementCard(
      NftAchievement nft, ThemeData theme, bool isDark) {
    final color = Color(nft.rarity.colorValue);
    final fmt = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showAchievementDetail(nft, theme),
        child: Column(
          children: [
            // Rarity banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Text(
                '${nft.rarity.emoji} ${nft.rarity.label}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),

            // Badge icon
            Expanded(
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                        color: color.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _badgeEmoji(nft.name),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
              ),
            ),

            // Name & date
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Column(
                children: [
                  Text(
                    nft.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#${nft.tokenId} · ${fmt.format(nft.mintedAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 9,
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

  // ──────────────────────────────────────────────
  //  Empty State
  // ──────────────────────────────────────────────

  Widget _buildEmptyState(
      List<AchievementType> allTypes, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: const Center(
              child: Text('🎖️', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thành tích nào',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hoàn thành các nhiệm vụ và quest để nhận\nNFT thành tích soulbound!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (allTypes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '${allTypes.length} thành tích đang chờ bạn 🔓',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Available Types Reference
  // ──────────────────────────────────────────────

  Widget _buildAvailableTypes(List<AchievementType> types,
      AchievementSummary summary, ThemeData theme, bool isDark) {
    // Mark which types user already owns
    final ownedTypeIds = summary.achievements.map((a) => a.typeId).toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '📋 Danh sách thành tích (${types.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...types.map((t) {
            final owned = ownedTypeIds.contains(t.typeId);
            final color = Color(t.rarity.colorValue);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: owned
                    ? color.withValues(alpha: 0.08)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                border: owned
                    ? Border.all(color: color.withValues(alpha: 0.4))
                    : null,
              ),
              child: Row(
                children: [
                  // Status icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: owned
                          ? color.withValues(alpha: 0.2)
                          : theme.colorScheme.surface,
                    ),
                    child: Center(
                      child: owned
                          ? Icon(Icons.check_circle, color: color, size: 20)
                          : Icon(Icons.lock_outline,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                              size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: owned
                                ? null
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          '${t.rarity.emoji} ${t.rarity.label} · ${t.supplyText}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (owned)
                    const Text('✅', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Achievement Detail Dialog
  // ──────────────────────────────────────────────

  void _showAchievementDetail(NftAchievement nft, ThemeData theme) {
    final color = Color(nft.rarity.colorValue);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Text(
                    _badgeEmoji(nft.name),
                    style: TextStyle(fontSize: 48),
                  ),
                  SizedBox(height: 8),
                  Text(
                    nft.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${nft.rarity.emoji} ${nft.rarity.label}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.surface, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _detailRow('Token ID', '#${nft.tokenId}', theme),
                  _detailRow('Type ID', '#${nft.typeId}', theme),
                  _detailRow('Ngày nhận', fmt.format(nft.mintedAt), theme),
                  _detailRow(
                      'Loại', 'Soulbound (ERC-721)', theme),
                  const SizedBox(height: 4),
                  Text(
                    '🔒 NFT này không thể chuyển nhượng',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          Text(value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────

  /// Map achievement name to a badge emoji
  String _badgeEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('founder') || n.contains('sáng lập')) return '👑';
    if (n.contains('commander') || n.contains('chỉ huy')) return '⚔️';
    if (n.contains('speed') || n.contains('tốc')) return '⚡';
    if (n.contains('recruit') || n.contains('tuyển')) return '🤝';
    if (n.contains('zero') || n.contains('defect')) return '🎯';
    if (n.contains('sắt') || n.contains('iron')) return '🛡️';
    if (n.contains('đa nhân') || n.contains('multi')) return '🃏';
    if (n.contains('doanh thu') || n.contains('revenue')) return '💰';
    if (n.contains('phượng') || n.contains('phoenix')) return '🔥';
    if (n.contains('người sắt') || n.contains('iron man')) return '🦾';
    return '🏅';
  }
}
