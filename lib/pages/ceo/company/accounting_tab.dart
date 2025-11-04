import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/accounting.dart';
import '../../../models/company.dart';
import '../../../services/accounting_service.dart';

/// Accounting Summary Provider
final accountingSummaryProvider = FutureProvider.family<
    AccountingSummary,
    ({String companyId, DateTime startDate, DateTime endDate, String? branchId})>(
  (ref, params) async {
    final service = AccountingService();
    return await service.getSummary(
      companyId: params.companyId,
      startDate: params.startDate,
      endDate: params.endDate,
      branchId: params.branchId,
    );
  },
);

/// Transactions Provider
final accountingTransactionsProvider = FutureProvider.family<
    List<AccountingTransaction>,
    ({
      String companyId,
      String? branchId,
      DateTime? startDate,
      DateTime? endDate,
      TransactionType? type
    })>(
  (ref, params) async {
    final service = AccountingService();
    return await service.getTransactions(
      companyId: params.companyId,
      branchId: params.branchId,
      startDate: params.startDate,
      endDate: params.endDate,
      type: params.type,
    );
  },
);

/// Daily Revenue Provider
final dailyRevenueProvider = FutureProvider.family<
    List<DailyRevenue>,
    ({
      String companyId,
      String? branchId,
      DateTime? startDate,
      DateTime? endDate
    })>(
  (ref, params) async {
    final service = AccountingService();
    return await service.getDailyRevenue(
      companyId: params.companyId,
      branchId: params.branchId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  },
);

/// Accounting Tab for Company Details
class AccountingTab extends ConsumerStatefulWidget {
  final Company company;
  final String companyId;

  const AccountingTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  ConsumerState<AccountingTab> createState() => _AccountingTabState();
}

class _AccountingTabState extends ConsumerState<AccountingTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedBranchId;

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
    final summaryAsync = ref.watch(
      accountingSummaryProvider((
        companyId: widget.companyId,
        startDate: _startDate,
        endDate: _endDate,
        branchId: _selectedBranchId,
      )),
    );

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header with filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '💰 Kế toán doanh nghiệp',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: () => _showAddTransactionDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date range selector
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () => _selectDateRange(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick filters
                    _buildQuickFilter('Tuần này', 7),
                    const SizedBox(width: 4),
                    _buildQuickFilter('Tháng này', 30),
                    const SizedBox(width: 4),
                    _buildQuickFilter('Quý này', 90),
                  ],
                ),
              ],
            ),
          ),

          // Summary cards
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Lỗi: $error'),
            ),
            data: (summary) => _buildSummaryCards(summary),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Giao dịch'),
                Tab(text: 'Doanh thu'),
                Tab(text: 'Báo cáo'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(summaryAsync),
                _buildTransactionsTab(),
                _buildRevenueTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(String label, int days) {
    return TextButton(
      onPressed: () {
        setState(() {
          _endDate = DateTime.now();
          _startDate = _endDate.subtract(Duration(days: days));
        });
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildSummaryCards(AccountingSummary summary) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              '💰 Doanh thu',
              summary.formattedRevenue,
              Colors.green,
              Icons.trending_up,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              '💸 Chi phí',
              summary.formattedExpense,
              Colors.orange,
              Icons.trending_down,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              '💵 Lợi nhuận',
              summary.formattedNetProfit,
              summary.netProfit >= 0 ? Colors.blue : Colors.red,
              Icons.account_balance_wallet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              '📊 Biên lợi nhuận',
              summary.formattedProfitMargin,
              Colors.purple,
              Icons.pie_chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AsyncValue<AccountingSummary> summaryAsync) {
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Lỗi: $error')),
      data: (summary) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue trend chart
            _buildChartCard(
              'Xu hướng doanh thu',
              Icons.show_chart,
              _buildRevenueTrendChart(),
            ),
            const SizedBox(height: 16),
            // Expense breakdown
            _buildExpenseBreakdownCard(),
            const SizedBox(height: 16),
            // Recent transactions
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, IconData icon, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildRevenueTrendChart() {
    final revenueAsync = ref.watch(
      dailyRevenueProvider((
        companyId: widget.companyId,
        branchId: _selectedBranchId,
        startDate: _startDate,
        endDate: _endDate,
      )),
    );

    return revenueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Lỗi: $error')),
      data: (revenues) {
        if (revenues.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu'));
        }

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      NumberFormat.compact(locale: 'vi').format(value),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < revenues.length) {
                      return Text(
                        DateFormat('dd/MM').format(revenues[value.toInt()].date),
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: revenues.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.amount,
                  );
                }).toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Phân bổ chi phí',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Expense breakdown list
          _buildExpenseItem('Lương nhân viên', 45000000, Colors.blue),
          _buildExpenseItem('Tiện ích', 8000000, Colors.orange),
          _buildExpenseItem('Bảo trì', 3000000, Colors.green),
          _buildExpenseItem('Khác', 2000000, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            NumberFormat.currency(
              locale: 'vi_VN',
              symbol: '₫',
              decimalDigits: 0,
            ).format(amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactionsAsync = ref.watch(
      accountingTransactionsProvider((
        companyId: widget.companyId,
        branchId: _selectedBranchId,
        startDate: _startDate,
        endDate: _endDate,
        type: null,
      )),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Giao dịch gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          transactionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Lỗi: $error'),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(child: Text('Chưa có giao dịch'));
              }
              return Column(
                children: transactions.take(5).map((transaction) {
                  return _buildTransactionItem(transaction);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(AccountingTransaction transaction) {
    final isExpense = transaction.type != TransactionType.revenue;
    final color = isExpense ? Colors.red : Colors.green;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        '${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(transaction.amount)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return const Center(child: Text('Danh sách giao dịch chi tiết'));
  }

  Widget _buildRevenueTab() {
    return const Center(child: Text('Quản lý doanh thu'));
  }

  Widget _buildReportsTab() {
    return const Center(child: Text('Báo cáo tài chính'));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm giao dịch'),
        content: const Text('Chức năng đang phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
