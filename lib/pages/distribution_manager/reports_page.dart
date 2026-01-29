// Distribution Manager Reports Page
// Full-featured reports with real data connection

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/auth_provider.dart';

// ==================== REPORTS PAGE ====================
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.blue.shade700,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.trending_up, size: 20), text: 'Doanh thu'),
              Tab(icon: Icon(Icons.account_balance_wallet, size: 20), text: 'Công nợ'),
              Tab(icon: Icon(Icons.inventory_2, size: 20), text: 'Tồn kho'),
              Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'Đơn hàng'),
            ],
          ),
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _RevenueReportTab(),
              _ReceivablesReportTab(),
              _InventoryReportTab(),
              _OrdersReportTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== REVENUE REPORT TAB ====================
class _RevenueReportTab extends ConsumerStatefulWidget {
  const _RevenueReportTab();

  @override
  ConsumerState<_RevenueReportTab> createState() => _RevenueReportTabState();
}

class _RevenueReportTabState extends ConsumerState<_RevenueReportTab> {
  bool _isLoading = true;
  Map<String, dynamic> _revenueData = {};
  List<Map<String, dynamic>> _dailyRevenue = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get today's revenue
      final todayOrders = await supabase
          .from('sales_orders')
          .select('total')
          .eq('company_id', companyId)
          .gte('order_date', startOfDay.toIso8601String().split('T')[0])
          .inFilter('status', ['confirmed', 'processing', 'completed']);

      double todayRevenue = 0;
      for (var order in todayOrders) {
        todayRevenue += (order['total'] ?? 0).toDouble();
      }

      // Get this week's revenue
      final weekOrders = await supabase
          .from('sales_orders')
          .select('total')
          .eq('company_id', companyId)
          .gte('order_date', startOfWeek.toIso8601String().split('T')[0])
          .inFilter('status', ['confirmed', 'processing', 'completed']);

      double weekRevenue = 0;
      for (var order in weekOrders) {
        weekRevenue += (order['total'] ?? 0).toDouble();
      }

      // Get this month's revenue
      final monthOrders = await supabase
          .from('sales_orders')
          .select('total')
          .eq('company_id', companyId)
          .gte('order_date', startOfMonth.toIso8601String().split('T')[0])
          .inFilter('status', ['confirmed', 'processing', 'completed']);

      double monthRevenue = 0;
      int monthOrderCount = monthOrders.length;
      for (var order in monthOrders) {
        monthRevenue += (order['total'] ?? 0).toDouble();
      }

      // Get daily revenue for chart (last 7 days)
      final last7Days = now.subtract(const Duration(days: 6));
      final dailyOrders = await supabase
          .from('sales_orders')
          .select('order_date, total')
          .eq('company_id', companyId)
          .gte('order_date', last7Days.toIso8601String().split('T')[0])
          .inFilter('status', ['confirmed', 'processing', 'completed'])
          .order('order_date');

      // Group by date
      final Map<String, double> dailyMap = {};
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        dailyMap[dateStr] = 0;
      }

      for (var order in dailyOrders) {
        final date = order['order_date'] as String;
        final total = (order['total'] ?? 0).toDouble();
        if (dailyMap.containsKey(date)) {
          dailyMap[date] = (dailyMap[date] ?? 0) + total;
        }
      }

      final dailyList = dailyMap.entries.map((e) {
        return {'date': e.key, 'revenue': e.value};
      }).toList();

      // Get top customers this month with proper customer names
      final topCustomers = await supabase
          .from('sales_orders')
          .select('customer_id, total, customers(name, phone)')
          .eq('company_id', companyId)
          .gte('order_date', startOfMonth.toIso8601String().split('T')[0])
          .inFilter('status', ['confirmed', 'processing', 'completed']);

      final Map<String, Map<String, dynamic>> customerMap = {};
      for (var order in topCustomers) {
        final custId = order['customer_id'] as String?;
        final customerData = order['customers'] as Map<String, dynamic>?;
        final custName = customerData?['name'] as String? ?? 
                        customerData?['phone'] as String? ?? 
                        'Khách hàng #${custId?.substring(0, 8) ?? 'N/A'}';
        final total = (order['total'] ?? 0).toDouble();
        if (custId != null) {
          if (!customerMap.containsKey(custId)) {
            customerMap[custId] = {'name': custName, 'total': 0.0, 'count': 0};
          }
          customerMap[custId]!['total'] += total;
          customerMap[custId]!['count'] += 1;
        }
      }

      final topCustomersList = customerMap.values.toList()
        ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

      setState(() {
        _revenueData = {
          'today': todayRevenue,
          'week': weekRevenue,
          'month': monthRevenue,
          'monthOrders': monthOrderCount,
          'avgOrder': monthOrderCount > 0 ? monthRevenue / monthOrderCount : 0,
          'topCustomers': topCustomersList.take(5).toList(),
        };
        _dailyRevenue = dailyList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading revenue: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadRevenueData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Hôm nay',
                    currencyFormat.format(_revenueData['today'] ?? 0),
                    Icons.today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Tuần này',
                    currencyFormat.format(_revenueData['week'] ?? 0),
                    Icons.date_range,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Tháng này',
                    currencyFormat.format(_revenueData['month'] ?? 0),
                    Icons.calendar_month,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'TB/đơn hàng',
                    currencyFormat.format(_revenueData['avgOrder'] ?? 0),
                    Icons.shopping_cart,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Revenue Chart
            const Text(
              'Doanh thu 7 ngày qua',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _buildRevenueChart(),
            ),

            const SizedBox(height: 24),

            // Top Customers
            const Text(
              'Top khách hàng tháng này',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._buildTopCustomersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_dailyRevenue.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final maxRevenue = _dailyRevenue
        .map((e) => (e['revenue'] as double))
        .reduce((a, b) => a > b ? a : b);
    final interval = maxRevenue > 0 ? maxRevenue / 4 : 1.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                currencyFormat.format(rod.toY),
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _dailyRevenue.length) {
                  final date = _dailyRevenue[index]['date'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd/MM').format(DateTime.parse(date)),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: interval > 0 ? interval : 1,
              getTitlesWidget: (value, meta) {
                if (value >= 1000000) {
                  return Text(
                    '${(value / 1000000).toStringAsFixed(0)}M',
                    style: const TextStyle(fontSize: 10),
                  );
                } else if (value >= 1000) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _dailyRevenue.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value['revenue'] as double,
                color: Colors.blue.shade400,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildTopCustomersList() {
    final topCustomers =
        (_revenueData['topCustomers'] as List<dynamic>?) ?? [];

    if (topCustomers.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Chưa có đơn hàng trong tháng này'),
          ),
        ),
      ];
    }

    return topCustomers.asMap().entries.map((entry) {
      final index = entry.key;
      final customer = entry.value as Map<String, dynamic>;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: index == 0
                    ? Colors.amber
                    : index == 1
                        ? Colors.grey.shade400
                        : index == 2
                            ? Colors.brown.shade300
                            : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: index < 3 ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${customer['count']} đơn hàng',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              currencyFormat.format(customer['total']),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ==================== RECEIVABLES REPORT TAB ====================
class _ReceivablesReportTab extends ConsumerStatefulWidget {
  const _ReceivablesReportTab();

  @override
  ConsumerState<_ReceivablesReportTab> createState() =>
      _ReceivablesReportTabState();
}

class _ReceivablesReportTabState extends ConsumerState<_ReceivablesReportTab> {
  bool _isLoading = true;
  Map<String, dynamic> _receivablesData = {};
  List<Map<String, dynamic>> _customerDebts = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadReceivablesData();
  }

  Future<void> _loadReceivablesData() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Get all unpaid/partial orders with customer info
      final unpaidOrders = await supabase
          .from('sales_orders')
          .select('id, customer_id, total, order_date, payment_status, customers(name, phone, company_name)')
          .eq('company_id', companyId)
          .inFilter('payment_status', ['unpaid', 'partial'])
          .order('order_date', ascending: false);

      double totalReceivables = 0;
      double overdueAmount = 0;
      final now = DateTime.now();
      final Map<String, Map<String, dynamic>> customerDebtMap = {};

      for (var order in unpaidOrders) {
        final total = (order['total'] ?? 0).toDouble();
        totalReceivables += total;

        // Check if overdue (> 30 days)
        final orderDate = DateTime.parse(order['order_date'] as String);
        if (now.difference(orderDate).inDays > 30) {
          overdueAmount += total;
        }

        // Group by customer
        final custId = order['customer_id'] as String?;
        final customerData = order['customers'] as Map<String, dynamic>?;
        final custName = customerData?['company_name'] as String? ?? 
                        customerData?['name'] as String? ?? 
                        customerData?['phone'] as String? ?? 
                        'Khách hàng #${custId?.substring(0, 8) ?? 'N/A'}';
        if (custId != null) {
          if (!customerDebtMap.containsKey(custId)) {
            customerDebtMap[custId] = {
              'name': custName,
              'total': 0.0,
              'count': 0,
              'oldestDate': order['order_date'],
            };
          }
          customerDebtMap[custId]!['total'] += total;
          customerDebtMap[custId]!['count'] += 1;
        }
      }

      final customerDebtList = customerDebtMap.values.toList()
        ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

      setState(() {
        _receivablesData = {
          'total': totalReceivables,
          'overdue': overdueAmount,
          'customerCount': customerDebtMap.length,
          'orderCount': unpaidOrders.length,
        };
        _customerDebts = customerDebtList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading receivables: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadReceivablesData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Tổng công nợ',
                    currencyFormat.format(_receivablesData['total'] ?? 0),
                    Icons.account_balance_wallet,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Quá hạn (>30 ngày)',
                    currencyFormat.format(_receivablesData['overdue'] ?? 0),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Khách nợ',
                    '${_receivablesData['customerCount'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Đơn chưa TT',
                    '${_receivablesData['orderCount'] ?? 0}',
                    Icons.receipt,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Debt by Customer
            const Text(
              'Công nợ theo khách hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_customerDebts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 48, color: Colors.green),
                      SizedBox(height: 12),
                      Text('Không có công nợ!'),
                    ],
                  ),
                ),
              )
            else
              ..._customerDebts.map((customer) {
                final total = customer['total'] as double;
                final percentage = (_receivablesData['total'] as double) > 0
                    ? (total / (_receivablesData['total'] as double) * 100)
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            currencyFormat.format(total),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${customer['count']} đơn chưa TT',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 30 ? Colors.red : Colors.orange,
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
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ==================== INVENTORY REPORT TAB ====================
class _InventoryReportTab extends ConsumerStatefulWidget {
  const _InventoryReportTab();

  @override
  ConsumerState<_InventoryReportTab> createState() => _InventoryReportTabState();
}

class _InventoryReportTabState extends ConsumerState<_InventoryReportTab> {
  bool _isLoading = true;
  Map<String, dynamic> _inventoryData = {};
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Get all products with stock
      final products = await supabase
          .from('products')
          .select('id, name, sku, unit, selling_price, stock_quantity, min_stock_level')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('stock_quantity', ascending: true);

      int totalProducts = products.length;
      int totalStock = 0;
      double totalValue = 0;
      List<Map<String, dynamic>> lowStock = [];

      for (var product in products) {
        final qty = (product['stock_quantity'] ?? 0) as int;
        final price = (product['selling_price'] ?? 0).toDouble();
        final minLevel = (product['min_stock_level'] ?? 10) as int;

        totalStock += qty;
        totalValue += qty * price;

        if (qty <= minLevel) {
          lowStock.add(product);
        }
      }

      setState(() {
        _inventoryData = {
          'totalProducts': totalProducts,
          'totalStock': totalStock,
          'totalValue': totalValue,
          'lowStockCount': lowStock.length,
        };
        _products = List<Map<String, dynamic>>.from(products);
        _lowStockProducts = lowStock;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading inventory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadInventoryData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Tổng SP',
                    '${_inventoryData['totalProducts'] ?? 0}',
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Tổng tồn',
                    '${_inventoryData['totalStock'] ?? 0}',
                    Icons.warehouse,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Giá trị tồn',
                    currencyFormat.format(_inventoryData['totalValue'] ?? 0),
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Sắp hết hàng',
                    '${_inventoryData['lowStockCount'] ?? 0}',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Low Stock Alert
            if (_lowStockProducts.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sản phẩm sắp hết hàng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._lowStockProducts.take(5).map((product) {
                final qty = product['stock_quantity'] ?? 0;
                final minLevel = product['min_stock_level'] ?? 10;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory, color: Colors.red.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'SKU: ${product['sku'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$qty ${product['unit'] ?? ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: qty == 0 ? Colors.red : Colors.orange.shade700,
                            ),
                          ),
                          Text(
                            'Min: $minLevel',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // All Products
            const Text(
              'Tất cả sản phẩm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._products.take(10).map((product) {
              final qty = product['stock_quantity'] ?? 0;
              final isLow = qty <= (product['min_stock_level'] ?? 10);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'SKU: ${product['sku'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$qty ${product['unit'] ?? ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isLow ? Colors.red.shade700 : Colors.green.shade700,
                        ),
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
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ==================== ORDERS REPORT TAB ====================
class _OrdersReportTab extends ConsumerStatefulWidget {
  const _OrdersReportTab();

  @override
  ConsumerState<_OrdersReportTab> createState() => _OrdersReportTabState();
}

class _OrdersReportTabState extends ConsumerState<_OrdersReportTab> {
  bool _isLoading = true;
  Map<String, dynamic> _ordersData = {};
  Map<String, int> _statusCounts = {};
  List<Map<String, dynamic>> _recentOrders = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOrdersData();
  }

  Future<void> _loadOrdersData() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get all orders this month
      final monthOrders = await supabase
          .from('sales_orders')
          .select('id, status, total, order_date, customer_id, customers(name, company_name, phone)')
          .eq('company_id', companyId)
          .gte('order_date', startOfMonth.toIso8601String().split('T')[0])
          .order('created_at', ascending: false);

      // Count by status
      final Map<String, int> statusMap = {
        'draft': 0,
        'pending_approval': 0,
        'confirmed': 0,
        'processing': 0,
        'completed': 0,
        'cancelled': 0,
      };

      double totalValue = 0;
      int todayCount = 0;

      for (var order in monthOrders) {
        final status = order['status'] as String? ?? 'draft';
        statusMap[status] = (statusMap[status] ?? 0) + 1;
        totalValue += (order['total'] ?? 0).toDouble();

        final orderDate = order['order_date'] as String;
        if (orderDate == startOfDay.toIso8601String().split('T')[0]) {
          todayCount++;
        }
      }

      setState(() {
        _ordersData = {
          'totalOrders': monthOrders.length,
          'todayOrders': todayCount,
          'totalValue': totalValue,
          'completionRate': monthOrders.isNotEmpty
              ? ((statusMap['completed'] ?? 0) / monthOrders.length * 100)
              : 0.0,
        };
        _statusCounts = statusMap;
        _recentOrders = List<Map<String, dynamic>>.from(monthOrders.take(10));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadOrdersData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Tháng này',
                    '${_ordersData['totalOrders'] ?? 0}',
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Hôm nay',
                    '${_ordersData['todayOrders'] ?? 0}',
                    Icons.today,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Tổng giá trị',
                    currencyFormat.format(_ordersData['totalValue'] ?? 0),
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Hoàn thành',
                    '${(_ordersData['completionRate'] ?? 0).toStringAsFixed(0)}%',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status breakdown
            const Text(
              'Theo trạng thái',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildStatusRow('Nháp', _statusCounts['draft'] ?? 0, Colors.grey),
                  _buildStatusRow('Chờ duyệt', _statusCounts['pending_approval'] ?? 0, Colors.orange),
                  _buildStatusRow('Đã duyệt', _statusCounts['confirmed'] ?? 0, Colors.blue),
                  _buildStatusRow('Đang xử lý', _statusCounts['processing'] ?? 0, Colors.purple),
                  _buildStatusRow('Hoàn thành', _statusCounts['completed'] ?? 0, Colors.green),
                  _buildStatusRow('Đã hủy', _statusCounts['cancelled'] ?? 0, Colors.red),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Orders
            const Text(
              'Đơn hàng gần đây',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_recentOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('Chưa có đơn hàng')),
              )
            else
              ..._recentOrders.map((order) {
                final status = order['status'] as String? ?? 'draft';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              () {
                                final customerData = order['customers'] as Map<String, dynamic>?;
                                return customerData?['company_name'] as String? ?? 
                                       customerData?['name'] as String? ?? 
                                       customerData?['phone'] as String? ?? 
                                       'Khách hàng #${order['customer_id']?.toString().substring(0, 8) ?? 'N/A'}';
                              }(),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              order['order_date'] as String? ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(order['total'] ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getStatusText(status),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    final total = _ordersData['totalOrders'] ?? 1;
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'pending_approval':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Nháp';
      case 'pending_approval':
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã duyệt';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
