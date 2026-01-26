import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/odori_receivable.dart';
import '../../providers/odori_providers.dart';
import 'receivable_payment_page.dart';

class OdoriReceivablesPage extends ConsumerStatefulWidget {
  const OdoriReceivablesPage({super.key});

  @override
  ConsumerState<OdoriReceivablesPage> createState() => _OdoriReceivablesPageState();
}

class _OdoriReceivablesPageState extends ConsumerState<OdoriReceivablesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _statusFilter = null;
              break;
            case 1:
              _statusFilter = 'overdue';
              break;
            case 2:
              _statusFilter = 'paid';
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receivablesAsync = ref.watch(receivablesProvider(ReceivableFilters(
      status: _statusFilter,
    )));
    final overdueAsync = ref.watch(overdueReceivablesProvider);
    final paymentsAsync = ref.watch(paymentsProvider(const PaymentFilters()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Công nợ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Tất cả'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Quá hạn'),
                  const SizedBox(width: 4),
                  overdueAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (items) => items.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${items.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Đã thanh toán'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary cards
          _buildSummaryCards(receivablesAsync),
          // Receivables list
          Expanded(
            child: receivablesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Lỗi: $error'),
                  ],
                ),
              ),
              data: (receivables) {
                if (receivables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Không có công nợ'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(receivablesProvider(const ReceivableFilters()).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: receivables.length,
                    itemBuilder: (context, index) {
                      final receivable = receivables[index];
                      return _ReceivableCard(receivable: receivable);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordPaymentSheet(),
        icon: const Icon(Icons.payments),
        label: const Text('Ghi thu'),
      ),
    );
  }

  Widget _buildSummaryCards(AsyncValue<List<OdoriReceivable>> receivablesAsync) {
    return receivablesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (receivables) {
        final totalReceivable = receivables
            .where((r) => r.status != 'paid')
            .fold<double>(0, (sum, r) => sum + r.remainingAmount);
        
        final overdueAmount = receivables
            .where((r) => r.isOverdue)
            .fold<double>(0, (sum, r) => sum + r.remainingAmount);
        
        final overdueCount = receivables.where((r) => r.isOverdue).length;

        final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Tổng công nợ',
                  value: currencyFormat.format(totalReceivable),
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Quá hạn',
                  value: currencyFormat.format(overdueAmount),
                  subtitle: '$overdueCount khách hàng',
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecordPaymentSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceivablePaymentPage()),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceivableCard extends StatelessWidget {
  final OdoriReceivable receivable;

  const _ReceivableCard({required this.receivable});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReceivableDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receivable.customerName ?? 'Khách hàng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          receivable.invoiceNumber,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: receivable.status, isOverdue: receivable.isOverdue),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Đến hạn: ${dateFormat.format(receivable.dueDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: receivable.isOverdue ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  if (receivable.isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Quá ${receivable.daysOverdue} ngày',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Còn lại',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      Text(
                        currencyFormat.format(receivable.remainingAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: receivable.isOverdue ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Đã thu',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      Text(
                        currencyFormat.format(receivable.paidAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (receivable.status != 'paid')
                    ElevatedButton(
                      onPressed: () => _recordPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Thu tiền'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceivableDetail(BuildContext context) {
    // TODO: Navigate to receivable detail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chi tiết công nợ ${receivable.invoiceNumber}')),
    );
  }

  void _recordPayment(BuildContext context) {
    // TODO: Implement payment recording
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ghi thu tiền',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              receivable.customerName ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                prefixText: 'đ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Phương thức',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản')),
                DropdownMenuItem(value: 'check', child: Text('Séc')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã ghi thu tiền thành công')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Xác nhận', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isOverdue;

  const _StatusBadge({required this.status, this.isOverdue = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (isOverdue && status != 'paid') {
      color = Colors.red;
      label = 'Quá hạn';
    } else {
      switch (status) {
        case 'open':
          color = Colors.blue;
          label = 'Đang mở';
          break;
        case 'partial':
          color = Colors.orange;
          label = 'Một phần';
          break;
        case 'paid':
          color = Colors.green;
          label = 'Đã thanh toán';
          break;
        case 'written_off':
          color = Colors.grey;
          label = 'Đã xóa';
          break;
        default:
          color = Colors.grey;
          label = status;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
