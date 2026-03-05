import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/blockchain_config.dart';
import '../../core/router/app_router.dart';
import '../../models/token/token_models.dart';
import '../../providers/token_provider.dart';
import 'sabo_token_store_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class SaboWalletPage extends ConsumerStatefulWidget {
  SaboWalletPage({super.key});

  @override
  ConsumerState<SaboWalletPage> createState() => _SaboWalletPageState();
}

class _SaboWalletPageState extends ConsumerState<SaboWalletPage>
    with SingleTickerProviderStateMixin {
  final _fmt = NumberFormat('#,###');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(tokenHistoryProvider.notifier).loadHistory();
      ref.read(bridgeHistoryProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(tokenWalletProvider);
    final historyState = ref.watch(tokenHistoryProvider);
    final bridgeState = ref.watch(bridgeHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SABO Wallet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Thành Tích NFT',
            onPressed: () => GoRouter.of(context).push(AppRoutes.saboAchievements),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Token Analytics',
            onPressed: () => GoRouter.of(context).push(AppRoutes.saboTokenAnalytics),
          ),
          if (walletState.wallet != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Text('💰', style: TextStyle(fontSize: 14)),
                label: Text(
                  '${_fmt.format(walletState.wallet!.balance.toInt())} SABO',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: Colors.amber.shade50,
                side: BorderSide(color: Colors.amber.shade300),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet, size: 18), text: 'Ví'),
            Tab(icon: Icon(Icons.swap_horiz, size: 18), text: 'Bridge'),
            Tab(icon: Icon(Icons.lock_clock, size: 18), text: 'Staking'),
          ],
        ),
      ),
      body: walletState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : walletState.error != null
              ? _buildError(walletState.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Wallet (original content)
                    RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(tokenWalletProvider.notifier).refresh();
                        await ref
                            .read(tokenHistoryProvider.notifier)
                            .loadHistory();
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildWalletHeroCard(context, walletState.wallet),
                          const SizedBox(height: 20),
                          _buildQuickActions(),
                          const SizedBox(height: 20),
                          _buildRecentTransactions(historyState),
                          const SizedBox(height: 20),
                          _buildEarningOpportunities(theme),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    // Tab 2: Bridge
                    RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(bridgeHistoryProvider.notifier)
                            .loadHistory();
                        await ref.read(tokenWalletProvider.notifier).refresh();
                        await ref.read(bridgeLiveStatusProvider.notifier).refresh();
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildBridgeHeroCard(context, walletState.wallet),
                          const SizedBox(height: 12),
                          _buildBridgeLiveStatus(),
                          const SizedBox(height: 16),
                          _buildBridgeActions(),
                          const SizedBox(height: 20),
                          _buildBridgeHistory(bridgeState),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    // Tab 3: Staking
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildStakingHero(context),
                        const SizedBox(height: 20),
                        _buildStakingTiers(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ],
                ),
    );
  }

  // ─── Wallet Hero Card ──────────────────────────────────────────────────────

  Widget _buildWalletHeroCard(BuildContext context, TokenWallet? wallet) {
    final balance = wallet?.balance ?? 0;
    final totalEarned = wallet?.totalEarned ?? 0;
    final totalSpent = wallet?.totalSpent ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFA726), Color(0xFFFFCA28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🪙', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Text(
                'SABO Wallet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Off-chain',
                  style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _fmt.format(balance.toInt()),
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          Text(
            'SABO Token',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '≈ ${_fmt.format((balance * 10).toInt())} VNĐ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statChip(context, '📈 Đã nhận', _fmt.format(totalEarned.toInt())),
              const SizedBox(width: 8),
              _statChip(context, '📉 Đã chi', _fmt.format(totalSpent.toInt())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 12),
      ),
    );
  }

  // ─── Quick Actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionButton('💰', 'Nhận\nthưởng', Colors.green, _showEarnInfo),
        const SizedBox(width: 12),
        _actionButton('🛒', 'Cửa\nhàng', Colors.orange, _goToStore),
        const SizedBox(width: 12),
        _actionButton('📤', 'Chuyển\ntoken', Colors.blue, _showTransferDialog),
        const SizedBox(width: 12),
        _actionButton('📊', 'Lịch\nsử', Colors.purple, _showFullHistory),
      ],
    );
  }

  Widget _actionButton(
    String emoji,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.9),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Recent Transactions ───────────────────────────────────────────────────

  Widget _buildRecentTransactions(TokenHistoryState historyState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giao dịch gần đây',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _showFullHistory,
              child: const Text('Xem tất cả →'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (historyState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (historyState.transactions.isEmpty)
          _buildEmptyTransactions()
        else
          ...historyState.transactions.take(5).map(_buildTransactionTile),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Text('🪙', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Hoàn thành quest & task để nhận SABO Token!',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TokenTransaction tx) {
    final isPositive = tx.type.isPositive;
    final color = tx.type.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(tx.type.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? tx.type.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.timeAgo,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? "+" : "-"}${_fmt.format(tx.amount.toInt())}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Earning Opportunities ─────────────────────────────────────────────────

  Widget _buildEarningOpportunities(ThemeData theme) {
    final items = [
      ('✅', 'Đăng nhập hàng ngày', '+5 SABO', Colors.green),
      ('⚔️', 'Hoàn thành Quest', '+20 SABO', Colors.blue),
      ('🏆', 'Mở khóa Achievement', '+50 SABO', Colors.amber),
      ('📋', 'Hoàn thành Task', '+10 SABO', Colors.teal),
      ('🔥', 'Chuỗi điểm danh (streak)', '+15 SABO/streak', Colors.orange),
      ('⬆️', 'Lên level mới', '+100 SABO', Colors.purple),
      ('🌟', 'Tháng hoàn hảo', '+300 SABO', Colors.pink),
      ('🤝', 'Giới thiệu đồng nghiệp', '+200 SABO', Colors.indigo),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Cách kiếm SABO Token',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.$4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bridge Hero Card ───────────────────────────────────────────────────

  Widget _buildBridgeHeroCard(BuildContext context, TokenWallet? wallet) {
    final balance = wallet?.balance ?? 0;
    final walletAddr = wallet?.walletAddress;
    final hasWallet = walletAddr != null && walletAddr.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF90CAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🌉', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Text(
                'SABO Bridge',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  BlockchainConfig.networkName,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _bridgeStat(context, 
                  'Off-chain',
                  '${_fmt.format(balance.toInt())} SABO',
                  Icons.cloud_outlined,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.surface54, size: 20),
              ),
              Expanded(
                child: _bridgeStat(context, 
                  'On-chain',
                  hasWallet ? '— SABO' : 'Chưa liên kết',
                  Icons.link,
                ),
              ),
            ],
          ),
          if (hasWallet) ...[
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔗 ${walletAddr.substring(0, 6)}...${walletAddr.substring(walletAddr.length - 4)}',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bridgeStat(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.surface70, size: 14),
              SizedBox(width: 4),
              Text(label,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bridge Live Status ────────────────────────────────────────────────

  Widget _buildBridgeLiveStatus() {
    final status = ref.watch(bridgeLiveStatusProvider);
    final isOnline = status.isOnline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withValues(alpha: 0.06)
            : Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'Bridge Online' : 'Bridge Offline',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
              const Spacer(),
              if (status.lastChecked != null)
                Text(
                  _timeAgo(status.lastChecked!),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => ref.read(bridgeLiveStatusProvider.notifier).refresh(),
                child: Icon(
                  Icons.refresh,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          if (isOnline) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statusMini(
                    'Tổng khóa',
                    '${_fmt.format(status.totalLocked.toInt())} SABO',
                    Icons.lock_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusMini(
                    'Đã rút',
                    '${_fmt.format(status.totalWithdrawn.toInt())} SABO',
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusMini(
                    'Trạng thái',
                    status.isPaused ? 'Tạm dừng' : 'Hoạt động',
                    status.isPaused ? Icons.pause_circle : Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
          if (!isOnline && status.error != null) ...[
            const SizedBox(height: 8),
            Text(
              status.error!,
              style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusMini(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  // ─── Bridge Actions ────────────────────────────────────────────────────

  Widget _buildBridgeActions() {
    return Row(
      children: [
        Expanded(
          child: _bridgeActionBtn(
            icon: Icons.arrow_upward_rounded,
            label: 'Rút lên\nBlockchain',
            color: Colors.orange,
            onTap: _showWithdrawDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _bridgeActionBtn(
            icon: Icons.arrow_downward_rounded,
            label: 'Nạp từ\nBlockchain',
            color: Colors.green,
            onTap: _showDepositDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _bridgeActionBtn(
            icon: Icons.link,
            label: 'Liên kết\nVí',
            color: Colors.blue,
            onTap: _showLinkWalletDialog,
          ),
        ),
      ],
    );
  }

  Widget _bridgeActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bridge History ────────────────────────────────────────────────────

  Widget _buildBridgeHistory(BridgeHistoryState bridgeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch sử Bridge',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (bridgeState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (bridgeState.requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text('🌉', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text('Chưa có giao dịch bridge nào',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                SizedBox(height: 4),
                Text('Rút hoặc nạp SABO từ blockchain',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        else
          ...bridgeState.requests.map(_buildBridgeRequestTile),
      ],
    );
  }

  Widget _buildBridgeRequestTile(BridgeRequest req) {
    final isWithdraw = req.type == BridgeRequestType.withdraw;
    final statusColor = switch (req.status) {
      BridgeRequestStatus.pending => Colors.amber,
      BridgeRequestStatus.processing => Colors.blue,
      BridgeRequestStatus.completed => Colors.green,
      BridgeRequestStatus.failed => Colors.red,
      BridgeRequestStatus.cancelled => Colors.grey,
    };
    final statusLabel = switch (req.status) {
      BridgeRequestStatus.pending => 'Chờ xử lý',
      BridgeRequestStatus.processing => 'Đang xử lý',
      BridgeRequestStatus.completed => 'Thành công',
      BridgeRequestStatus.failed => 'Thất bại',
      BridgeRequestStatus.cancelled => 'Đã hủy',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isWithdraw ? Colors.orange : Colors.green)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isWithdraw
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isWithdraw ? Colors.orange : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWithdraw ? 'Rút lên blockchain' : 'Nạp từ blockchain',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatBridgeDate(req.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt.format(req.amount.toInt())} SABO',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
              if (req.feeAmount > 0)
                Text(
                  'Fee: ${req.feeAmount.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
          if (req.status == BridgeRequestStatus.pending) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel_outlined,
                  size: 18, color: Colors.red),
              onPressed: () async {
                final ok = await ref
                    .read(bridgeHistoryProvider.notifier)
                    .cancelRequest(req.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Đã hủy request' : 'Lỗi hủy request'),
                  ));
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatBridgeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return DateFormat('dd/MM HH:mm').format(dt);
  }

  // ─── Staking Hero ──────────────────────────────────────────────────────

  Widget _buildStakingHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC), Color(0xFFCE93D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🔒', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SABO Staking',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Stake SABO để nhận APY lên đến 30%',
                      style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.surface70, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Staking sẽ khả dụng khi SABO Token được deploy lên Base L2. Bạn có thể xem trước các tier và APY bên dưới.',
                    style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Staking Tiers ─────────────────────────────────────────────────────

  Widget _buildStakingTiers() {
    final tiers = ref.watch(stakingTiersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Staking Tiers',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...tiers.map((tier) => _buildStakingTierCard(context, tier)),
      ],
    );
  }

  Widget _buildStakingTierCard(BuildContext context, StakingTierInfo tier) {
    final tierColors = {
      'Bronze': Colors.brown,
      'Silver': Colors.grey,
      'Gold': Colors.amber,
      'Diamond': Colors.blue,
    };
    final color = tierColors[tier.name] ?? Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(tier.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tối thiểu: ${_fmt.format(tier.minStake.toInt())} SABO  •  Lock: ${tier.lockPeriodDays} ngày',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${tier.apyPercent.toInt()}% APY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(tokenWalletProvider.notifier).refresh(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _showEarnInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💰 Cách nhận SABO Token',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'SABO Token được phát thưởng tự động khi bạn hoạt động tích cực trong hệ thống:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _earnInfoRow('Đăng nhập mỗi ngày', '5 SABO'),
            _earnInfoRow('Hoàn thành quest', '20 SABO'),
            _earnInfoRow('Unlock achievement', '50 SABO'),
            _earnInfoRow('Hoàn thành task', '10 SABO'),
            _earnInfoRow('Level up', '100 SABO'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _earnInfoRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  void _goToStore() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SaboTokenStorePage()),
    );
  }

  void _showTransferDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final employeeIdController = TextEditingController();
    final balance = ref.read(tokenWalletProvider).wallet?.balance ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📤 Chuyển SABO Token',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Số dư: ${_fmt.format(balance.toInt())} SABO',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: employeeIdController,
              decoration: const InputDecoration(
                labelText: 'ID nhân viên nhận',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng SABO',
                prefixIcon: Icon(Icons.toll),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                    ),
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      final toId = employeeIdController.text.trim();
                      if (amount <= 0 || toId.isEmpty) return;

                      Navigator.pop(ctx);
                      final success = await ref
                          .read(tokenWalletProvider.notifier)
                          .transferTokens(
                            toId,
                            amount,
                            note: noteController.text.trim().isNotEmpty
                                ? noteController.text.trim()
                                : null,
                          );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Đã chuyển ${_fmt.format(amount.toInt())} SABO thành công!'
                                : 'Chuyển thất bại. Kiểm tra số dư.',
                          ),
                          backgroundColor:
                              success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) {
                        ref
                            .read(tokenHistoryProvider.notifier)
                            .loadHistory();
                      }
                    },
                    child: const Text('Chuyển'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullHistory() {
    ref.read(tokenHistoryProvider.notifier).loadHistory();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => _TokenHistorySheet(
          scrollController: scrollController,
          fmt: _fmt,
        ),
      ),
    );
  }

  // ─── Bridge Dialogs ────────────────────────────────────────────────────

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    final addressController = TextEditingController();
    final wallet = ref.read(tokenWalletProvider).wallet;
    final balance = wallet?.balance ?? 0;

    // Pre-fill linked address
    if (wallet?.walletAddress != null && wallet!.walletAddress!.isNotEmpty) {
      addressController.text = wallet.walletAddress!;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final amount = double.tryParse(amountController.text) ?? 0;
          final fee = BlockchainConfig.calculateWithdrawFee(amount);
          final net = amount - fee;

          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔼 Rút SABO lên Blockchain',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Số dư: ${_fmt.format(balance.toInt())} SABO  •  Min: ${BlockchainConfig.minBridgeAmount.toInt()}  •  Max: ${BlockchainConfig.maxWithdrawAmount.toInt()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ ví (0x...)',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(),
                    hintText: '0x...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Số lượng SABO',
                    prefixIcon: Icon(Icons.toll),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (amount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        _feeRow('Số lượng', '${amount.toStringAsFixed(0)} SABO'),
                        _feeRow('Phí (${(BlockchainConfig.withdrawFeePercent * 100).toInt()}%)',
                            '-${fee.toStringAsFixed(1)} SABO'),
                        const Divider(height: 16),
                        _feeRow('Nhận được', '${net.toStringAsFixed(1)} SABO',
                            bold: true),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Theme.of(context).colorScheme.surface,
                        ),
                        onPressed: () async {
                          final amt =
                              double.tryParse(amountController.text) ?? 0;
                          final addr = addressController.text.trim();
                          if (amt < BlockchainConfig.minBridgeAmount ||
                              addr.isEmpty) {
                            return;
                          }

                          Navigator.pop(ctx);
                          final result = await ref
                              .read(bridgeHistoryProvider.notifier)
                              .requestWithdraw(
                                  amount: amt, walletAddress: addr);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(result != null
                                ? 'Yêu cầu rút ${_fmt.format(amt.toInt())} SABO đã tạo!'
                                : 'Lỗi tạo yêu cầu rút'),
                            backgroundColor:
                                result != null ? Colors.green : Colors.red,
                          ));
                        },
                        child: const Text('Rút SABO'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _feeRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    final txHashController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔽 Nạp SABO từ Blockchain',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Gửi SABO đến Bridge contract trên Base L2, sau đó nhập tx hash để xác nhận.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bridge Contract:',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    BlockchainConfig.bridgeContract,
                    style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: txHashController,
              decoration: const InputDecoration(
                labelText: 'Transaction Hash (0x...)',
                prefixIcon: Icon(Icons.receipt_long),
                border: OutlineInputBorder(),
                hintText: '0x...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng SABO đã gửi',
                prefixIcon: Icon(Icons.toll),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                    ),
                    onPressed: () async {
                      final txHash = txHashController.text.trim();
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      if (txHash.isEmpty || amount <= 0) return;

                      Navigator.pop(ctx);
                      final result = await ref
                          .read(bridgeHistoryProvider.notifier)
                          .confirmDeposit(
                              txHash: txHash, expectedAmount: amount);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result != null
                            ? 'Nạp ${_fmt.format(amount.toInt())} SABO thành công!'
                            : 'Lỗi xác nhận deposit'),
                        backgroundColor:
                            result != null ? Colors.green : Colors.red,
                      ));
                    },
                    child: const Text('Xác nhận nạp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkWalletDialog() {
    final addressController = TextEditingController();
    final wallet = ref.read(tokenWalletProvider).wallet;

    if (wallet?.walletAddress != null && wallet!.walletAddress!.isNotEmpty) {
      addressController.text = wallet.walletAddress!;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔗 Liên kết ví Blockchain',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Liên kết địa chỉ ví EVM (MetaMask, Coinbase Wallet, v.v.) để sử dụng Bridge.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ ví (0x...)',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
                hintText: '0x...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                    ),
                    onPressed: () async {
                      final addr = addressController.text.trim();
                      if (addr.isEmpty ||
                          !BlockchainConfig.isValidAddress(addr)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Địa chỉ ví không hợp lệ')));
                        return;
                      }

                      Navigator.pop(ctx);
                      try {
                        final service = ref.read(tokenServiceProvider);
                        await service.linkWalletAddress(wallet!.id, addr);
                        ref.read(tokenWalletProvider.notifier).refresh();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã liên kết ví thành công!'),
                              backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('Liên kết'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Full History Sheet ──────────────────────────────────────────────────────

class _TokenHistorySheet extends ConsumerWidget {
  final ScrollController scrollController;
  final NumberFormat fmt;

  const _TokenHistorySheet({
    required this.scrollController,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(tokenHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '📊 Lịch sử giao dịch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : historyState.transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có giao dịch nào',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: historyState.transactions.length,
                        itemBuilder: (_, index) {
                          final tx = historyState.transactions[index];
                          final isPositive = tx.type.isPositive;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  tx.type.color.withValues(alpha: 0.15),
                              child: Text(
                                tx.type.icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            title: Text(
                              tx.description ?? tx.type.label,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              tx.timeAgo,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              '${isPositive ? "+" : "-"}${fmt.format(tx.amount.toInt())}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPositive
                                    ? Colors.green.shade700
                                    : Colors.red.shade600,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
