import 'package:flutter/material.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ceo_business_provider.dart';
import '../manager/employee_performance_page.dart';
import 'daily_reports_dashboard_page.dart';

/// CEO Analytics Page
/// Advanced analytics and insights for all stores
class CEOAnalyticsPage extends ConsumerStatefulWidget {
  const CEOAnalyticsPage({super.key});

  @override
  ConsumerState<CEOAnalyticsPage> createState() => _CEOAnalyticsPageState();
}

class _CEOAnalyticsPageState extends ConsumerState<CEOAnalyticsPage> {
  int _selectedTab = 0;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildPeriodSelector(),
          _buildTabBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final periodName = {
          'week': 'tuần này',
          'month': 'tháng này',
          'quarter': 'quý này',
          'year': 'năm này',
        }[selectedPeriod] ??
        'tháng này';

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Phân tích dữ liệu',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đang tải xuống báo cáo $periodName...'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          },
          icon: const Icon(Icons.file_download, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chia sẻ báo cáo phân tích $periodName'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          },
          icon: const Icon(Icons.share, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          'Tuần này',
          'Tháng này',
          'Quý này',
          'Năm này',
        ].map((period) => _buildPeriodChip(period)).toList(),
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final periodMap = {
      'Tuần này': 'week',
      'Tháng này': 'month',
      'Quý này': 'quarter',
      'Năm này': 'year',
    };

    final isSelected = selectedPeriod == periodMap[period];
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedPeriodProvider.notifier).set(periodMap[period]!);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('Doanh thu', 0),
          _buildTab('Khách hàng', 1),
          _buildTab('Hiệu suất', 2),
          _buildTab('Báo cáo', 3),
          _buildTab('So sánh', 4),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color:
                  isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildRevenueAnalytics();
      case 1:
        return _buildCustomerAnalytics();
      case 2:
        return _buildPerformanceAnalytics();
      case 3:
        return _buildDailyReportsTab();
      case 4:
        return _buildComparisonAnalytics();
      default:
        return _buildRevenueAnalytics();
    }
  }

  Widget _buildRevenueAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueOverview(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildRevenueByCompany(),
        ],
      ),
    );
  }

  Widget _buildRevenueOverview() {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final revenueAsync = ref.watch(ceoPeriodRevenueProvider(selectedPeriod));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: revenueAsync.when(
        data: (data) {
          final totalRevenue =
              (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
          final growthPercentage =
              (data['growthPercentage'] as num?)?.toDouble() ?? 0.0;
          final isPositive = growthPercentage >= 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng doanh thu ${_getPeriodLabel(selectedPeriod)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(totalRevenue),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.red)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${growthPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'so với kỳ trước',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, stack) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng doanh thu',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              '₫0',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Không có dữ liệu',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'week':
        return 'tuần';
      case 'quarter':
        return 'quý';
      case 'year':
        return 'năm';
      case 'month':
      default:
        return 'tháng';
    }
  }

  Widget _buildRevenueChart() {
    final chartAsync = ref.watch(dailyRevenueChartProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biểu đồ doanh thu 30 ngày',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          chartAsync.when(
            data: (dataPoints) {
              if (dataPoints.isEmpty) {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const Text('Chưa có dữ liệu',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              final spots = dataPoints.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.revenue);
              }).toList();

              final maxY = spots
                  .map((s) => s.y)
                  .reduce((a, b) => a > b ? a : b);

              return SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                      getDrawingHorizontalLine: (_) => FlLine(
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
                            if (value >= 1000000) {
                              return Text(
                                '${(value / 1000000).toStringAsFixed(0)}M',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500),
                              );
                            }
                            if (value >= 1000) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}K',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500),
                              );
                            }
                            return Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (dataPoints.length / 6)
                              .ceilToDouble()
                              .clamp(1, 10),
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= dataPoints.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                DateFormat('dd/MM')
                                    .format(dataPoints[idx].date),
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary
                              .withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            final day = idx >= 0 &&
                                    idx < dataPoints.length
                                ? DateFormat('dd/MM')
                                    .format(dataPoints[idx].date)
                                : '';
                            return LineTooltipItem(
                              '$day\n${_formatRevenue(spot.y)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 200,
              child: Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByCompany() {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final revenueAsync = ref.watch(ceoPeriodRevenueProvider(selectedPeriod));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu theo công ty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          revenueAsync.when(
            data: (data) {
              final breakdown = (data['revenueBreakdown'] as List<dynamic>?)
                      ?.cast<Map<String, dynamic>>() ??
                  [];

              if (breakdown.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có dữ liệu doanh thu',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dữ liệu sẽ xuất hiện khi có phiên hoàn thành',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: breakdown
                    .map((company) => _buildCompanyRevenueItem(company))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Lỗi tải dữ liệu: ${error.toString()}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyRevenueItem(Map<String, dynamic> company) {
    final businessType = company['businessType'] as String? ?? 'billiards';
    final revenue = (company['revenue'] as num?)?.toDouble() ?? 0.0;
    final percentage = (company['percentage'] as num?)?.toDouble() ?? 0.0;
    final name = company['name'] as String? ?? 'Công ty';

    // Get color and icon based on business type
    final typeInfo = _getBusinessTypeInfo(businessType);
    final color = typeInfo['color'] as Color;
    final icon = typeInfo['icon'] as IconData;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatRevenue(revenue),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getBusinessTypeInfo(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return {'icon': Icons.restaurant, 'color': AppColors.success};
      case 'cafe':
        return {'icon': Icons.coffee, 'color': AppColors.primary};
      case 'billiards':
        return {'icon': Icons.sports_bar, 'color': AppColors.info};
      case 'karaoke':
        return {'icon': Icons.mic, 'color': const Color(0xFFEC4899)};
      case 'hotel':
        return {'icon': Icons.hotel, 'color': AppColors.warning};
      default:
        return {'icon': Icons.business, 'color': const Color(0xFF6366F1)};
    }
  }

  String _formatRevenue(double revenue) {
    if (revenue == 0) return '₫0';
    if (revenue >= 1000000000) {
      return '₫${(revenue / 1000000000).toStringAsFixed(1)}B';
    }
    if (revenue >= 1000000) {
      return '₫${(revenue / 1000000).toStringAsFixed(0)}M';
    }
    if (revenue >= 1000) {
      return '₫${(revenue / 1000).toStringAsFixed(0)}K';
    }
    return currencyFormat.format(revenue);
  }

  Widget _buildCustomerAnalytics() {
    final insightsAsync = ref.watch(customerInsightsProvider);
    final cf = NumberFormat('#,###', 'vi_VN');

    return insightsAsync.when(
      data: (insights) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Tổng khách hàng',
                    '${insights.totalActive}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    'KH mới tháng này',
                    '${insights.newThisMonth}',
                    Icons.person_add,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'KH có nguy cơ',
                    '${insights.atRiskCount}',
                    Icons.warning_amber,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    'Tổng công nợ',
                    '${cf.format(insights.totalDebt)}₫',
                    Icons.account_balance,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tier distribution
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phân bố khách hàng theo hạng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...insights.tierDistribution.entries.map((e) {
                    final total = insights.totalActive > 0
                        ? insights.totalActive
                        : 1;
                    final pct = (e.value / total * 100);
                    final tierColor = _getTierColor(e.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: tierColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getTierLabel(e.key),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${e.value} (${pct.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(tierColor),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Top 10 customers
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top 10 khách hàng (theo doanh thu)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (insights.top10Customers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Chưa có dữ liệu',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...insights.top10Customers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      final name = c['name'] ?? 'N/A';
                      final revenue = (c['revenue'] as num?)?.toDouble() ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i < 3
                                    ? Colors.amber.shade100
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: i < 3
                                      ? Colors.amber.shade800
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              currencyFormat.format(revenue),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'vip':
        return Colors.amber;
      case 'gold':
        return Colors.orange;
      case 'silver':
        return Colors.blueGrey;
      case 'bronze':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getTierLabel(String tier) {
    switch (tier.toLowerCase()) {
      case 'vip':
        return 'VIP';
      case 'gold':
        return 'Vàng';
      case 'silver':
        return 'Bạc';
      case 'bronze':
        return 'Đồng';
      default:
        return tier;
    }
  }

  Widget _buildPerformanceAnalytics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadPerformanceStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final totalEmployees = stats['total'] ?? 0;
        final avgScore = stats['avgScore'] ?? 0.0;
        final kpiAchieved = stats['kpiPercent'] ?? 0;
        final needsImprovement = stats['needsImprovement'] ?? 0;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPerformanceHeaderCard(),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: _buildQuickStatCard('Tổng nhân viên', '$totalEmployees', Icons.people, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildQuickStatCard('Điểm TB', avgScore is double ? avgScore.toStringAsFixed(1) : '$avgScore', Icons.star, Colors.amber)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildQuickStatCard('KPI đạt', '$kpiAchieved%', Icons.check_circle, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildQuickStatCard('Cần cải thiện', '$needsImprovement', Icons.trending_up, Colors.orange)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Click vào nút trên để xem bảng xếp hạng, KPI chi tiết và thực hiện đánh giá nhân viên',
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
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

  Future<Map<String, dynamic>> _loadPerformanceStats() async {
    try {
      final supabase = Supabase.instance.client;
      final user = ref.read(authProvider).user;
      if (user == null) return {};
      
      final companiesData = await supabase
          .from('companies')
          .select('id')
          .eq('owner_id', user.id);
      final companyIds = (companiesData as List).map((c) => c['id'] as String).toList();
      if (companyIds.isEmpty) return {};
      
      final empData = await supabase
          .from('employees')
          .select('id')
          .inFilter('company_id', companyIds)
          .eq('is_active', true);
      final total = (empData as List).length;
      
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final monthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String();
      
      final kpiData = await supabase
          .from('kpi_targets')
          .select('employee_id, target_value, current_value')
          .inFilter('company_id', companyIds)
          .gte('period_start', monthStart)
          .lte('period_start', monthEnd);
      
      final kpiList = kpiData as List;
      int achieved = 0;
      int needsImprovement = 0;
      double totalScore = 0;
      
      for (final kpi in kpiList) {
        final target = (kpi['target_value'] as num?)?.toDouble() ?? 0;
        final current = (kpi['current_value'] as num?)?.toDouble() ?? 0;
        final score = target > 0 ? (current / target * 100) : 0.0;
        totalScore += score;
        if (score >= 80) achieved++;
        else if (score < 50) needsImprovement++;
      }
      
      return {
        'total': total,
        'avgScore': kpiList.isNotEmpty ? totalScore / kpiList.length : 0.0,
        'kpiPercent': kpiList.isNotEmpty ? (achieved / kpiList.length * 100).round() : 0,
        'needsImprovement': needsImprovement,
      };
    } catch (e) {
      return {'total': 0, 'avgScore': 0.0, 'kpiPercent': 0, 'needsImprovement': 0};
    }
  }

  Widget _buildPerformanceHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.analytics, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Đánh giá hiệu suất nhân viên',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Theo dõi KPI, xếp hạng và đánh giá chi tiết',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeePerformancePage(),
                ),
              );
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Xem bảng KPI chi tiết'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.warning, AppColors.error],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Báo cáo cuối ngày nhân viên',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Xem tổng hợp báo cáo công việc của tất cả nhân viên',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DailyReportsDashboardPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Mở Dashboard báo cáo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Features List
          _buildFeatureCard(
            'Tự động tạo báo cáo',
            'Báo cáo được tạo tự động khi nhân viên checkout',
            Icons.auto_awesome,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            'AI Summary',
            'Tóm tắt thông minh ca làm việc và công việc hoàn thành',
            Icons.psychology,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            'Thống kê chi tiết',
            'Xem tỷ lệ nộp, giờ làm trung bình, công việc hoàn thành',
            Icons.analytics,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            'Lọc và tìm kiếm',
            'Lọc theo trạng thái, ngày, nhân viên, chi nhánh',
            Icons.filter_list,
            Colors.orange,
          ),
          const SizedBox(height: 24),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Click vào nút trên để xem dashboard báo cáo đầy đủ với bộ lọc và thống kê chi tiết',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonAnalytics() {
    final companyAsync = ref.watch(companyComparisonProvider);
    final cf = NumberFormat('#,###', 'vi_VN');

    return companyAsync.when(
      data: (companies) {
        if (companies.isEmpty) {
          return const Center(
            child: Text('Chưa có công ty nào',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: companies.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _comparisonStat(
                            'Doanh thu tháng',
                            '${cf.format(c.monthlyRevenue)}₫',
                            Icons.trending_up,
                            Colors.green),
                        _comparisonStat(
                            'Đơn hàng',
                            '${c.orderCount}',
                            Icons.receipt_long,
                            Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _comparisonStat(
                            'Nhân viên',
                            '${c.employeeCount}',
                            Icons.people,
                            Colors.purple),
                        _comparisonStat(
                            'Khách hàng',
                            '${c.customerCount}',
                            Icons.store,
                            Colors.orange),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _comparisonStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text(label,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
