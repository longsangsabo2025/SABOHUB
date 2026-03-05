import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/token/token_models.dart';
import '../../providers/token_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

// ─── Page ────────────────────────────────────────────────────────────────────

class SaboTokenStorePage extends ConsumerStatefulWidget {
  const SaboTokenStorePage({super.key});

  @override
  ConsumerState<SaboTokenStorePage> createState() => _SaboTokenStorePageState();
}

class _SaboTokenStorePageState extends ConsumerState<SaboTokenStorePage> {
  String? _selectedCategory;
  bool _showPurchases = false;
  final _fmt = NumberFormat('#,###');

  // ── Category definitions ──
  static const _categories = <String, String>{
    'perk': 'Đặc quyền',
    'cosmetic': 'Trang trí',
    'boost': 'Tăng cường',
    'voucher': 'Voucher',
    'physical': 'Vật lý',
    'digital': 'Digital',
    'nft': 'NFT',
  };

  // ── Reload helpers ──
  Future<void> _refresh() async {
    ref.invalidate(tokenWalletProvider);
    ref.invalidate(tokenStoreProvider);
    ref.read(tokenWalletProvider.notifier).loadWallet();
    ref.read(tokenStoreProvider.notifier).loadStore();
  }

  @override
  void initState() {
    super.initState();
    // Trigger initial load
    Future.microtask(() {
      ref.read(tokenStoreProvider.notifier).loadStore();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(tokenWalletProvider);
    final storeState = ref.watch(tokenStoreProvider);
    final wallet = walletState.wallet;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: _buildAppBar(wallet),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: walletState.isLoading || storeState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : walletState.error != null
                ? _buildError('Lỗi tải ví: ${walletState.error}')
                : storeState.error != null
                    ? _buildError('Lỗi tải cửa hàng: ${storeState.error}')
                    : _buildBody(wallet, storeState.items),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AppBar
  // ──────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(TokenWallet? wallet) {
    final balance = wallet?.balance ?? 0;

    return AppBar(
      title: Text('SABO Store'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                _fmt.format(balance.toInt()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Body
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildBody(TokenWallet? wallet, List<TokenStoreItem> items) {
    if (items.isEmpty) {
      return _buildEmpty('Chưa có vật phẩm nào trong cửa hàng');
    }

    final filtered = _selectedCategory == null
        ? items
        : items.where((i) => i.category.value == _selectedCategory).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Balance header
        SliverToBoxAdapter(child: _buildBalanceCard(wallet)),

        // Category chips
        SliverToBoxAdapter(child: _buildCategoryFilter(items)),

        // Purchase toggle
        SliverToBoxAdapter(child: _buildPurchasesToggle(wallet)),

        // Purchases or grid
        if (_showPurchases && wallet != null)
          SliverToBoxAdapter(child: _buildMyPurchases(wallet.id))
        else if (filtered.isEmpty)
          SliverToBoxAdapter(child: _buildEmpty('Không có vật phẩm cho danh mục này'))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildItemCard(filtered[index], wallet),
                childCount: filtered.length,
              ),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Balance Card
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildBalanceCard(TokenWallet? wallet) {
    if (wallet == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.warning, AppColors.warningDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('💰', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SABO Token',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.surface70),
                ),
                Text(
                  _fmt.format(wallet.balance.toInt()),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statLabel('Earned', wallet.totalEarned),
              const SizedBox(height: 2),
              _statLabel('Spent', wallet.totalSpent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statLabel(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.surface60),
        ),
        const SizedBox(width: 4),
        Text(
          _fmt.format(value.toInt()),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Category Filter
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildCategoryFilter(List<TokenStoreItem> items) {
    final availableCats = items.map((i) => i.category.value).toSet();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chipButton(null, 'Tất cả', availableCats.isNotEmpty),
          ..._categories.entries
              .where((e) => availableCats.contains(e.key))
              .map((e) => _chipButton(e.key, e.value, true)),
        ],
      ),
    );
  }

  Widget _chipButton(String? category, String label, bool enabled) {
    final selected = _selectedCategory == category;

    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: enabled
            ? (_) => setState(() {
                  _selectedCategory = category;
                  _showPurchases = false;
                })
            : null,
        selectedColor: Colors.amber.shade100,
        backgroundColor: Theme.of(context).colorScheme.surface,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.amber.shade900 : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: selected ? Colors.amber.shade400 : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Purchases Toggle
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPurchasesToggle(TokenWallet? wallet) {
    if (wallet == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton.icon(
        onPressed: () => setState(() => _showPurchases = !_showPurchases),
        icon: Icon(
          _showPurchases ? Icons.storefront : Icons.inventory_2_outlined,
          size: 18,
          color: AppColors.primary,
        ),
        label: Text(
          _showPurchases ? 'Xem cửa hàng' : 'Vật phẩm đã mua',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Item Card
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildItemCard(TokenStoreItem item, TokenWallet? wallet) {
    final balance = wallet?.balance ?? 0;
    final canAfford = balance >= item.tokenCost;
    final meetsLevel = true; // level check deferred to provider / gamification
    final purchasedCodes = <String>{}; // resolved per-card in purchases section
    final owned = item.isOneTime && purchasedCodes.contains(item.id);
    final canBuy = canAfford && meetsLevel && !owned && item.isActive;
    final catEnum = item.category;

    return Container(
      decoration: BoxDecoration(
        color: owned ? AppColors.success.withValues(alpha: 0.04) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: owned
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon header
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: catEnum.color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Center(
              child: Text(item.iconEmoji, style: const TextStyle(fontSize: 40)),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: catEnum.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${catEnum.icon} ${catEnum.label}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: catEnum.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Cost
                  Row(
                    children: [
                      Text(
                        '💰 ${item.formattedCost} SABO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Level + stock row
                  Row(
                    children: [
                      if (item.minLevel > 1)
                        _badge('Lv.${item.minLevel}+', AppColors.info),
                      if (item.minLevel > 1) const SizedBox(width: 4),
                      if (!item.isUnlimited && item.stock != null)
                        _badge('Còn ${item.stock}', AppColors.success),
                      if (item.isOneTime) ...[
                        const SizedBox(width: 4),
                        _badge('1 lần', Colors.orange),
                      ],
                    ],
                  ),

                  const Spacer(),

                  // Buy button
                  if (owned)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          '✅ Đã mua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canBuy ? () => _onPurchase(item, wallet) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canBuy ? Colors.amber.shade700 : Colors.grey.shade300,
                          foregroundColor: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          canBuy
                              ? 'Mua'
                              : !canAfford
                                  ? 'Thiếu token'
                                  : 'Không khả dụng',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Purchase Flow
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _onPurchase(TokenStoreItem item, TokenWallet? wallet) async {
    final balance = wallet?.balance ?? 0;
    final balanceAfter = balance - item.tokenCost;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(item.iconEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.name, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) ...[
              Text(
                item.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
            ],
            _purchaseRow('Chi phí', '💰 ${item.formattedCost} SABO', Colors.amber.shade800),
            const Divider(height: 16),
            _purchaseRow('Số dư hiện tại', _fmt.format(balance.toInt()), AppColors.textPrimary),
            _purchaseRow(
              'Số dư sau mua',
              _fmt.format(balanceAfter.toInt()),
              balanceAfter >= 0 ? AppColors.success : AppColors.error,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: balanceAfter >= 0 ? () => Navigator.pop(ctx, true) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận mua'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final success = await ref.read(tokenStoreProvider.notifier).purchaseItem(item.id);

      if (!mounted) return;

      if (success) {
        // Show success animation
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => _SuccessDialog(itemName: item.name, itemIcon: item.iconEmoji),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mua không thành công'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _purchaseRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // My Purchases
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildMyPurchases(String walletId) {
    final storeState = ref.watch(tokenStoreProvider);
    final purchases = storeState.myPurchases;

    if (storeState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (purchases.isEmpty) {
      return _buildEmpty('Bạn chưa mua vật phẩm nào');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '🎒 Vật phẩm đã mua',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          ...purchases.map((p) => _buildPurchaseTile(p)),
        ],
      ),
    );
  }

  Widget _buildPurchaseTile(TokenPurchase purchase) {
    final item = purchase.item;
    final statusInfo = _purchaseStatusInfo(purchase);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusInfo.color.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                item?.iconEmoji ?? '🎁',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item?.name ?? 'Vật phẩm',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusInfo.color,
                        ),
                      ),
                    ),
                    if (purchase.expiresAt != null && purchase.isActive) ...[
                      const SizedBox(width: 6),
                      Text(
                        _expiryText(purchase.expiresAt!),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '💰 ${_fmt.format(purchase.tokenCost.toInt())}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _purchaseStatusInfo(TokenPurchase p) {
    if (p.isExpired) return (label: 'Hết hạn', color: Colors.grey);
    return switch (p.status) {
      'active' => (label: 'Đang dùng', color: AppColors.success),
      'used' => (label: 'Đã dùng', color: AppColors.info),
      'expired' => (label: 'Hết hạn', color: Colors.grey),
      'refunded' => (label: 'Hoàn trả', color: Colors.orange),
      _ => (label: p.status, color: AppColors.textSecondary),
    };
  }

  String _expiryText(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Đã hết hạn';
    if (diff.inDays > 0) return 'Còn ${diff.inDays}d';
    if (diff.inHours > 0) return 'Còn ${diff.inHours}h';
    return 'Còn ${diff.inMinutes}m';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏪', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _refresh,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Success Dialog ──────────────────────────────────────────────────────────

class _SuccessDialog extends StatefulWidget {
  final String itemName;
  final String itemIcon;

  const _SuccessDialog({required this.itemName, required this.itemIcon});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.12),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle, color: AppColors.success, size: 48),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mua thành công!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.itemIcon} ${widget.itemName}',
                style: const TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
