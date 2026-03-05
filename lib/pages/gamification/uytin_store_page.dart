import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class UytinStorePage extends ConsumerWidget {
  const UytinStorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(ceoProfileProvider);
    final storeItems = ref.watch(storeItemsProvider);
    final purchases = ref.watch(userPurchasesProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Uy Tín Store'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceHeader(context, profile),
          const SizedBox(height: 16),
          _buildActivePurchases(purchases),
          const SizedBox(height: 16),
          storeItems.when(
            data: (items) {
              final purchasedCodes = purchases.value
                      ?.map((p) => p.item?.code)
                      .whereType<String>()
                      .toSet() ??
                  {};

              final categories = ['perk', 'boost', 'cosmetic', 'unlock'];
              final categoryNames = {
                'perk': '🛡️ Đặc Quyền',
                'boost': '⚡ Tăng Cường',
                'cosmetic': '✨ Trang Trí',
                'unlock': '🔓 Mở Khóa',
              };

              return Column(
                children: categories.map((cat) {
                  final catItems = items.where((i) => i.category == cat).toList();
                  if (catItems.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryNames[cat] ?? cat,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      ...catItems.map((item) {
                        final owned = purchasedCodes.contains(item.code) && item.isOneTime;
                        return _buildStoreItem(context, ref, item, profile, owned);
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Lỗi: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context, CeoProfile? profile) {
    if (profile == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 36)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uy Tín',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.surface70),
                ),
                Text(
                  '${profile.reputationPoints}',
                  style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Lv.${profile.level}',
              style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePurchases(AsyncValue<List<UytinPurchase>> purchases) {
    return purchases.when(
      data: (list) {
        final active = list.where((p) => !p.isExpired).toList();
        if (active.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎒 Vật phẩm đang sử dụng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: active.map((p) {
                final item = p.item;
                final hasExpiry = p.expiresAt != null;
                final remaining = hasExpiry
                    ? p.expiresAt!.difference(DateTime.now())
                    : null;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item?.iconEmoji ?? '⭐', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        item?.name ?? 'Item',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (remaining != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${remaining.inHours}h',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildStoreItem(
    BuildContext context,
    WidgetRef ref,
    UytinStoreItem item,
    CeoProfile? profile,
    bool owned,
  ) {
    final canAfford = (profile?.reputationPoints ?? 0) >= item.cost;
    final meetsLevel = (profile?.level ?? 0) >= item.minLevel;
    final canBuy = canAfford && meetsLevel && !owned;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: owned ? AppColors.success.withValues(alpha: 0.04) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: owned
              ? AppColors.success.withValues(alpha: 0.3)
              : canBuy
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: owned
                  ? AppColors.success.withValues(alpha: 0.12)
                  : Color(0xFF6A1B9A).withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(item.iconEmoji, style: TextStyle(fontSize: 22)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: owned ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (owned)
                      const Text('✅', style: TextStyle(fontSize: 16)),
                  ],
                ),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFF6A1B9A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⭐ ${item.cost}',
                        style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (item.minLevel > 1)
                      Text(
                        'Lv.${item.minLevel}+',
                        style: TextStyle(
                          fontSize: 10,
                          color: meetsLevel ? AppColors.textSecondary : AppColors.error,
                        ),
                      ),
                    if (item.durationHours != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '⏰ ${item.durationHours}h',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!owned)
            ElevatedButton(
              onPressed: canBuy ? () => _onPurchase(context, ref, item) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canBuy ? Color(0xFF6A1B9A) : Colors.grey.shade300,
                foregroundColor: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                canBuy ? 'Mua' : !meetsLevel ? 'Lv.${item.minLevel}' : 'Thiếu',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onPurchase(BuildContext context, WidgetRef ref, UytinStoreItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(item.iconEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) Text(item.description!),
            const SizedBox(height: 8),
            Text(
              'Chi phí: ⭐ ${item.cost} Uy Tín',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
            child: const Text('Xác nhận mua'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(gamificationActionsProvider).purchaseStoreItem(item.code);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
