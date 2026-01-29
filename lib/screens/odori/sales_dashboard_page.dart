import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/odori_service.dart';
import '../../models/odori_models.dart';

/// Sales Dashboard Page - Analytics and KPIs for Flutter
class SalesDashboardPage extends ConsumerStatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  ConsumerState<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends ConsumerState<SalesDashboardPage> {
  String _selectedPeriod = '30d';
  bool _isLoading = true;
  
  // Stats
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalCustomers = 0;
  int _pendingDeliveries = 0;
  
  // Chart data
  List<DailySalesData> _dailySales = [];
  List<AgingBucket> _agingReport = [];

  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Calculate date range
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case '7d':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '30d':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'thisMonth':
          startDate = DateTime(now.year, now.month, 1);
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }

      // Fetch orders
      final orders = await odoriService.getOrders(
        fromDate: startDate,
        toDate: now,
      );
      
      // Fetch customers
      final customers = await odoriService.getCustomers();
      
      // Fetch deliveries
      final deliveries = await odoriService.getDeliveries(
        status: DeliveryStatus.pending,
      );
      
      // Fetch aging report
      final aging = await odoriService.getAgingReport();

      // Calculate stats
      _totalRevenue = orders.fold(0, (sum, o) => sum + o.totalAmount);
      _totalOrders = orders.length;
      _totalCustomers = customers.length;
      _pendingDeliveries = deliveries.length;

      // Group orders by date for chart
      final groupedByDate = <String, DailySalesData>{};
      for (final order in orders) {
        final dateStr = DateFormat('MM/dd').format(order.orderDate);
        if (!groupedByDate.containsKey(dateStr)) {
          groupedByDate[dateStr] = DailySalesData(
            date: dateStr,
            revenue: 0,
            orders: 0,
          );
        }
        groupedByDate[dateStr]!.revenue += order.totalAmount;
        groupedByDate[dateStr]!.orders += 1;
      }
      _dailySales = groupedByDate.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Parse aging report
      _agingReport = [
        AgingBucket('Chưa đến hạn', aging['current'] ?? 0, Colors.green),
        AgingBucket('1-30 ngày', aging['1_30_days'] ?? 0, Colors.yellow.shade700),
        AgingBucket('31-60 ngày', aging['31_60_days'] ?? 0, Colors.orange),
        AgingBucket('61-90 ngày', aging['61_90_days'] ?? 0, Colors.red),
        AgingBucket('90+ ngày', aging['over_90_days'] ?? 0, Colors.red.shade900),
      ];

      // TODO: Fetch top products (need to aggregate from order items)

    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo Kinh doanh'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('7 ngày qua')),
              const PopupMenuItem(value: '30d', child: Text('30 ngày qua')),
              const PopupMenuItem(value: 'thisMonth', child: Text('Tháng này')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards
                    _buildKPICards(),
                    const SizedBox(height: 24),
                    
                    // Revenue Chart
                    _buildSectionTitle('Xu hướng doanh thu'),
                    const SizedBox(height: 12),
                    _buildRevenueChart(),
                    const SizedBox(height: 24),
                    
                    // Aging Report
                    _buildSectionTitle('Phân tích tuổi nợ'),
                    const SizedBox(height: 12),
                    _buildAgingChart(),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPICards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          title: 'Doanh thu',
          value: _currencyFormat.format(_totalRevenue),
          icon: Icons.attach_money,
          color: Colors.green,
          trend: '+12.5%',
          trendUp: true,
        ),
        _buildKPICard(
          title: 'Đơn hàng',
          value: _totalOrders.toString(),
          icon: Icons.shopping_cart,
          color: Colors.blue,
          subtitle: 'TB: ${_currencyFormat.format(_totalOrders > 0 ? _totalRevenue / _totalOrders : 0)}',
        ),
        _buildKPICard(
          title: 'Khách hàng',
          value: _totalCustomers.toString(),
          icon: Icons.people,
          color: Colors.purple,
        ),
        _buildKPICard(
          title: 'Chờ giao',
          value: _pendingDeliveries.toString(),
          icon: Icons.local_shipping,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    String? trend,
    bool? trendUp,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trend != null)
                  Row(
                    children: [
                      Icon(
                        trendUp == true ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: trendUp == true ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 11,
                          color: trendUp == true ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  )
                else if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_dailySales.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final maxRevenue = _dailySales
        .map((e) => e.revenue)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxRevenue * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      _currencyFormat.format(rod.toY),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= _dailySales.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _dailySales[value.toInt()].date,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value / 1000000).toStringAsFixed(0)}M',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _dailySales.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.revenue,
                      color: Colors.blue,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgingChart() {
    final total = _agingReport.fold<double>(0, (sum, b) => sum + b.amount);
    
    if (total == 0) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green.shade300),
              const SizedBox(height: 8),
              const Text(
                'Không có công nợ!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: _agingReport.where((b) => b.amount > 0).map((bucket) {
                    final percentage = (bucket.amount / total) * 100;
                    return PieChartSectionData(
                      value: bucket.amount,
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: bucket.color,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _agingReport.map((bucket) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: bucket.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bucket.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                );
              }).toList(),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng công nợ:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _currencyFormat.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Thao tác nhanh'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.receipt_long,
                label: 'Tạo đơn hàng',
                color: Colors.blue,
                onTap: () {
                  // Navigate to create order
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.local_shipping,
                label: 'Xem giao hàng',
                color: Colors.orange,
                onTap: () {
                  // Navigate to deliveries
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.payments,
                label: 'Thu tiền',
                color: Colors.green,
                onTap: () {
                  // Navigate to payments
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_add,
                label: 'Thêm KH',
                color: Colors.purple,
                onTap: () {
                  // Navigate to add customer
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily sales data for charts
class DailySalesData {
  final String date;
  double revenue;
  int orders;

  DailySalesData({
    required this.date,
    required this.revenue,
    required this.orders,
  });
}

/// Top product data
class TopProductData {
  final String id;
  final String name;
  final int quantity;
  final double revenue;

  TopProductData({
    required this.id,
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

/// Aging bucket for receivables
class AgingBucket {
  final String label;
  final double amount;
  final Color color;

  AgingBucket(this.label, this.amount, this.color);
}
