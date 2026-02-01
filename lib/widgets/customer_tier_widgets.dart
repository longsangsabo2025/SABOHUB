/// Customer Tier Widgets - Badge và UI components cho phân loại khách hàng
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer_tier.dart';

/// Badge hiển thị tier khách hàng
class CustomerTierBadge extends StatelessWidget {
  final CustomerTier tier;
  final bool showLabel;
  final double size;

  const CustomerTierBadge({
    super.key,
    required this.tier,
    this.showLabel = true,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == CustomerTier.none) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 8 : 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tier.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: tier.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tier.emoji,
            style: TextStyle(fontSize: size * 0.8),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              tier.displayName,
              style: TextStyle(
                color: tier.textColor,
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip để filter theo tier
class CustomerTierFilterChip extends StatelessWidget {
  final CustomerTier? tier; // null = Tất cả
  final bool isSelected;
  final VoidCallback onTap;

  const CustomerTierFilterChip({
    super.key,
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = tier?.displayName ?? 'Tất cả';
    final emoji = tier?.emoji ?? '👥';
    final color = tier?.color ?? Colors.teal;

    return Material(
      color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card hiển thị thống kê tier
class CustomerTierStatsCard extends StatelessWidget {
  final Map<CustomerTier, int> stats;
  final CustomerTier? selectedTier;
  final Function(CustomerTier?)? onTierSelected;

  const CustomerTierStatsCard({
    super.key,
    required this.stats,
    this.selectedTier,
    this.onTierSelected,
  });

  @override
  Widget build(BuildContext context) {
    final total = stats.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Phân loại khách hàng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                'Tổng: $total',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final tier in [CustomerTier.diamond, CustomerTier.gold, CustomerTier.silver, CustomerTier.bronze])
                Expanded(
                  child: _buildTierStat(tier, stats[tier] ?? 0, total),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierStat(CustomerTier tier, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    final isSelected = selectedTier == tier;

    return GestureDetector(
      onTap: onTierSelected != null
          ? () => onTierSelected!(isSelected ? null : tier)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? tier.color.withOpacity(0.2) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tier.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(tier.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: tier.color,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row hiển thị thông tin doanh số của khách hàng
class CustomerRevenueInfo extends StatelessWidget {
  final CustomerRevenue revenue;
  final bool showTier;

  const CustomerRevenueInfo({
    super.key,
    required this.revenue,
    this.showTier = true,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Row(
      children: [
        if (showTier) ...[
          CustomerTierBadge(tier: revenue.tier, showLabel: false),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currencyFormat.format(revenue.totalRevenue),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '${revenue.completedOrders}/${revenue.totalOrders} đơn',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (revenue.outstandingAmount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Nợ: ${NumberFormat.compact(locale: 'vi').format(revenue.outstandingAmount)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
