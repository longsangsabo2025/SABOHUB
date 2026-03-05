import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/token/token_models.dart';
import '../../providers/token_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

// ──────────────────────────────────────────────
// SABO Token Analytics Dashboard (CEO/Manager)
// ──────────────────────────────────────────────

class SaboTokenAnalyticsPage extends ConsumerStatefulWidget {
  SaboTokenAnalyticsPage({super.key});

  @override
  ConsumerState<SaboTokenAnalyticsPage> createState() =>
      _SaboTokenAnalyticsPageState();
}

class _SaboTokenAnalyticsPageState
    extends ConsumerState<SaboTokenAnalyticsPage> {
  final _numberFormat = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(companyTokenStatsProvider);
    final earningAsync = ref.watch(tokenEarningBreakdownProvider);
    final flowAsync = ref.watch(tokenDailyFlowProvider);
    final topEarnersAsync = ref.watch(tokenTopEarnersProvider);
    final storeStatsAsync = ref.watch(tokenStoreStatsProvider);
    final activityAsync = ref.watch(tokenRecentActivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Token Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(companyTokenStatsProvider);
              ref.invalidate(tokenEarningBreakdownProvider);
              ref.invalidate(tokenDailyFlowProvider);
              ref.invalidate(tokenTopEarnersProvider);
              ref.invalidate(tokenStoreStatsProvider);
              ref.invalidate(tokenRecentActivityProvider);
            },
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(companyTokenStatsProvider);
          ref.invalidate(tokenEarningBreakdownProvider);
          ref.invalidate(tokenDailyFlowProvider);
          ref.invalidate(tokenTopEarnersProvider);
          ref.invalidate(tokenStoreStatsProvider);
          ref.invalidate(tokenRecentActivityProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Overview Stats ──
              _buildOverviewSection(theme, statsAsync),
              const SizedBox(height: 24),

              // ── Daily Flow Chart ──
              _buildSectionHeader(theme, '📈 Dòng Token 30 ngày', 'Earn vs Spend'),
              const SizedBox(height: 12),
              _buildDailyFlowChart(theme, flowAsync),
              const SizedBox(height: 24),

              // ── Earning Breakdown ──
              _buildSectionHeader(theme, '🎯 Phân Bổ Thu Nhập', '30 ngày qua'),
              const SizedBox(height: 12),
              _buildEarningBreakdown(theme, earningAsync),
              const SizedBox(height: 24),

              // ── Top Earners ──
              _buildSectionHeader(theme, '🏆 Top Earners', 'Tổng thu nhập'),
              const SizedBox(height: 12),
              _buildTopEarners(theme, topEarnersAsync),
              const SizedBox(height: 24),

              // ── Store Stats ──
              _buildSectionHeader(theme, '🛒 Store Analytics', '30 ngày qua'),
              const SizedBox(height: 12),
              _buildStoreStats(theme, storeStatsAsync),
              const SizedBox(height: 24),

              // ── Recent Activity ──
              _buildSectionHeader(theme, '⚡ Hoạt Động Gần Đây', '20 giao dịch mới nhất'),
              const SizedBox(height: 12),
              _buildRecentActivity(theme, activityAsync),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Overview Stats Hero ─────────────────────────────────────────────────

  Widget _buildOverviewSection(
    ThemeData theme,
    AsyncValue<
            ({
              double totalCirculating,
              int totalWallets,
              double totalEarned,
              double totalSpent,
            })>
        statsAsync,
  ) {
    return statsAsync.when(
      loading: () => _buildLoadingCard(height: 180),
      error: (e, _) => _buildErrorCard('Không tải được thống kê: $e'),
      data: (stats) {
        final velocity = stats.totalEarned > 0
            ? (stats.totalSpent / stats.totalEarned * 100)
            : 0.0;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🪙', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Text(
                    'SABO Token Economy',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      '💰 Lưu Hành',
                      _numberFormat.format(stats.totalCirculating.toInt()),
                      'SABO',
                      Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatTile(
                      '👥 Ví Hoạt Động',
                      stats.totalWallets.toString(),
                      'wallets',
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      '📈 Tổng Phát Thưởng',
                      _numberFormat.format(stats.totalEarned.toInt()),
                      'SABO',
                      AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatTile(
                      '📉 Tổng Chi Tiêu',
                      _numberFormat.format(stats.totalSpent.toInt()),
                      'SABO',
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Velocity indicator
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      velocity > 70
                          ? Icons.trending_up
                          : velocity > 30
                              ? Icons.trending_flat
                              : Icons.trending_down,
                      color: velocity > 70
                          ? AppColors.success
                          : velocity > 30
                              ? Color(0xFFFFD700)
                              : Color(0xFFFF5722),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Token Velocity: ${velocity.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface70,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      velocity > 70
                          ? '(Tốt — token được sử dụng nhiều)'
                          : velocity > 30
                              ? '(Trung bình)'
                              : '(Thấp — cần khuyến khích chi tiêu)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Daily Flow Chart ────────────────────────────────────────────────────

  Widget _buildDailyFlowChart(
    ThemeData theme,
    AsyncValue<List<({DateTime date, double earned, double spent})>> flowAsync,
  ) {
    return flowAsync.when(
      loading: () => _buildLoadingCard(height: 220),
      error: (e, _) => _buildErrorCard('Không tải được biểu đồ: $e'),
      data: (flow) {
        if (flow.isEmpty) {
          return _buildEmptyCard('Chưa có dữ liệu giao dịch');
        }

        final maxVal = flow.fold<double>(
          0,
          (max, f) => math.max(max, math.max(f.earned, f.spent)),
        );

        // Summary stats
        final totalEarned = flow.fold<double>(0, (s, f) => s + f.earned);
        final totalSpent = flow.fold<double>(0, (s, f) => s + f.spent);
        final netFlow = totalEarned - totalSpent;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legend + summary
                Row(
                  children: [
                    _buildLegendDot(AppColors.success, 'Earn'),
                    const SizedBox(width: 4),
                    Text(
                      _numberFormat.format(totalEarned.toInt()),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildLegendDot(AppColors.warning, 'Spend'),
                    const SizedBox(width: 4),
                    Text(
                      _numberFormat.format(totalSpent.toInt()),
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: netFlow >= 0
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Net: ${netFlow >= 0 ? '+' : ''}${_numberFormat.format(netFlow.toInt())}',
                        style: TextStyle(
                          color: netFlow >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bar chart
                SizedBox(
                  height: 160,
                  child: maxVal == 0
                      ? const Center(
                          child: Text(
                            'Chưa có giao dịch trong 30 ngày',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Show only last 15 days for readability
                            final displayFlow = flow.length > 15
                                ? flow.sublist(flow.length - 15)
                                : flow;
                            final barWidth =
                                (constraints.maxWidth / displayFlow.length) - 4;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: displayFlow.map((day) {
                                final earnH =
                                    maxVal > 0 ? (day.earned / maxVal * 130) : 0.0;
                                final spendH =
                                    maxVal > 0 ? (day.spent / maxVal * 130) : 0.0;
                                final isToday = day.date.day ==
                                        DateTime.now().day &&
                                    day.date.month == DateTime.now().month;

                                return Tooltip(
                                  message:
                                      '${DateFormat('dd/MM').format(day.date)}\n'
                                      'Earn: ${day.earned.toInt()}\n'
                                      'Spend: ${day.spent.toInt()}',
                                  child: SizedBox(
                                    width: math.max(barWidth, 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Earn bar
                                        Container(
                                          width: math.max(barWidth * 0.4, 3),
                                          height: math.max(earnH, 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        // Spend bar
                                        Container(
                                          width: math.max(barWidth * 0.4, 3),
                                          height: math.max(spendH, 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Date label
                                        Text(
                                          isToday
                                              ? 'Nay'
                                              : day.date.day.toString(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isToday
                                                ? theme.colorScheme.primary
                                                : Colors.grey,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ─── Earning Breakdown ───────────────────────────────────────────────────

  Widget _buildEarningBreakdown(
    ThemeData theme,
    AsyncValue<Map<String, double>> earningAsync,
  ) {
    return earningAsync.when(
      loading: () => _buildLoadingCard(height: 200),
      error: (e, _) => _buildErrorCard('Không tải được phân bổ: $e'),
      data: (breakdown) {
        if (breakdown.isEmpty) {
          return _buildEmptyCard('Chưa có thu nhập token');
        }

        final total = breakdown.values.fold<double>(0, (s, v) => s + v);
        final sorted = breakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final colors = [
          AppColors.success,
          AppColors.info,
          AppColors.warning,
          Color(0xFF9C27B0),
          Color(0xFFE91E63),
          Color(0xFF00BCD4),
          Color(0xFF607D8B),
          Color(0xFFFF5722),
          Color(0xFFCDDC39),
          Color(0xFF795548),
          Color(0xFFFFD700),
        ];

        final sourceLabels = {
          'task': '📋 Công việc',
          'quest': '⚔️ Nhiệm vụ',
          'achievement': '🏅 Thành tích',
          'attendance': '🕐 Chấm công',
          'bonus': '🎁 Thưởng',
          'referral': '🤝 Giới thiệu',
          'system': '⚙️ Hệ thống',
          'season_reward': '🏆 Thưởng mùa',
          'manual': '✏️ Thủ công',
          'transfer': '📤 Chuyển khoản',
          'purchase': '🛒 Mua hàng',
        };

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Horizontal bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      children: sorted.asMap().entries.map((entry) {
                        final pct = entry.value.value / total;
                        final color = colors[entry.key % colors.length];
                        return Expanded(
                          flex: (pct * 1000).toInt().clamp(1, 1000),
                          child: Tooltip(
                            message:
                                '${sourceLabels[entry.value.key] ?? entry.value.key}: ${entry.value.value.toInt()} (${(pct * 100).toStringAsFixed(1)}%)',
                            child: Container(color: color),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // List items
                ...sorted.asMap().entries.map((entry) {
                  final source = entry.value.key;
                  final amount = entry.value.value;
                  final pct = total > 0 ? (amount / total * 100) : 0.0;
                  final color = colors[entry.key % colors.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sourceLabels[source] ?? source,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          _numberFormat.format(amount.toInt()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
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

  // ─── Top Earners ─────────────────────────────────────────────────────────

  Widget _buildTopEarners(
    ThemeData theme,
    AsyncValue<List<TokenWallet>> topEarnersAsync,
  ) {
    return topEarnersAsync.when(
      loading: () => _buildLoadingCard(height: 300),
      error: (e, _) => _buildErrorCard('Không tải được bảng xếp hạng: $e'),
      data: (earners) {
        if (earners.isEmpty) {
          return _buildEmptyCard('Chưa có dữ liệu');
        }

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: earners.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final wallet = entry.value;
                final medal = rank == 1
                    ? '🥇'
                    : rank == 2
                        ? '🥈'
                        : rank == 3
                            ? '🥉'
                            : '#$rank';

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: rank <= 3
                        ? Color(0xFFFFD700).withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                    child: Text(
                      medal,
                      style: TextStyle(
                        fontSize: rank <= 3 ? 20 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    wallet.employeeName ?? 'Nhân viên',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Balance: ${_numberFormat.format(wallet.balance.toInt())} SABO',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _numberFormat.format(wallet.totalEarned.toInt()),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'earned',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ─── Store Stats ─────────────────────────────────────────────────────────

  Widget _buildStoreStats(
    ThemeData theme,
    AsyncValue<
            ({
              int totalPurchases,
              double totalRevenue,
              Map<String, int> byCategory,
            })>
        storeStatsAsync,
  ) {
    return storeStatsAsync.when(
      loading: () => _buildLoadingCard(height: 120),
      error: (e, _) => _buildErrorCard('Không tải được store stats: $e'),
      data: (stats) {
        final categoryLabels = {
          'perk': '⭐ Đặc quyền',
          'cosmetic': '🎨 Trang trí',
          'boost': '🚀 Tăng cường',
          'voucher': '🎫 Voucher',
          'physical': '📦 Vật phẩm',
          'digital': '💎 Kỹ thuật số',
          'nft': '🖼️ NFT',
        };

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary row
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        '🛒 Giao dịch',
                        stats.totalPurchases.toString(),
                        theme,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        '💰 Doanh thu',
                        '${_numberFormat.format(stats.totalRevenue.toInt())} 🪙',
                        theme,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        '📊 Categories',
                        stats.byCategory.length.toString(),
                        theme,
                      ),
                    ),
                  ],
                ),
                if (stats.byCategory.isNotEmpty) ...[
                  const Divider(height: 24),
                  ...stats.byCategory.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              categoryLabels[entry.key] ?? entry.key,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${entry.value} lượt mua',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Recent Activity ─────────────────────────────────────────────────────

  Widget _buildRecentActivity(
    ThemeData theme,
    AsyncValue<List<TokenTransaction>> activityAsync,
  ) {
    return activityAsync.when(
      loading: () => _buildLoadingCard(height: 200),
      error: (e, _) => _buildErrorCard('Không tải được hoạt động: $e'),
      data: (activities) {
        if (activities.isEmpty) {
          return _buildEmptyCard('Chưa có hoạt động token nào');
        }

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: activities.map((tx) {
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: tx.type.color.withValues(alpha: 0.15),
                    child: Text(tx.type.icon, style: const TextStyle(fontSize: 16)),
                  ),
                  title: Text(
                    tx.description ?? tx.type.label,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    tx.timeAgo,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  trailing: Text(
                    tx.formattedAmount,
                    style: TextStyle(
                      color: tx.type.isPositive
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(ThemeData theme, String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard({double height = 120}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 1,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Text('📭', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
