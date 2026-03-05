import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/ceo_business_provider.dart';

/// Distribution CEO Sales Tab — Orders, revenue trends, customer insights
class DistributionCEOSales extends ConsumerWidget {
  const DistributionCEOSales({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(dailyRevenueChartProvider);
    final customerAsync = ref.watch(customerInsightsProvider);
    final kpisAsync = ref.watch(realCEOKPIsProvider);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyRevenueChartProvider);
        ref.invalidate(customerInsightsProvider);
        ref.invalidate(realCEOKPIsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue chart
            const Text('📊 Doanh thu 30 ngày',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            chartAsync.when(
              data: (data) => _buildRevenueChart(context, data, fmt),
              loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) =>
                  const SizedBox(height: 200, child: Center(child: Text('Lỗi tải chart'))),
            ),

            const SizedBox(height: 24),

            // Order stats
            const Text('🛒 Đơn hàng tháng này',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            kpisAsync.when(
              data: (kpis) => Row(
                children: [
                  _buildStatChip('Hoàn thành', '${kpis.completedOrdersThisMonth}',
                      AppColors.success),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      'Doanh thu', fmt.format(kpis.monthlyRevenue), AppColors.primary),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      'COGS', fmt.format(kpis.cogs), Colors.orange),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => const Text('Lỗi'),
            ),

            const SizedBox(height: 24),

            // Customer insights
            const Text('👥 Khách hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            customerAsync.when(
              data: (insights) => _buildCustomerInsights(context, insights, fmt),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Text('Lỗi tải KH'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, List<DailyRevenue> data, NumberFormat fmt) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa có dữ liệu doanh thu')),
      );
    }

    final maxRevenue =
        data.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    final maxY = maxRevenue == 0 ? 1.0 : maxRevenue * 1.2;

    return Container(
      height: 220,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, _) {
                  if (value == 0) return const Text('');
                  final label = value >= 1000000
                      ? '${(value / 1000000).toStringAsFixed(0)}M'
                      : '${(value / 1000).toStringAsFixed(0)}K';
                  return Text(label,
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const Text('');
                  }
                  return Text(
                    '${data[index].date.day}/${data[index].date.month}',
                    style:
                        TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                  .toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInsights(BuildContext context, CustomerInsights insights, NumberFormat fmt) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatChip(
                'Tổng KH', '${insights.totalActive}', AppColors.info),
            const SizedBox(width: 8),
            _buildStatChip(
                'KH mới', '+${insights.newThisMonth}', AppColors.success),
            const SizedBox(width: 8),
            _buildStatChip(
                'KH rủi ro', '${insights.atRiskCount}', AppColors.error),
          ],
        ),
        const SizedBox(height: 12),
        // Tier distribution
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phân bổ tier',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...insights.tierDistribution.entries
                  .where((e) => e.value > 0)
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _tierColor(e.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(e.key.toUpperCase(),
                                style: const TextStyle(fontSize: 13)),
                            const Spacer(),
                            Text('${e.value}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Top 10 customers
        if (insights.top10Customers.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top 10 khách hàng (doanh thu)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...insights.top10Customers.asMap().entries.map((entry) {
                  final c = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text('${entry.key + 1}.',
                            style: TextStyle(
                                color: entry.key < 3
                                    ? Colors.amber.shade800
                                    : Colors.grey,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(c['name'] ?? '',
                                style: const TextStyle(fontSize: 13))),
                        Text(fmt.format(c['revenue'] ?? 0),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond':
        return Colors.blue;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      case 'bronze':
        return Colors.brown;
      default:
        return Colors.grey.shade300;
    }
  }
}
