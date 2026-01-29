import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

final supabase = Supabase.instance.client;

// Provider for driver's delivery history
final driverDeliveryHistoryProvider = FutureProvider.autoDispose<List<DeliveryHistoryItem>>((ref) async {
  final authState = ref.watch(authProvider);
  final employeeId = authState.user?.id;
  if (employeeId == null) return [];

  final response = await supabase
      .from('deliveries')
      .select('''
        *,
        sales_orders(
          order_number,
          total_amount,
          customers(name)
        )
      ''')
      .eq('driver_id', employeeId)
      .inFilter('status', ['delivered', 'failed', 'cancelled'])
      .order('completed_at', ascending: false)
      .limit(50);

  return (response as List).map((json) => DeliveryHistoryItem.fromJson(json)).toList();
});

class DeliveryHistoryItem {
  final String id;
  final String deliveryNumber;
  final String status;
  final String? orderNumber;
  final double? totalAmount;
  final String? customerName;
  final DateTime? completedAt;
  final DateTime deliveryDate;

  DeliveryHistoryItem({
    required this.id,
    required this.deliveryNumber,
    required this.status,
    this.orderNumber,
    this.totalAmount,
    this.customerName,
    this.completedAt,
    required this.deliveryDate,
  });

  factory DeliveryHistoryItem.fromJson(Map<String, dynamic> json) {
    final order = json['sales_orders'];
    final customer = order?['customers'];
    return DeliveryHistoryItem(
      id: json['id'],
      deliveryNumber: json['delivery_number'] ?? 'DL-???',
      status: json['status'],
      orderNumber: order?['order_number'],
      totalAmount: order?['total_amount']?.toDouble(),
      customerName: customer?['name'],
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      deliveryDate: DateTime.parse(json['delivery_date']),
    );
  }

  Color get statusColor {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'delivered':
        return 'Thành công';
      case 'failed':
        return 'Thất bại';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'failed':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.info;
    }
  }
}

/// Driver Delivery History Page
/// Read-only page showing past deliveries for the driver
class DriverDeliveryHistoryPage extends ConsumerStatefulWidget {
  const DriverDeliveryHistoryPage({super.key});

  @override
  ConsumerState<DriverDeliveryHistoryPage> createState() => _DriverDeliveryHistoryPageState();
}

class _DriverDeliveryHistoryPageState extends ConsumerState<DriverDeliveryHistoryPage> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(driverDeliveryHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao hàng'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _statusFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Tất cả')),
              const PopupMenuItem(value: 'delivered', child: Text('Thành công')),
              const PopupMenuItem(value: 'failed', child: Text('Thất bại')),
              const PopupMenuItem(value: 'cancelled', child: Text('Đã hủy')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(driverDeliveryHistoryProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(driverDeliveryHistoryProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (history) {
          // Apply filter
          final filteredHistory = _statusFilter == null
              ? history
              : history.where((h) => h.status == _statusFilter).toList();

          if (filteredHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _statusFilter == null 
                        ? 'Chưa có lịch sử giao hàng'
                        : 'Không có đơn ${_getFilterLabel()}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final grouped = <String, List<DeliveryHistoryItem>>{};
          for (final item in filteredHistory) {
            final dateKey = DateFormat('dd/MM/yyyy').format(item.deliveryDate);
            grouped.putIfAbsent(dateKey, () => []).add(item);
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(driverDeliveryHistoryProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary stats
                _buildSummaryCard(history),
                const SizedBox(height: 16),
                
                // History list grouped by date
                ...grouped.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(entry.key),
                    const SizedBox(height: 8),
                    ...entry.value.map((item) => _HistoryCard(
                      item: item,
                      currencyFormat: currencyFormat,
                      dateFormat: dateFormat,
                    )),
                    const SizedBox(height: 8),
                  ],
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getFilterLabel() {
    switch (_statusFilter) {
      case 'delivered':
        return 'thành công';
      case 'failed':
        return 'thất bại';
      case 'cancelled':
        return 'đã hủy';
      default:
        return '';
    }
  }

  Widget _buildSummaryCard(List<DeliveryHistoryItem> history) {
    final delivered = history.where((h) => h.status == 'delivered').length;
    final failed = history.where((h) => h.status == 'failed').length;
    final totalValue = history
        .where((h) => h.status == 'delivered')
        .fold<double>(0, (sum, h) => sum + (h.totalAmount ?? 0));

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.check_circle,
                  label: 'Thành công',
                  value: '$delivered',
                  color: Colors.green,
                ),
                _StatItem(
                  icon: Icons.cancel,
                  label: 'Thất bại',
                  value: '$failed',
                  color: Colors.red,
                ),
                _StatItem(
                  icon: Icons.percent,
                  label: 'Tỷ lệ',
                  value: history.isNotEmpty 
                      ? '${((delivered / history.length) * 100).toStringAsFixed(0)}%'
                      : '0%',
                  color: Colors.blue,
                ),
              ],
            ),
            if (totalValue > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng giá trị đã giao: ${currencyFormat.format(totalValue)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DeliveryHistoryItem item;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  const _HistoryCard({
    required this.item,
    required this.currencyFormat,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.statusIcon, color: item.statusColor, size: 24),
            ),
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.orderNumber ?? item.deliveryNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.statusLabel,
                          style: TextStyle(
                            color: item.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.customerName ?? 'Khách hàng',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (item.completedAt != null) ...[
                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(item.completedAt!),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                      const Spacer(),
                      if (item.totalAmount != null)
                        Text(
                          currencyFormat.format(item.totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: item.status == 'delivered' ? Colors.green : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
