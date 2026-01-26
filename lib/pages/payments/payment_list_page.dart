import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/payment.dart';
import '../../providers/payment_provider.dart';
import 'payment_form_page.dart';

class PaymentListPage extends ConsumerStatefulWidget {
  const PaymentListPage({super.key});

  @override
  ConsumerState<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends ConsumerState<PaymentListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Auto refresh every 30 seconds for real-time updates
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        ref.invalidate(allPaymentsProvider);
        ref.invalidate(paymentStatsProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentStats = ref.watch(paymentStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Stats cards
              paymentStats.when(
                data: (stats) => _buildStatsCards(stats),
                loading: () => const SizedBox(height: 60),
                error: (error, stack) => const SizedBox(height: 60),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Hoàn thành'),
                  Tab(text: 'Đang chờ'),
                  Tab(text: 'Thất bại'),
                  Tab(text: 'Đã hoàn'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllPaymentsTab(),
          _buildPaymentsByStatusTab(PaymentStatus.completed),
          _buildPaymentsByStatusTab(PaymentStatus.pending),
          _buildPaymentsByStatusTab(PaymentStatus.failed),
          _buildPaymentsByStatusTab(PaymentStatus.refunded),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentFormPage()),
          );
        },
        label: const Text('Thanh toán'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // First row - Revenue and counts
          Row(
            children: [
              _buildStatCard(
                'Doanh thu hôm nay',
                '${(stats['todayRevenue'] as double).toInt()}K',
                Colors.green,
                Icons.monetization_on,
              ),
              const SizedBox(width: 4),
              _buildStatCard(
                'Hoàn thành',
                '${stats['completedToday']}',
                Colors.blue,
                Icons.check_circle,
              ),
              const SizedBox(width: 4),
              _buildStatCard(
                'Đang chờ',
                '${stats['pendingPayments']}',
                Colors.orange,
                Icons.pending,
              ),
              const SizedBox(width: 4),
              _buildStatCard(
                'Thất bại',
                '${stats['failedPayments']}',
                Colors.red,
                Icons.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPaymentsTab() {
    final allPayments = ref.watch(allPaymentsProvider);
    
    return allPayments.when(
      data: (payments) => _buildPaymentsList(payments),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildPaymentsByStatusTab(PaymentStatus status) {
    final payments = ref.watch(paymentsByStatusProvider(status));
    
    return payments.when(
      data: (payments) => _buildPaymentsList(payments),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    if (payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) => _buildPaymentCard(payments[index]),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.referenceNumber ?? 'GD-${payment.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (payment.customerName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            payment.customerName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: payment.status.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.status.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Amount and method info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số tiền',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${payment.amount.toInt()}K',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: payment.method.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payment.method.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(payment.paidAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Action buttons for pending/failed payments
              if (payment.status == PaymentStatus.pending || payment.status == PaymentStatus.failed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (payment.status == PaymentStatus.pending) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completePayment(payment.id),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Xác nhận'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _failPayment(payment.id),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Thất bại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    if (payment.status == PaymentStatus.failed) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completePayment(payment.id),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Refund button for completed payments
              if (payment.status == PaymentStatus.completed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _refundPayment(payment.id),
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Hoàn tiền'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Lỗi: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    ref.invalidate(allPaymentsProvider);
    ref.invalidate(paymentStatsProvider);
    for (final status in PaymentStatus.values) {
      ref.invalidate(paymentsByStatusProvider(status));
    }
  }

  void _showPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentDetailsSheet(payment),
    );
  }

  Widget _buildPaymentDetailsSheet(Payment payment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Row(
            children: [
              Text(
                'Chi tiết thanh toán',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: payment.status.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment.status.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Payment details
          _buildDetailRow('Mã giao dịch', payment.referenceNumber ?? 'GD-${payment.id.substring(0, 8)}'),
          if (payment.customerName != null)
            _buildDetailRow('Khách hàng', payment.customerName!),
          _buildDetailRow('Số tiền', '${payment.amount.toInt()}K'),
          _buildDetailRow('Phương thức', payment.method.label),
          _buildDetailRow('Thời gian', _formatDateTimeFull(payment.paidAt)),
          
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Ghi chú', payment.notes!),
          ],
          
          const SizedBox(height: 24),
          
          // Action buttons based on status
          if (payment.status == PaymentStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _completePayment(payment.id);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _failPayment(payment.id);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Thất bại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (payment.status == PaymentStatus.completed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _refundPayment(payment.id);
                },
                icon: const Icon(Icons.undo),
                label: const Text('Hoàn tiền'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],

          if (payment.status == PaymentStatus.failed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _completePayment(payment.id);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại thanh toán'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
          
          // Safe area bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTimeFull(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _completePayment(String paymentId) async {
    try {
      final paymentActions = ref.read(paymentActionsProvider);
      await paymentActions.completePayment(paymentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận thanh toán thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _failPayment(String paymentId) async {
    try {
      final paymentActions = ref.read(paymentActionsProvider);
      await paymentActions.failPayment(paymentId, reason: 'Thanh toán thất bại');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đánh dấu thanh toán thất bại'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refundPayment(String paymentId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn tiền'),
        content: const Text('Bạn có chắc chắn muốn hoàn tiền cho giao dịch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Hoàn tiền', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final paymentActions = ref.read(paymentActionsProvider);
        await paymentActions.refundPayment(paymentId, reason: 'Hoàn tiền theo yêu cầu');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hoàn tiền thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}