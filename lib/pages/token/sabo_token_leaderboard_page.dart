import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/token/token_wallet.dart';
import '../../providers/token_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

// ─── Medal Colors ───────────────────────────────────────────────────────────
const _kGold = Color(0xFFFFD700);
const _kGoldDark = Color(0xFFDAA520);
const _kSilver = Color(0xFFC0C0C0);
const _kSilverDark = Color(0xFFA8A8A8);
const _kBronze = AppColors.tierBronze;
const _kBronzeDark = Color(0xFFB8690E);

/// Formats a number with comma separators: 12345 → "12,345"
String _fmt(double v) => NumberFormat('#,##0').format(v.toInt());

// ═══════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════

class SaboTokenLeaderboardPage extends ConsumerStatefulWidget {
  const SaboTokenLeaderboardPage({super.key});

  @override
  ConsumerState<SaboTokenLeaderboardPage> createState() =>
      _SaboTokenLeaderboardPageState();
}

class _SaboTokenLeaderboardPageState
    extends ConsumerState<SaboTokenLeaderboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedSort = 0; // 0 = balance, 1 = totalEarned

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedSort = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TokenWallet> _sortedList(List<TokenWallet> raw) {
    final copy = List<TokenWallet>.from(raw);
    if (_selectedSort == 1) {
      copy.sort((a, b) => b.totalEarned.compareTo(a.totalEarned));
    } else {
      copy.sort((a, b) => b.balance.compareTo(a.balance));
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(tokenLeaderboardProvider);
    final walletState = ref.watch(tokenWalletProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('🏆 Bảng Xếp Hạng SABO'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Chia sẻ BXH',
            onPressed: () {
              final wallets = ref.read(tokenLeaderboardProvider).value ?? [];
              final sorted = _sortedList(wallets);
              final top3 = sorted.take(3).toList();
              final text = StringBuffer('🏆 Bảng Xếp Hạng SABO Token\n\n');
              for (int i = 0; i < top3.length; i++) {
                final medals = ['🥇', '🥈', '🥉'];
                text.writeln('${medals[i]} ${top3[i].employeeName} — ${_fmt(top3[i].balance.toDouble())} SABO');
              }
              text.writeln('\n👉 Tham gia: https://sabohub.vercel.app\n#SABOHUB #TokenLeaderboard');
              Clipboard.setData(ClipboardData(text: text.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã copy BXH! Paste lên mạng xã hội 🎉'), backgroundColor: Colors.green),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(tokenLeaderboardProvider),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const _ShimmerLoading(),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(tokenLeaderboardProvider),
        ),
        data: (wallets) {
          if (wallets.isEmpty) return const _EmptyState();

          final sorted = _sortedList(wallets);
          final myWallet = walletState.wallet;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(tokenLeaderboardProvider);
              ref.read(tokenWalletProvider.notifier).refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ─── Header gradient ────────────────────────────
                SliverToBoxAdapter(
                  child: _HeaderGradient(
                    sorted: sorted,
                    sortIndex: _selectedSort,
                  ),
                ),

                // ─── Your rank card ─────────────────────────────
                if (myWallet != null)
                  SliverToBoxAdapter(
                    child: _YourRankCard(
                      wallet: myWallet,
                      rank: _findRank(sorted, myWallet.employeeId),
                      sortIndex: _selectedSort,
                    ),
                  ),

                // ─── Tabs: Balance / Total Earned ───────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    tabController: _tabController,
                  ),
                ),

                // ─── Full ranking list ──────────────────────────
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final wallet = sorted[index];
                        return _RankTile(
                          rank: index + 1,
                          wallet: wallet,
                          sortIndex: _selectedSort,
                          isCurrentUser:
                              myWallet?.employeeId == wallet.employeeId,
                        );
                      },
                      childCount: sorted.length,
                    ),
                  ),
                ),

                // bottom spacing
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  int _findRank(List<TokenWallet> sorted, String employeeId) {
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].employeeId == employeeId) return i + 1;
    }
    return -1;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER GRADIENT + PODIUM TOP 3
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderGradient extends StatelessWidget {
  final List<TokenWallet> sorted;
  final int sortIndex;

  const _HeaderGradient({required this.sorted, required this.sortIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // sparkle label
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✨ Top SABO Earners ✨',
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Podium: 2nd | 1st | 3rd
          if (sorted.length >= 3)
            _Podium(
              first: sorted[0],
              second: sorted[1],
              third: sorted[2],
              sortIndex: sortIndex,
            )
          else
            _SmallPodium(wallets: sorted, sortIndex: sortIndex),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PODIUM (3+ players)
// ═══════════════════════════════════════════════════════════════════════════

class _Podium extends StatelessWidget {
  final TokenWallet first;
  final TokenWallet second;
  final TokenWallet third;
  final int sortIndex;

  const _Podium({
    required this.first,
    required this.second,
    required this.third,
    required this.sortIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(
            child: _PodiumSlot(
              wallet: second,
              rank: 2,
              height: 90,
              medalColor: _kSilver,
              medalColorDark: _kSilverDark,
              sortIndex: sortIndex,
            ),
          ),
          const SizedBox(width: 8),
          // 1st place
          Expanded(
            child: _PodiumSlot(
              wallet: first,
              rank: 1,
              height: 120,
              medalColor: _kGold,
              medalColorDark: _kGoldDark,
              sortIndex: sortIndex,
            ),
          ),
          const SizedBox(width: 8),
          // 3rd place
          Expanded(
            child: _PodiumSlot(
              wallet: third,
              rank: 3,
              height: 70,
              medalColor: _kBronze,
              medalColorDark: _kBronzeDark,
              sortIndex: sortIndex,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final TokenWallet wallet;
  final int rank;
  final double height;
  final Color medalColor;
  final Color medalColorDark;
  final int sortIndex;

  const _PodiumSlot({
    required this.wallet,
    required this.rank,
    required this.height,
    required this.medalColor,
    required this.medalColorDark,
    required this.sortIndex,
  });

  @override
  Widget build(BuildContext context) {
    final value = sortIndex == 0 ? wallet.balance : wallet.totalEarned;
    final displayName =
        wallet.employeeName ?? 'Nhân viên ${wallet.employeeId.substring(0, 6)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for #1
        if (rank == 1)
          const Text('👑', style: TextStyle(fontSize: 28))
        else
          const SizedBox(height: 28),
        const SizedBox(height: 4),

        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: rank == 1 ? 72 : 58,
              height: rank == 1 ? 72 : 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 33 : 26,
                backgroundColor: medalColor.withValues(alpha: 0.2),
                backgroundImage: wallet.employeeAvatar != null
                    ? NetworkImage(wallet.employeeAvatar!)
                    : null,
                child: wallet.employeeAvatar == null
                    ? Text(
                        _initials(displayName),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: rank == 1 ? 22 : 18,
                        ),
                      )
                    : null,
              ),
            ),
            // Rank badge
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: medalColorDark,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name
        Text(
          _truncate(displayName, 12),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),

        // Balance
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on_rounded,
                color: _kGold, size: 14),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                _fmt(value),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: medalColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Podium bar
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.6),
                medalColor.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              _rankLabel(rank),
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _rankLabel(int r) {
    switch (r) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$r';
    }
  }
}

// Small podium for < 3 participants
class _SmallPodium extends StatelessWidget {
  final List<TokenWallet> wallets;
  final int sortIndex;

  const _SmallPodium({required this.wallets, required this.sortIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: wallets.asMap().entries.map((entry) {
          final i = entry.key;
          final w = entry.value;
          final colors = [
            (_kGold, _kGoldDark),
            (_kSilver, _kSilverDark),
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _PodiumSlot(
              wallet: w,
              rank: i + 1,
              height: i == 0 ? 100 : 80,
              medalColor: colors[i].$1,
              medalColorDark: colors[i].$2,
              sortIndex: sortIndex,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// YOUR RANK CARD
// ═══════════════════════════════════════════════════════════════════════════

class _YourRankCard extends StatelessWidget {
  final TokenWallet wallet;
  final int rank;
  final int sortIndex;

  const _YourRankCard({
    required this.wallet,
    required this.rank,
    required this.sortIndex,
  });

  @override
  Widget build(BuildContext context) {
    final value = sortIndex == 0 ? wallet.balance : wallet.totalEarned;
    final label = sortIndex == 0 ? 'Số dư' : 'Tổng thu nhập';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: rank > 0
                  ? Text(
                      '#$rank',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : Icon(Icons.remove_rounded,
                      color: Theme.of(context).colorScheme.surface54, size: 20),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hạng của bạn',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wallet.employeeName ?? 'Bạn',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface60,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: _kGold, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _fmt(value),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB BAR DELEGATE (sticky)
// ═══════════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _TabBarDelegate({required this.tabController});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: tabController,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 0,
          labelColor: Theme.of(context).colorScheme.surface,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: '💰 Theo Balance'),
            Tab(text: '📈 Theo Tổng Thu Nhập'),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabController != oldDelegate.tabController;
}

// ═══════════════════════════════════════════════════════════════════════════
// RANK LIST TILE
// ═══════════════════════════════════════════════════════════════════════════

class _RankTile extends StatelessWidget {
  final int rank;
  final TokenWallet wallet;
  final int sortIndex;
  final bool isCurrentUser;

  const _RankTile({
    required this.rank,
    required this.wallet,
    required this.sortIndex,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        wallet.employeeName ?? 'Nhân viên ${wallet.employeeId.substring(0, 6)}';
    final primaryValue = sortIndex == 0 ? wallet.balance : wallet.totalEarned;
    final secondaryValue = sortIndex == 0 ? wallet.totalEarned : wallet.balance;
    final secondaryLabel = sortIndex == 0 ? 'Tổng thu nhập' : 'Số dư';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: Center(child: _rankWidget(rank)),
          ),
          const SizedBox(width: 10),

          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: _avatarBg(rank),
            backgroundImage: wallet.employeeAvatar != null
                ? NetworkImage(wallet.employeeAvatar!)
                : null,
            child: wallet.employeeAvatar == null
                ? Text(
                    _initials(displayName),
                    style: TextStyle(
                      color: rank <= 3 ? Theme.of(context).colorScheme.surface : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isCurrentUser
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BẠN',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$secondaryLabel: ${_fmt(secondaryValue)} SABO',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Primary value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: _kGold, size: 16),
                  const SizedBox(width: 3),
                  Text(
                    _fmt(primaryValue),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: rank <= 3 ? _medalColor(rank) : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'SABO',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankWidget(int r) {
    if (r <= 3) {
      final icons = ['🥇', '🥈', '🥉'];
      return Text(icons[r - 1], style: const TextStyle(fontSize: 22));
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '#$r',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Color _avatarBg(int r) {
    switch (r) {
      case 1:
        return _kGold.withValues(alpha: 0.3);
      case 2:
        return _kSilver.withValues(alpha: 0.3);
      case 3:
        return _kBronze.withValues(alpha: 0.3);
      default:
        return AppColors.grey200;
    }
  }

  Color _medalColor(int r) {
    switch (r) {
      case 1:
        return _kGoldDark;
      case 2:
        return _kSilverDark;
      case 3:
        return _kBronzeDark;
      default:
        return AppColors.textPrimary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIMMER LOADING
// ═══════════════════════════════════════════════════════════════════════════

class _ShimmerLoading extends StatefulWidget {
  const _ShimmerLoading();

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      listenable: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header shimmer
              _shimmerBox(height: 260, radius: 0),
              const SizedBox(height: 16),
              // Card shimmer
              _shimmerBox(height: 80, margin: 16),
              const SizedBox(height: 8),
              // Tab bar shimmer
              _shimmerBox(height: 48, margin: 16),
              const SizedBox(height: 8),
              // List items
              for (int i = 0; i < 6; i++) ...[
                _shimmerBox(height: 72, margin: 16),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double height,
    double radius = 14,
    double margin = 0,
  }) {
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: margin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: const [
            AppColors.shimmerBase,
            AppColors.shimmerHighlight,
            AppColors.shimmerBase,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// AnimatedBuilder that works like AnimatedWidget
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  }) : super();

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) => builder(context, child);
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có dữ liệu xếp hạng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bảng xếp hạng sẽ xuất hiện khi nhân viên\nbắt đầu kiếm SABO Token.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR STATE
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải bảng xếp hạng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

String _truncate(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}…';
}
