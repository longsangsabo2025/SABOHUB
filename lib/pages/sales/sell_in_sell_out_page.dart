import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/sell_in_sell_out_service.dart';
import '../../providers/auth_provider.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _RecordSellInSheet(
          onSaved: () {
            ref.invalidate(recentSellInProvider);
            ref.invalidate(salesSummaryProvider);
          },
        ),
      ),
    );
  }

  void _showRecordSellOutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _RecordSellOutSheet(
          onSaved: () {
            ref.invalidate(recentSellOutProvider);
            ref.invalidate(salesSummaryProvider);
          },
        ),
      ),
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

/// Form ghi nhận Sell-in (Công ty → NPP)
class _RecordSellInSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _RecordSellInSheet({required this.onSaved});
  
  @override
  ConsumerState<_RecordSellInSheet> createState() => _RecordSellInSheetState();
}

class _RecordSellInSheetState extends ConsumerState<_RecordSellInSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _distributors = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _products = [];
  
  String? _selectedDistributorId;
  String? _selectedWarehouseId;
  final List<Map<String, dynamic>> _items = [];
  final _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) return;
    
    final supabase = Supabase.instance.client;
    
    // Load distributors (NPP) - customers with type = 'distributor' OR name contains 'NPP'
    final distResponse = await supabase
        .from('customers')
        .select('id, name, code')
        .eq('company_id', companyId)
        .or('type.eq.distributor,name.ilike.%npp%')
        .order('name');
    
    // Load warehouses
    final whResponse = await supabase
        .from('warehouses')
        .select('id, name')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('name');
    
    // Load products
    final prodResponse = await supabase
        .from('products')
        .select('id, name, sku, unit, selling_price')
        .eq('company_id', companyId)
        .eq('status', 'active')
        .order('name');
    
    setState(() {
      _distributors = List<Map<String, dynamic>>.from(distResponse);
      _warehouses = List<Map<String, dynamic>>.from(whResponse);
      _products = List<Map<String, dynamic>>.from(prodResponse);
    });
  }
  
  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProductSelectorSheet(
        products: _products,
        onSelected: (product, qty) {
          setState(() {
            final existingIndex = _items.indexWhere((i) => i['product_id'] == product['id']);
            if (existingIndex >= 0) {
              _items[existingIndex]['quantity'] += qty;
              _items[existingIndex]['total_amount'] = 
                  _items[existingIndex]['quantity'] * _items[existingIndex]['unit_price'];
            } else {
              _items.add({
                'product_id': product['id'],
                'product_name': product['name'],
                'sku': product['sku'],
                'unit': product['unit'] ?? 'pcs',
                'quantity': qty,
                'unit_price': (product['selling_price'] ?? 0).toDouble(),
                'total_amount': qty * (product['selling_price'] ?? 0).toDouble(),
              });
            }
          });
        },
      ),
    );
  }
  
  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }
  
  Future<void> _saveSellIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistributorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn NPP'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm sản phẩm'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;
      
      final supabase = Supabase.instance.client;
      
      // Generate transaction code
      final now = DateTime.now();
      final txCode = 'SI${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(9)}';
      
      final totalQty = _items.fold<int>(0, (sum, i) => sum + (i['quantity'] as int));
      final totalAmount = _items.fold<double>(0, (sum, i) => sum + (i['total_amount'] as double));
      
      // Insert transaction
      final txResponse = await supabase
          .from('sell_in_transactions')
          .insert({
            'company_id': companyId,
            'transaction_code': txCode,
            'transaction_date': now.toIso8601String().split('T')[0],
            'from_warehouse_id': _selectedWarehouseId,
            'distributor_id': _selectedDistributorId,
            'total_quantity': totalQty,
            'total_amount': totalAmount,
            'status': 'pending',
            'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            'created_by': userId,
          })
          .select('id')
          .single();
      
      final txId = txResponse['id'];
      
      // Insert items
      for (final item in _items) {
        await supabase.from('sell_in_items').insert({
          'sell_in_id': txId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'unit': item['unit'],
          'unit_price': item['unit_price'],
          'total_amount': item['total_amount'],
        });
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ghi nhận Sell-in: $txCode'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final totalAmount = _items.fold<double>(0, (sum, i) => sum + (i['total_amount'] as double));
    
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.input, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ghi nhận Sell-in', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Công ty → NPP', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Dropdowns
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NPP Selector
                    DropdownButtonFormField<String>(
                      value: _selectedDistributorId,
                      decoration: InputDecoration(
                        labelText: 'Nhà phân phối (NPP) *',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      items: _distributors.isEmpty 
                          ? [const DropdownMenuItem(value: null, child: Text('Chưa có NPP - Thêm khách hàng type=distributor'))]
                          : _distributors.map((d) => DropdownMenuItem(
                              value: d['id'] as String,
                              child: Text(d['name'] ?? 'N/A'),
                            )).toList(),
                      onChanged: (v) => setState(() => _selectedDistributorId = v),
                      validator: (v) => v == null ? 'Chọn NPP' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    // Warehouse Selector
                    DropdownButtonFormField<String>(
                      value: _selectedWarehouseId,
                      decoration: InputDecoration(
                        labelText: 'Kho xuất',
                        prefixIcon: const Icon(Icons.warehouse),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      items: _warehouses.map((w) => DropdownMenuItem(
                        value: w['id'] as String,
                        child: Text(w['name'] ?? 'N/A'),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedWarehouseId = v),
                    ),
                    const SizedBox(height: 12),
                    
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Items Header
                    Row(
                      children: [
                        const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm SP'),
                        ),
                      ],
                    ),
                    
                    // Items List
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Chưa có sản phẩm')),
                      )
                    else
                      ...List.generate(_items.length, (index) {
                        final item = _items[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text('${item['quantity']}'),
                            ),
                            title: Text(item['product_name'] ?? 'SP', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['sku']} • ${_currencyFormat.format(item['unit_price'])}/${item['unit']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_currencyFormat.format(item['total_amount']), style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            
            // Total & Save
            const Divider(),
            Row(
              children: [
                const Text('Tổng:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(_currencyFormat.format(totalAmount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSellIn,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                label: Text(_isLoading ? 'Đang lưu...' : 'Ghi nhận Sell-in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Form ghi nhận Sell-out (NPP → Điểm bán)
class _RecordSellOutSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _RecordSellOutSheet({required this.onSaved});
  
  @override
  ConsumerState<_RecordSellOutSheet> createState() => _RecordSellOutSheetState();
}

class _RecordSellOutSheetState extends ConsumerState<_RecordSellOutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _distributors = [];
  List<Map<String, dynamic>> _outlets = [];
  List<Map<String, dynamic>> _products = [];
  
  String? _selectedDistributorId;
  String? _selectedOutletId;
  final List<Map<String, dynamic>> _items = [];
  final _outletNameController = TextEditingController();
  final _outletAddressController = TextEditingController();
  final _notesController = TextEditingController();
  String _outletChannel = 'GT Lẻ';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _outletNameController.dispose();
    _outletAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) return;
    
    final supabase = Supabase.instance.client;
    
    // Load distributors (NPP)
    final distResponse = await supabase
        .from('customers')
        .select('id, name, code')
        .eq('company_id', companyId)
        .or('type.eq.distributor,name.ilike.%npp%')
        .order('name');
    
    // Load outlets (retail customers)
    final outletResponse = await supabase
        .from('customers')
        .select('id, name, code, address, channel')
        .eq('company_id', companyId)
        .or('type.eq.retail,type.is.null,type.eq.other')
        .order('name')
        .limit(100);
    
    // Load products
    final prodResponse = await supabase
        .from('products')
        .select('id, name, sku, unit, selling_price')
        .eq('company_id', companyId)
        .eq('status', 'active')
        .order('name');
    
    setState(() {
      _distributors = List<Map<String, dynamic>>.from(distResponse);
      _outlets = List<Map<String, dynamic>>.from(outletResponse);
      _products = List<Map<String, dynamic>>.from(prodResponse);
    });
  }
  
  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProductSelectorSheet(
        products: _products,
        onSelected: (product, qty) {
          setState(() {
            final existingIndex = _items.indexWhere((i) => i['product_id'] == product['id']);
            if (existingIndex >= 0) {
              _items[existingIndex]['quantity'] += qty;
              _items[existingIndex]['total_amount'] = 
                  _items[existingIndex]['quantity'] * _items[existingIndex]['unit_price'];
            } else {
              _items.add({
                'product_id': product['id'],
                'product_name': product['name'],
                'sku': product['sku'],
                'unit': product['unit'] ?? 'pcs',
                'quantity': qty,
                'unit_price': (product['selling_price'] ?? 0).toDouble(),
                'total_amount': qty * (product['selling_price'] ?? 0).toDouble(),
              });
            }
          });
        },
      ),
    );
  }
  
  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }
  
  Future<void> _saveSellOut() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm sản phẩm'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Validate outlet info
    if (_selectedOutletId == null && _outletNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hoặc nhập thông tin điểm bán'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;
      
      final supabase = Supabase.instance.client;
      
      // Generate transaction code
      final now = DateTime.now();
      final txCode = 'SO${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(9)}';
      
      final totalQty = _items.fold<int>(0, (sum, i) => sum + (i['quantity'] as int));
      final totalAmount = _items.fold<double>(0, (sum, i) => sum + (i['total_amount'] as double));
      
      // Insert transaction
      final txResponse = await supabase
          .from('sell_out_transactions')
          .insert({
            'company_id': companyId,
            'transaction_code': txCode,
            'transaction_date': now.toIso8601String().split('T')[0],
            'distributor_id': _selectedDistributorId,
            'outlet_id': _selectedOutletId,
            'outlet_name': _selectedOutletId != null 
                ? _outlets.firstWhere((o) => o['id'] == _selectedOutletId)['name']
                : _outletNameController.text.trim(),
            'outlet_address': _selectedOutletId != null
                ? _outlets.firstWhere((o) => o['id'] == _selectedOutletId)['address']
                : _outletAddressController.text.trim(),
            'outlet_channel': _outletChannel,
            'total_quantity': totalQty,
            'total_amount': totalAmount,
            'status': 'recorded',
            'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            'created_by': userId,
            'reported_by_id': userId,
          })
          .select('id')
          .single();
      
      final txId = txResponse['id'];
      
      // Insert items
      for (final item in _items) {
        await supabase.from('sell_out_items').insert({
          'sell_out_id': txId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'unit': item['unit'],
          'unit_price': item['unit_price'],
          'total_amount': item['total_amount'],
        });
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ghi nhận Sell-out: $txCode'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final totalAmount = _items.fold<double>(0, (sum, i) => sum + (i['total_amount'] as double));
    
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.output, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ghi nhận Sell-out', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('NPP/Sales → Điểm bán', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NPP Selector (optional for sell-out)
                    DropdownButtonFormField<String>(
                      value: _selectedDistributorId,
                      decoration: InputDecoration(
                        labelText: 'Nhà phân phối (NPP) - tùy chọn',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('-- Không qua NPP --')),
                        ..._distributors.map((d) => DropdownMenuItem(
                          value: d['id'] as String,
                          child: Text(d['name'] ?? 'N/A'),
                        )),
                      ],
                      onChanged: (v) => setState(() => _selectedDistributorId = v),
                    ),
                    const SizedBox(height: 12),
                    
                    // Outlet Section
                    const Text('Điểm bán *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // Outlet Selector
                    DropdownButtonFormField<String>(
                      value: _selectedOutletId,
                      decoration: InputDecoration(
                        labelText: 'Chọn điểm bán có sẵn',
                        prefixIcon: const Icon(Icons.store),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('-- Nhập mới --')),
                        ..._outlets.map((o) => DropdownMenuItem(
                          value: o['id'] as String,
                          child: Text('${o['name']} ${o['channel'] != null ? "(${o['channel']})" : ""}'),
                        )),
                      ],
                      onChanged: (v) => setState(() => _selectedOutletId = v),
                    ),
                    
                    if (_selectedOutletId == null) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _outletNameController,
                        decoration: InputDecoration(
                          labelText: 'Tên điểm bán *',
                          prefixIcon: const Icon(Icons.store),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        validator: (v) => _selectedOutletId == null && (v?.trim().isEmpty ?? true) ? 'Nhập tên điểm bán' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _outletAddressController,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ điểm bán',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _outletChannel,
                        decoration: InputDecoration(
                          labelText: 'Kênh',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Horeca', child: Text('Horeca')),
                          DropdownMenuItem(value: 'GT Sỉ', child: Text('GT Sỉ')),
                          DropdownMenuItem(value: 'GT Lẻ', child: Text('GT Lẻ')),
                        ],
                        onChanged: (v) => setState(() => _outletChannel = v!),
                      ),
                    ],
                    const SizedBox(height: 12),
                    
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Items Header
                    Row(
                      children: [
                        const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm SP'),
                        ),
                      ],
                    ),
                    
                    // Items List
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Chưa có sản phẩm')),
                      )
                    else
                      ...List.generate(_items.length, (index) {
                        final item = _items[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade50,
                              child: Text('${item['quantity']}'),
                            ),
                            title: Text(item['product_name'] ?? 'SP', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['sku']} • ${_currencyFormat.format(item['unit_price'])}/${item['unit']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_currencyFormat.format(item['total_amount']), style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            
            // Total & Save
            const Divider(),
            Row(
              children: [
                const Text('Tổng:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(_currencyFormat.format(totalAmount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSellOut,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                label: Text(_isLoading ? 'Đang lưu...' : 'Ghi nhận Sell-out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product Selector Sheet
class _ProductSelectorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic> product, int quantity) onSelected;
  
  const _ProductSelectorSheet({required this.products, required this.onSelected});
  
  @override
  State<_ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<_ProductSelectorSheet> {
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  String _searchQuery = '';
  Map<String, dynamic>? _selectedProduct;
  
  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    super.dispose();
  }
  
  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.products;
    final query = _searchQuery.toLowerCase();
    return widget.products.where((p) =>
      (p['name']?.toLowerCase().contains(query) ?? false) ||
      (p['sku']?.toLowerCase().contains(query) ?? false)
    ).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Chọn sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                final isSelected = _selectedProduct?['id'] == product['id'];
                
                return Card(
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(product['name']?[0] ?? 'P'),
                    ),
                    title: Text(product['name'] ?? 'N/A'),
                    subtitle: Text('${product['sku']} • ${_currencyFormat.format(product['selling_price'] ?? 0)}/${product['unit'] ?? 'pcs'}'),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                    onTap: () => setState(() => _selectedProduct = product),
                  ),
                );
              },
            ),
          ),
          
          if (_selectedProduct != null) ...[
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    decoration: InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final qty = int.tryParse(_qtyController.text) ?? 1;
                    widget.onSelected(_selectedProduct!, qty);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}