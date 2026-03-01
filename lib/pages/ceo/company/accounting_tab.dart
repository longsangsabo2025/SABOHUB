import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/accounting.dart';
import '../../../models/company.dart';
import '../../../services/accounting_service.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/customer_avatar.dart';
import '../../../providers/auth_provider.dart';

/// Accounting Summary Provider
/// Caches summary data for 5 minutes to reduce API calls
final accountingSummaryProvider = FutureProvider.autoDispose.family<
    AccountingSummary,
    ({
      String companyId,
      DateTime startDate,
      DateTime endDate,
      String? branchId
    })>(
  (ref, params) async {
    // Cache for 5 minutes - balance between fresh data and performance
    final link = ref.keepAlive();
    Timer(const Duration(minutes: 5), () {
      link.close();
    });

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
final accountingTransactionsProvider = FutureProvider.autoDispose.family<
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
final dailyRevenueProvider = FutureProvider.autoDispose.family<
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
  TransactionType? _transactionTypeFilter;
  PaymentMethod? _paymentFilter;
  String? _statusFilter;
  String _transactionSearch = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
                    Row(
                      children: [
                        // Help/Guide button
                        Semantics(
                          label: 'Xem hướng dẫn sử dụng kế toán',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.help_outline,
                                color: Colors.orange),
                            tooltip: 'Hướng dẫn sử dụng',
                            onPressed: () => _showAccountingGuide(),
                          ),
                        ),
                        // Add transaction button
                        Semantics(
                          label: 'Thêm giao dịch kế toán mới',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Colors.blue),
                            tooltip: 'Thêm giao dịch',
                            onPressed: () => _showAddTransactionDialog(),
                          ),
                        ),
                      ],
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
              isScrollable: true,
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Giao dịch'),
                Tab(text: 'Doanh thu'),
                Tab(text: 'Công nợ'),
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
                _buildCongNoTab(),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
      loading: () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer for summary cards
            const ShimmerSummaryCards(itemCount: 3),
            const SizedBox(height: 16),
            // Shimmer for revenue chart
            const ShimmerChart(height: 200),
            const SizedBox(height: 16),
            // Shimmer for expense chart
            const ShimmerChart(height: 200),
            const SizedBox(height: 16),
            // Shimmer for transactions
            const ShimmerTransactionRow(itemCount: 5),
          ],
        ),
      ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                    if (value.toInt() >= 0 && value.toInt() < revenues.length) {
                      return Text(
                        DateFormat('dd/MM')
                            .format(revenues[value.toInt()].date),
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  color: Colors.blue.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.05),
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
    final counterparty = transaction.counterpartyName;
    final itemsSummary = transaction.itemsSummary;
    final statusLabel = _formatStatus(transaction.status);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (counterparty != null && counterparty.isNotEmpty)
            Text(
              'Khách: $counterparty',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (itemsSummary != null && itemsSummary.isNotEmpty)
            Text(
              'SP: $itemsSummary',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          if (statusLabel.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final transactionsAsync = ref.watch(
      accountingTransactionsProvider((
        companyId: widget.companyId,
        branchId: _selectedBranchId,
        startDate: _startDate,
        endDate: _endDate,
        type: _transactionTypeFilter,
      )),
    );

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Lỗi: $error')),
      data: (transactions) {
        final filtered = _applyTransactionFilters(transactions);
        final statusOptions = _collectStatusOptions(transactions);
        final grouped = _groupTransactionsByDate(filtered);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo khách, sản phẩm, mô tả...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _transactionSearch.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _transactionSearch = '';
                                  _searchController.clear();
                                });
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() => _transactionSearch = value.trim()),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Tất cả',
                          selected: _transactionTypeFilter == null,
                          onSelected: () => setState(() => _transactionTypeFilter = null),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Thu',
                          selected: _transactionTypeFilter == TransactionType.revenue,
                          onSelected: () => setState(() => _transactionTypeFilter = TransactionType.revenue),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Chi',
                          selected: _transactionTypeFilter == TransactionType.expense,
                          onSelected: () => setState(() => _transactionTypeFilter = TransactionType.expense),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Tất cả HTTT',
                          selected: _paymentFilter == null,
                          onSelected: () => setState(() => _paymentFilter = null),
                        ),
                        const SizedBox(width: 6),
                        ...PaymentMethod.values.map((method) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildFilterChip(
                              label: method.label,
                              selected: _paymentFilter == method,
                              onSelected: () => setState(() => _paymentFilter = method),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Tất cả trạng thái',
                          selected: _statusFilter == null,
                          onSelected: () => setState(() => _statusFilter = null),
                        ),
                        const SizedBox(width: 6),
                        ...statusOptions.map((status) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildFilterChip(
                              label: _formatStatus(status),
                              selected: _statusFilter == status,
                              onSelected: () => setState(() => _statusFilter = status),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: grouped.isEmpty
                  ? const Center(child: Text('Không có giao dịch phù hợp'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: grouped.entries.map((entry) {
                        final dateLabel = DateFormat('dd/MM/yyyy').format(entry.key);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 8),
                              child: Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...entry.value.map(_buildTransactionItem),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueTab() {
    return const Center(child: Text('Quản lý doanh thu'));
  }

  // =============================================
  // CÔNG NỢ TAB - Receivables for this company
  // =============================================
  Widget _buildCongNoTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadCompanyCongNo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                const SizedBox(height: 16),
                const Text('Không có công nợ phải thu',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }
        
        final data = snapshot.data!;
        final cf = NumberFormat('#,###', 'vi_VN');
        final totalOutstanding = (data['total_outstanding'] ?? 0).toDouble();
        final totalOverdue = (data['total_overdue'] ?? 0).toDouble();
        final customers = data['customers'] as List<Map<String, dynamic>>? ?? [];
        final aging = data['aging'] as Map<String, double>? ?? {};
        final overduePercent = totalOutstanding > 0 
            ? (totalOverdue / totalOutstanding * 100) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  _buildCongNoCard('Tổng công nợ', '${cf.format(totalOutstanding)} ₫',
                      Colors.orange, Icons.account_balance_wallet),
                  const SizedBox(width: 12),
                  _buildCongNoCard('Quá hạn', '${cf.format(totalOverdue)} ₫',
                      Colors.red, Icons.warning_amber_rounded,
                      subtitle: '${overduePercent.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCongNoCard('Khách hàng nợ', '${customers.length}',
                      Colors.blue, Icons.people),
                  const SizedBox(width: 12),
                  _buildCongNoCard('Trung bình/KH',
                      customers.isNotEmpty 
                          ? '${cf.format(totalOutstanding / customers.length)} ₫'
                          : '0 ₫',
                      Colors.purple, Icons.analytics),
                ],
              ),
              
              // Aging distribution bar
              if (totalOutstanding > 0) ...[
                const SizedBox(height: 20),
                const Text('Phân bổ tuổi nợ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildAgingBarCompany(aging, totalOutstanding),
              ],

              // Aging pie chart
              if (totalOutstanding > 0) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _buildAgingPieSections(aging, totalOutstanding),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ],

              // Top customers
              const SizedBox(height: 20),
              const Text('Top khách hàng nợ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...customers.take(10).map((c) {
                final custOutstanding = (c['outstanding'] ?? 0).toDouble();
                final custOverdue = (c['overdue_amount'] ?? 0).toDouble();
                final pct = totalOutstanding > 0 ? custOutstanding / totalOutstanding : 0.0;
                final isOverdue = custOverdue > 0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isOverdue ? Border.all(color: Colors.red.shade100) : null,
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6, offset: const Offset(0, 2),
                    )],
                  ),
                  child: Row(
                    children: [
                      CustomerAvatar(
                        seed: c['name'] ?? 'K',
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] ?? '', 
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${(pct * 100).toStringAsFixed(1)}% tổng nợ',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${cf.format(custOutstanding)} ₫',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13,
                                color: isOverdue ? Colors.red.shade700 : Colors.orange.shade700,
                              )),
                          if (isOverdue)
                            Text('QH: ${cf.format(custOverdue)} ₫',
                                style: TextStyle(fontSize: 10, color: Colors.red.shade400)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadCompanyCongNo() async {
    try {
      final supabase = SupabaseService().client;
      
      final data = await supabase
          .from('v_receivables_aging')
          .select('customer_id, customer_name, balance, aging_bucket, days_overdue')
          .eq('company_id', widget.companyId);
      
      if (data.isEmpty) return {};
      
      double totalOutstanding = 0;
      double totalOverdue = 0;
      final aging = <String, double>{
        'current': 0, '1-30': 0, '31-60': 0, '61-90': 0, '90+': 0
      };
      final customerMap = <String, Map<String, dynamic>>{};
      
      for (final r in data) {
        final bal = ((r['balance'] ?? 0) as num).toDouble();
        final bucket = r['aging_bucket']?.toString() ?? 'current';
        final daysOverdue = ((r['days_overdue'] ?? 0) as num).toInt();
        final custId = r['customer_id'].toString();
        
        totalOutstanding += bal;
        aging[bucket] = (aging[bucket] ?? 0) + bal;
        
        customerMap.putIfAbsent(custId, () => {
          'name': r['customer_name'] ?? 'N/A',
          'outstanding': 0.0,
          'overdue_amount': 0.0,
        });
        customerMap[custId]!['outstanding'] = 
            (customerMap[custId]!['outstanding'] as double) + bal;
        
        if (daysOverdue > 0) {
          totalOverdue += bal;
          customerMap[custId]!['overdue_amount'] = 
              (customerMap[custId]!['overdue_amount'] as double) + bal;
        }
      }
      
      final customers = customerMap.values.toList()
        ..sort((a, b) => (b['outstanding'] as double).compareTo(a['outstanding'] as double));
      
      return {
        'total_outstanding': totalOutstanding,
        'total_overdue': totalOverdue,
        'customers': customers,
        'aging': aging,
      };
    } catch (e) {
      return {};
    }
  }

  Widget _buildCongNoCard(String title, String value, MaterialColor color, 
      IconData icon, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8,
            offset: const Offset(0, 2),
          )],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color.shade700, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color.shade700)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 10, color: color.shade400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingBarCompany(Map<String, double> aging, double total) {
    final buckets = [
      ('Chưa hạn', aging['current'] ?? 0, Colors.green),
      ('1-30 ngày', aging['1-30'] ?? 0, Colors.yellow.shade700),
      ('31-60', aging['31-60'] ?? 0, Colors.orange),
      ('61-90', aging['61-90'] ?? 0, Colors.deepOrange),
      ('>90 ngày', aging['90+'] ?? 0, Colors.red),
    ];
    
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: buckets.map((b) {
                final pct = total > 0 ? b.$2 / total : 0.0;
                if (pct <= 0) return const SizedBox.shrink();
                return Expanded(
                  flex: (pct * 1000).round().clamp(1, 1000),
                  child: Container(color: b.$3),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: buckets.where((b) => b.$2 > 0).map((b) {
            final cf = NumberFormat.compact(locale: 'vi');
            final pct = total > 0 ? (b.$2 / total * 100).toStringAsFixed(0) : '0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: b.$3, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${b.$1}: ${cf.format(b.$2)}₫ ($pct%)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildAgingPieSections(Map<String, double> aging, double total) {
    final items = [
      ('Chưa hạn', aging['current'] ?? 0, Colors.green.shade400),
      ('1-30d', aging['1-30'] ?? 0, Colors.yellow.shade600),
      ('31-60d', aging['31-60'] ?? 0, Colors.orange.shade400),
      ('61-90d', aging['61-90'] ?? 0, Colors.deepOrange.shade400),
      ('>90d', aging['90+'] ?? 0, Colors.red.shade400),
    ];
    
    return items
        .where((i) => i.$2 > 0)
        .map((i) {
          final pct = total > 0 ? i.$2 / total * 100 : 0.0;
          return PieChartSectionData(
            value: i.$2,
            title: '${pct.toStringAsFixed(0)}%',
            color: i.$3,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          );
        })
        .toList();
  }

  Widget _buildReportsTab() {
    return const Center(child: Text('Báo cáo tài chính'));
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.blue.withValues(alpha: 0.15),
      side: BorderSide(color: selected ? Colors.blue : Colors.grey.shade300),
    );
  }

  List<AccountingTransaction> _applyTransactionFilters(
    List<AccountingTransaction> transactions,
  ) {
    final search = _transactionSearch.toLowerCase();
    return transactions.where((t) {
      if (_paymentFilter != null && t.paymentMethod != _paymentFilter) {
        return false;
      }
      if (_statusFilter != null && t.status != _statusFilter) {
        return false;
      }
      if (search.isEmpty) return true;

      final haystack = [
        t.description,
        t.referenceId,
        t.notes,
        t.counterpartyName,
        t.itemsSummary,
      ].where((v) => v != null).join(' ').toLowerCase();

      return haystack.contains(search);
    }).toList();
  }

  Map<DateTime, List<AccountingTransaction>> _groupTransactionsByDate(
    List<AccountingTransaction> transactions,
  ) {
    final Map<DateTime, List<AccountingTransaction>> grouped = {};
    for (final transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(transaction);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  List<String> _collectStatusOptions(List<AccountingTransaction> transactions) {
    final statusSet = <String>{};
    for (final transaction in transactions) {
      final status = transaction.status;
      if (status != null && status.isNotEmpty) {
        statusSet.add(status);
      }
    }
    final statuses = statusSet.toList();
    statuses.sort();
    return statuses;
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'pending':
        return 'Đang xử lý';
      case 'approved':
        return 'Đã duyệt';
      case 'completed':
        return 'Hoàn tất';
      default:
        return status ?? '';
    }
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
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    TransactionType selectedType = TransactionType.expense;
    PaymentMethod selectedPayment = PaymentMethod.cash;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm giao dịch mới'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type
                  const Text(
                    'Loại giao dịch *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TransactionType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: TransactionType.values.map((type) {
                      final icons = {
                        TransactionType.revenue: Icons.attach_money,
                        TransactionType.expense: Icons.money_off,
                        TransactionType.salary: Icons.payments,
                        TransactionType.utility: Icons.electrical_services,
                        TransactionType.maintenance: Icons.build,
                        TransactionType.other: Icons.more_horiz,
                      };
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(icons[type],
                                size: 20, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(type.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền *',
                      border: OutlineInputBorder(),
                      prefixText: '₫ ',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số tiền';
                      }
                      if (double.tryParse(value.replaceAll(',', '')) == null) {
                        return 'Số tiền không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  const Text(
                    'Phương thức thanh toán *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PaymentMethod>(
                    initialValue: selectedPayment,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: PaymentMethod.values.map((method) {
                      final icons = {
                        PaymentMethod.cash: Icons.money,
                        PaymentMethod.bank: Icons.account_balance,
                        PaymentMethod.card: Icons.credit_card,
                        PaymentMethod.momo: Icons.phone_android,
                        PaymentMethod.other: Icons.more_horiz,
                      };
                      return DropdownMenuItem(
                        value: method,
                        child: Row(
                          children: [
                            Icon(icons[method],
                                size: 20, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(method.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedPayment = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date
                  const Text(
                    'Ngày giao dịch *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                      hintText: 'Nhập mô tả chi tiết...',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mô tả';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final amount = double.parse(
                      amountController.text.replaceAll(',', ''),
                    );

                    final service = AccountingService();
                    final userId = ref.read(authProvider).user?.id;

                    if (userId == null) {
                      throw Exception('User not authenticated');
                    }

                    await service.createTransaction(
                      companyId: widget.companyId,
                      branchId: _selectedBranchId,
                      type: selectedType,
                      amount: amount,
                      paymentMethod: selectedPayment,
                      description: descriptionController.text.trim(),
                      date: selectedDate,
                      createdBy: userId,
                    );

                    // Refresh data
                    ref.invalidate(accountingSummaryProvider);
                    ref.invalidate(accountingTransactionsProvider);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Đã thêm giao dịch thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountingGuide() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Hướng dẫn Kế toán Doanh nghiệp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.blue[700],
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue[700],
                        tabs: const [
                          Tab(text: '📚 Kiến thức cơ bản'),
                          Tab(text: '🎯 Hướng dẫn sử dụng'),
                          Tab(text: '💡 Tips & Tricks'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildBasicKnowledgeTab(),
                            _buildUsageGuideTab(),
                            _buildTipsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicKnowledgeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuideSection(
            '💰 Doanh thu là gì?',
            'Doanh thu là tổng số tiền mà doanh nghiệp thu được từ hoạt động kinh doanh chính.',
            [
              '• Thu từ khách hàng (bàn bi-a, đồ uống, dịch vụ)',
              '• Doanh thu theo ngày, tháng, quý',
              '• Doanh thu trước thuế và phí',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '💸 Chi phí là gì?',
            'Chi phí là tổng số tiền doanh nghiệp phải chi ra để duy trì hoạt động.',
            [
              '• Lương nhân viên',
              '• Tiền điện, nước, internet (Tiện ích)',
              '• Sửa chữa, bảo trì thiết bị',
              '• Mua sắm hàng hóa, vật tư',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '💵 Lợi nhuận là gì?',
            'Lợi nhuận = Doanh thu - Chi phí',
            [
              '• Lợi nhuận dương: Kinh doanh có lãi',
              '• Lợi nhuận âm: Kinh doanh thua lỗ',
              '• Mục tiêu: Tối đa hóa lợi nhuận',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '📊 Biên lợi nhuận là gì?',
            'Biên lợi nhuận = (Lợi nhuận / Doanh thu) × 100%',
            [
              '• Đo lường hiệu quả kinh doanh',
              '• Biên cao: Kinh doanh hiệu quả',
              '• Biên thấp: Cần tối ưu chi phí',
              '• Ví dụ: Biên 20% = cứ 100đ doanh thu thì lãi 20đ',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '📝 Các loại giao dịch',
            'Phân loại giao dịch giúp theo dõi tiền bạc rõ ràng:',
            [
              '• 💰 Doanh thu: Tiền thu vào',
              '• 💸 Chi phí: Chi phí chung',
              '• 💼 Lương: Chi trả lương nhân viên',
              '• ⚡ Tiện ích: Điện, nước, internet',
              '• 🔧 Bảo trì: Sửa chữa thiết bị',
              '• 📦 Khác: Chi phí khác',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '💳 Phương thức thanh toán',
            'Theo dõi cách khách hàng thanh toán:',
            [
              '• 💵 Tiền mặt',
              '• 🏦 Chuyển khoản ngân hàng',
              '• 💳 Thẻ tín dụng/ghi nợ',
              '• 📱 MoMo, ZaloPay',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuideSection(
            '1️⃣ Xem tổng hợp tài chính',
            'Các thẻ ở đầu trang hiển thị tổng quan:',
            [
              '• 💰 Doanh thu: Tổng tiền thu vào trong kỳ',
              '• 💸 Chi phí: Tổng tiền chi ra trong kỳ',
              '• 💵 Lợi nhuận: = Doanh thu - Chi phí',
              '• 📊 Biên lợi nhuận: % lợi nhuận/doanh thu',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '2️⃣ Chọn khoảng thời gian',
            'Sử dụng bộ lọc thời gian để xem báo cáo:',
            [
              '• Click vào 📅 để chọn khoảng thời gian tùy chỉnh',
              '• Hoặc dùng quick filters:',
              '  - "Tuần này": 7 ngày gần nhất',
              '  - "Tháng này": 30 ngày gần nhất',
              '  - "Quý này": 90 ngày gần nhất',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '3️⃣ Tab Tổng quan',
            'Xem biểu đồ và phân tích:',
            [
              '• 📈 Biểu đồ xu hướng doanh thu theo ngày',
              '• 🥧 Phân bổ chi phí theo danh mục',
              '• 📋 5 giao dịch gần đây',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '4️⃣ Tab Giao dịch',
            'Quản lý chi tiết các giao dịch:',
            [
              '• Xem danh sách giao dịch',
              '• Lọc theo loại, thời gian',
              '• Thêm giao dịch mới (nút ➕)',
              '• Sửa/xóa giao dịch',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '5️⃣ Tab Doanh thu',
            'Quản lý doanh thu hàng ngày:',
            [
              '• Nhập doanh thu theo ngày',
              '• Phân bổ theo chi nhánh',
              '• Ghi chú số bàn, số khách',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '6️⃣ Tab Báo cáo',
            'Xuất báo cáo tài chính:',
            [
              '• Báo cáo thu chi',
              '• Báo cáo lãi lỗ',
              '• Xuất PDF/Excel',
              '• Gửi email báo cáo',
            ],
          ),
          const SizedBox(height: 20),
          _buildGuideSection(
            '➕ Thêm giao dịch mới',
            'Click nút ➕ ở góc trên bên phải:',
            [
              '1. Chọn loại giao dịch (Thu/Chi)',
              '2. Nhập số tiền',
              '3. Chọn phương thức thanh toán',
              '4. Thêm mô tả chi tiết',
              '5. Chọn ngày giao dịch',
              '6. Lưu giao dịch',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipCard(
            '✅ Nhập dữ liệu đều đặn',
            'Hãy nhập doanh thu và chi phí hàng ngày để có báo cáo chính xác.',
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '📊 Theo dõi biên lợi nhuận',
            'Biên lợi nhuận giảm = cần giảm chi phí hoặc tăng giá. Mục tiêu: Biên > 20%',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '💡 Phân loại chi phí rõ ràng',
            'Chia chi phí thành: Lương, Tiện ích, Bảo trì... để dễ quản lý và tối ưu.',
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '📅 So sánh theo tháng',
            'So sánh doanh thu tháng này vs tháng trước để thấy xu hướng tăng/giảm.',
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '🎯 Đặt mục tiêu cụ thể',
            'Đặt mục tiêu doanh thu/lợi nhuận cho từng tháng, quý để có động lực.',
            Colors.teal,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '📝 Ghi chú chi tiết',
            'Thêm ghi chú cho mỗi giao dịch để sau này dễ nhớ và tra cứu.',
            Colors.indigo,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '🔍 Kiểm tra dữ liệu',
            'Cuối ngày, đối chiếu số tiền thực tế với số liệu đã nhập để tránh sai sót.',
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '📊 Xuất báo cáo định kỳ',
            'Mỗi tháng xuất báo cáo để lưu trữ và phân tích xu hướng dài hạn.',
            Colors.brown,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '💰 Quản lý tiền mặt',
            'Theo dõi tiền mặt vs chuyển khoản để biết luồng tiền của doanh nghiệp.',
            Colors.green[700]!,
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            '⚡ Tối ưu chi phí tiện ích',
            'Chi phí điện, nước thường chiếm 10-15% doanh thu. Nên tiết kiệm năng lượng.',
            Colors.amber,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Công thức vàng trong kinh doanh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '📈 Tăng doanh thu:\n'
                  '   • Chăm sóc khách hàng tốt\n'
                  '   • Marketing hiệu quả\n'
                  '   • Mở rộng dịch vụ\n\n'
                  '💸 Giảm chi phí:\n'
                  '   • Tối ưu quy trình\n'
                  '   • Tiết kiệm năng lượng\n'
                  '   • Đàm phán nhà cung cấp\n\n'
                  '📊 Kết quả = Lợi nhuận tối đa! 🎯',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(
      String title, String description, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                point,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildTipCard(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
