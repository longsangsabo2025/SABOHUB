import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';

final _revenueDataProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final supabase = Supabase.instance.client;
  final user = ref.read(authProvider).user;
  final companyId = user?.companyId;

  final startDate =
      DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T').first;

  var query = supabase
      .from('daily_revenue')
      .select('*')
      .gte('date', startDate)
      .order('date', ascending: true);

  if (companyId != null) {
    query = query.eq('company_id', companyId);
  }

  final response = await query;
  return List<Map<String, dynamic>>.from(response);
});

class RevenueDashboardPage extends ConsumerStatefulWidget {
  const RevenueDashboardPage({super.key});

  @override
  ConsumerState<RevenueDashboardPage> createState() =>
      _RevenueDashboardPageState();
}

class _RevenueDashboardPageState extends ConsumerState<RevenueDashboardPage> {
  final _cf = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final _nf = NumberFormat('#,###', 'vi_VN');
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(_revenueDataProvider(_selectedDays));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Doanh thu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: revenueAsync.when(
        data: (data) => _buildBody(data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> data) {
    final totalRevenue = data.fold<double>(
        0, (s, d) => s + ((d['total_revenue'] as num?)?.toDouble() ?? 0));
    final totalOrders =
        data.fold<int>(0, (s, d) => s + ((d['total_orders'] as num?)?.toInt() ?? 0));
    final totalCustomers = data.fold<int>(
        0, (s, d) => s + ((d['total_customers'] as num?)?.toInt() ?? 0));
    final avgDaily = data.isNotEmpty ? totalRevenue / data.length : 0.0;

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(_revenueDataProvider(_selectedDays)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildSummaryCards(totalRevenue, totalOrders, totalCustomers, avgDaily),
            const SizedBox(height: 20),
            _buildRevenueChart(data),
            const SizedBox(height: 20),
            _buildDailyTable(data),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [7, 30, 90].map((d) {
        final isSelected = _selectedDays == d;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(d == 7 ? '7 ngày' : d == 30 ? '30 ngày' : '90 ngày'),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedDays = d),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(
      double revenue, int orders, int customers, double avgDaily) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard('Tổng doanh thu', _cf.format(revenue), Icons.attach_money,
            Colors.green),
        _statCard('Đơn hàng', _nf.format(orders), Icons.receipt_long,
            Colors.blue),
        _statCard('Khách hàng', _nf.format(customers), Icons.people,
            Colors.purple),
        _statCard('TB/ngày', _cf.format(avgDaily), Icons.trending_up,
            Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Chưa có dữ liệu doanh thu',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final rev = (data[i]['total_revenue'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), rev / 1000000));
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Biểu đồ doanh thu (triệu ₫)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.1),
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

  Widget _buildDailyTable(List<Map<String, dynamic>> data) {
    final reversed = data.reversed.take(10).toList();
    if (reversed.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết gần đây',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...reversed.map((d) {
            final date = d['date'] as String? ?? '';
            final rev = (d['total_revenue'] as num?)?.toDouble() ?? 0;
            final orders = (d['total_orders'] as num?)?.toInt() ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                      width: 90,
                      child: Text(date,
                          style: const TextStyle(fontSize: 13))),
                  Expanded(
                    child: Text(_cf.format(rev),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Text('$orders đơn',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
