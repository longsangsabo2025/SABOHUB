import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/sell_in_sell_out_service.dart';

/// Sell-In/Sell-Out Dashboard Page
class SellInSellOutPage extends ConsumerStatefulWidget {
  const SellInSellOutPage({super.key});

  @override
  ConsumerState<SellInSellOutPage> createState() => _SellInSellOutPageState();
}

class _SellInSellOutPageState extends ConsumerState<SellInSellOutPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesSummaryAsync = ref.watch(salesSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell-in / Sell-out'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng quan', icon: Icon(Icons.dashboard)),
            Tab(text: 'Sell-in', icon: Icon(Icons.input)),
            Tab(text: 'Sell-out', icon: Icon(Icons.output)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Lọc',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(salesSummaryAsync),
          _buildSellInTab(),
          _buildSellOutTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransaction(),
        icon: const Icon(Icons.add),
        label: const Text('Ghi nhận'),
      ),
    );
  }

  Widget _buildOverviewTab(AsyncValue<SalesSummary> summaryAsync) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            summaryAsync.when(
              data: (summary) => _buildSummaryCards(summary),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
            const SizedBox(height: 24),
            
            // Low Stock Alerts
            _buildLowStockSection(),
            const SizedBox(height: 24),
            
            // Sell-through Reports
            _buildSellThroughSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(SalesSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '30 ngày gần đây',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Sell-in',
                _currencyFormat.format(summary.totalSellIn),
                '${summary.sellInCount} giao dịch',
                Icons.input,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sell-out',
                _currencyFormat.format(summary.totalSellOut),
                '${summary.sellOutCount} giao dịch',
                Icons.output,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Sell-through Rate',
          '${summary.avgSellThrough.toStringAsFixed(1)}%',
          'Tỷ lệ bán ra trung bình',
          Icons.trending_up,
          summary.avgSellThrough >= 70 ? Colors.green : Colors.orange,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fullWidth ? 24 : 18,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection() {
    final lowStockAsync = ref.watch(lowStockAlertsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cảnh báo tồn kho thấp',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        lowStockAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[400]),
                      const SizedBox(width: 12),
                      const Text('Không có sản phẩm nào dưới mức tồn kho tối thiểu'),
                    ],
                  ),
                ),
              );
            }
            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red[50],
                      child: Icon(Icons.inventory_2, color: Colors.red[400]),
                    ),
                    title: Text(item.productName ?? 'Sản phẩm'),
                    subtitle: Text(item.distributorName ?? 'NPP'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.currentStock}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Tồn kho',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Lỗi: $e'),
        ),
      ],
    );
  }

  Widget _buildSellThroughSection() {
    final reportsAsync = ref.watch(sellThroughReportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Báo cáo Sell-through',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có báo cáo sell-through'),
                ),
              );
            }
            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final rate = report.sellThroughRate;
                  final rateColor = rate >= 80
                      ? Colors.green
                      : rate >= 50
                          ? Colors.orange
                          : Colors.red;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rateColor.withAlpha(30),
                      child: Text(
                        '${rate.toInt()}%',
                        style: TextStyle(
                          color: rateColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(report.distributorName ?? 'NPP'),
                    subtitle: Text(
                      '${DateFormat('dd/MM').format(report.periodStart)} - ${DateFormat('dd/MM').format(report.periodEnd)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('In: ${report.totalSellIn}'),
                        Text('Out: ${report.totalSellOut}'),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Lỗi: $e'),
        ),
      ],
    );
  }

  Widget _buildSellInTab() {
    final sellInAsync = ref.watch(recentSellInProvider);

    return sellInAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState('Chưa có giao dịch sell-in', Icons.input);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return _buildSellInCard(tx);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildSellInCard(SellInTransaction tx) {
    final statusColor = _getSellInStatusColor(tx.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showSellInDetail(tx.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.input, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.distributorName ?? 'NPP',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          tx.transactionNumber,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(tx.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(tx.transactionDate),
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(tx.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              if (tx.poNumber != null) ...[
                const SizedBox(height: 4),
                Text(
                  'PO: ${tx.poNumber}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellOutTab() {
    final sellOutAsync = ref.watch(recentSellOutProvider);

    return sellOutAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState('Chưa có giao dịch sell-out', Icons.output);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return _buildSellOutCard(tx);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildSellOutCard(SellOutTransaction tx) {
    final statusColor = _getSellOutStatusColor(tx.paymentStatus ?? 'pending');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showSellOutDetail(tx.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.output, color: Colors.green[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.outletName ?? 'Điểm bán',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'NPP: ${tx.distributorName ?? '-'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(
                    _getPaymentStatusText(tx.paymentStatus),
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(tx.transactionDate),
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(tx.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (tx.invoiceNumber != null) ...[
                const SizedBox(height: 4),
                Text(
                  'HD: ${tx.invoiceNumber}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getSellInStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getSellOutStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'paid':
        return 'Đã TT';
      case 'partial':
        return 'TT một phần';
      case 'pending':
        return 'Chờ TT';
      default:
        return 'Chờ TT';
    }
  }

  Future<void> _refreshData() async {
    ref.invalidate(salesSummaryProvider);
    ref.invalidate(recentSellInProvider);
    ref.invalidate(recentSellOutProvider);
    ref.invalidate(lowStockAlertsProvider);
    ref.invalidate(sellThroughReportsProvider);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc dữ liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: Add date range picker
            // TODO: Add distributor selector
            const Text('Tính năng đang phát triển'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.input, color: Colors.blue[700]),
              ),
              title: const Text('Ghi nhận Sell-in'),
              subtitle: const Text('Công ty → NPP'),
              onTap: () {
                Navigator.pop(context);
                _showRecordSellInDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.output, color: Colors.green[700]),
              ),
              title: const Text('Ghi nhận Sell-out'),
              subtitle: const Text('NPP → Điểm bán'),
              onTap: () {
                Navigator.pop(context);
                _showRecordSellOutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordSellInDialog() {
    // TODO: Implement sell-in recording form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form ghi nhận Sell-in đang phát triển')),
    );
  }

  void _showRecordSellOutDialog() {
    // TODO: Implement sell-out recording form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form ghi nhận Sell-out đang phát triển')),
    );
  }

  void _showSellInDetail(String transactionId) {
    // TODO: Navigate to sell-in detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chi tiết Sell-in: $transactionId')),
    );
  }

  void _showSellOutDetail(String transactionId) {
    // TODO: Navigate to sell-out detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chi tiết Sell-out: $transactionId')),
    );
  }
}
