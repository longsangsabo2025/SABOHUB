import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/cached_providers.dart';

final supabase = Supabase.instance.client;

// Re-export DriverDelivery from cached_providers for backward compatibility
// The actual provider is now in cached_providers.dart as cachedDriverDeliveriesProvider

// Legacy provider (redirects to cached provider)
final driverDeliveriesProvider = FutureProvider.autoDispose<List<DriverDeliveryCache>>((ref) async {
  return ref.watch(cachedDriverDeliveriesProvider.future);
});

// Keep DriverDelivery class for backward compatibility with existing code
class DriverDelivery {
  final String id;
  final String deliveryNumber;
  final String status;
  final String? orderNumber;
  final double? totalAmount;
  final String? customerName;
  final String? customerAddress;
  final String? customerPhone;
  final double? latitude;
  final double? longitude;
  final DateTime deliveryDate;
  final DateTime? startedAt;

  DriverDelivery({
    required this.id,
    required this.deliveryNumber,
    required this.status,
    this.orderNumber,
    this.totalAmount,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
    this.latitude,
    this.longitude,
    required this.deliveryDate,
    this.startedAt,
  });

  factory DriverDelivery.fromJson(Map<String, dynamic> json) {
    final order = json['sales_orders'];
    final customer = order?['customers'];
    return DriverDelivery(
      id: json['id'],
      deliveryNumber: json['delivery_number'] ?? 'DL-???',
      status: json['status'],
      orderNumber: order?['order_number'],
      totalAmount: order?['total']?.toDouble() ?? json['total_amount']?.toDouble(),
      customerName: customer?['name'],
      customerAddress: customer?['address'],
      customerPhone: customer?['phone'],
      latitude: customer?['lat']?.toDouble(),  // DB uses 'lat' not 'latitude'
      longitude: customer?['lng']?.toDouble(),  // DB uses 'lng' not 'longitude'
      deliveryDate: DateTime.parse(json['delivery_date']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
    );
  }
  
  // Convert from cache model
  factory DriverDelivery.fromCache(DriverDeliveryCache cache) {
    return DriverDelivery(
      id: cache.id,
      deliveryNumber: cache.deliveryNumber,
      status: cache.status,
      orderNumber: cache.orderNumber,
      totalAmount: cache.totalAmount,
      customerName: cache.customerName,
      customerAddress: cache.customerAddress,
      customerPhone: cache.customerPhone,
      latitude: cache.latitude,
      longitude: cache.longitude,
      deliveryDate: cache.deliveryDate,
      startedAt: cache.startedAt,
    );
  }
}

class DriverDashboardPage extends ConsumerStatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  ConsumerState<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends ConsumerState<DriverDashboardPage> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  
  @override
  Widget build(BuildContext context) {
    // 🔥 PHASE 4: Use CACHED provider with realtime listener
    ref.watch(driverDeliveryListenerProvider); // Enable realtime updates
    final deliveriesAsync = ref.watch(cachedDriverDeliveriesProvider);
    // Stats are available but not displayed in current UI
    ref.watch(cachedDriverDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình hôm nay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshAllDriverData(ref),
          ),
        ],
      ),
      body: deliveriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              ElevatedButton(
                onPressed: () => refreshAllDriverData(ref),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (deliveriesCache) {
          // Convert cache to legacy DriverDelivery for UI compatibility
          final deliveries = deliveriesCache.map((c) => DriverDelivery.fromCache(c)).toList();
          
          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có đơn giao hôm nay',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nghỉ ngơi thôi! 🎉',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final inProgress = deliveries.where((d) => d.status == 'in_progress').toList();
          final pending = deliveries.where((d) => d.status == 'planned' || d.status == 'loading').toList();

          return RefreshIndicator(
            onRefresh: () async {
              refreshAllDriverData(ref);
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                _buildSummaryCard(deliveries),
                const SizedBox(height: 16),
                
                // In progress section
                if (inProgress.isNotEmpty) ...[
                  _buildSectionHeader('Đang giao', inProgress.length, Colors.green),
                  const SizedBox(height: 8),
                  ...inProgress.map((d) => _DeliveryCard(
                    delivery: d,
                    onAction: () => _completeDelivery(d),
                    actionLabel: 'Hoàn tất',
                    actionColor: Colors.green,
                  )),
                  const SizedBox(height: 16),
                ],
                
                // Pending section
                if (pending.isNotEmpty) ...[
                  _buildSectionHeader('Chờ giao', pending.length, Colors.orange),
                  const SizedBox(height: 8),
                  ...pending.map((d) => _DeliveryCard(
                    delivery: d,
                    onAction: () => _startDelivery(d),
                    actionLabel: 'Bắt đầu',
                    actionColor: Colors.blue,
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<DriverDelivery> deliveries) {
    final totalValue = deliveries.fold<double>(
      0, 
      (sum, d) => sum + (d.totalAmount ?? 0),
    );
    final completed = deliveries.where((d) => d.status == 'completed').length;
    final inProgress = deliveries.where((d) => d.status == 'in_progress').length;
    final pending = deliveries.where((d) => d.status == 'planned' || d.status == 'loading').length;

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
                  icon: Icons.pending_actions,
                  label: 'Chờ giao',
                  value: '$pending',
                  color: Colors.orange,
                ),
                _StatItem(
                  icon: Icons.local_shipping,
                  label: 'Đang giao',
                  value: '$inProgress',
                  color: Colors.blue,
                ),
                _StatItem(
                  icon: Icons.check_circle,
                  label: 'Hoàn tất',
                  value: '$completed',
                  color: Colors.green,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Tổng giá trị: ${currencyFormat.format(totalValue)}',
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

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startDelivery(DriverDelivery delivery) async {
    try {
      await supabase.from('deliveries').update({
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', delivery.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bắt đầu giao cho ${delivery.customerName}'),
            backgroundColor: Colors.blue,
          ),
        );
        refreshDriverDeliveries(ref); // Use cached refresh
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

  Future<void> _completeDelivery(DriverDelivery delivery) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn tất'),
        content: Text('Xác nhận đã giao hàng cho ${delivery.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase.from('deliveries').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', delivery.id);

      // Also update order status
      final orderResponse = await supabase
          .from('deliveries')
          .select('order_id')
          .eq('id', delivery.id)
          .single();
      
      if (orderResponse['order_id'] != null) {
        await supabase.from('sales_orders').update({
          'delivery_status': 'delivered',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderResponse['order_id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hoàn tất giao cho ${delivery.customerName}'),
            backgroundColor: Colors.green,
          ),
        );
        refreshDriverDeliveries(ref); // Use cached refresh
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DriverDelivery delivery;
  final VoidCallback onAction;
  final String actionLabel;
  final Color actionColor;

  const _DeliveryCard({
    required this.delivery,
    required this.onAction,
    required this.actionLabel,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        delivery.orderNumber ?? delivery.deliveryNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        delivery.customerName ?? 'Khách hàng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (delivery.totalAmount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currencyFormat.format(delivery.totalAmount),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (delivery.customerAddress != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      delivery.customerAddress!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            if (delivery.customerPhone != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('tel:${delivery.customerPhone}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.blue[500]),
                    const SizedBox(width: 4),
                    Text(
                      delivery.customerPhone!,
                      style: TextStyle(
                        color: Colors.blue[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (delivery.latitude != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Use coordinates if available, otherwise use address
                        final destination = 'https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=${delivery.latitude},${delivery.longitude}&travelmode=driving';
                        final uri = Uri.parse(destination);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Chỉ đường'),
                    ),
                  ),
                if (delivery.latitude != null) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAction,
                    icon: Icon(
                      delivery.status == 'in_progress' 
                          ? Icons.check_circle 
                          : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(actionLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
