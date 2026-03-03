import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/odori_delivery.dart';
import '../../providers/odori_providers.dart';
import 'delivery_form_page.dart';

class OdoriDeliveriesPage extends ConsumerStatefulWidget {
  const OdoriDeliveriesPage({super.key});

  @override
  ConsumerState<OdoriDeliveriesPage> createState() => _OdoriDeliveriesPageState();
}

class _OdoriDeliveriesPageState extends ConsumerState<OdoriDeliveriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String? _statusFilter;

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
    final deliveriesAsync = ref.watch(deliveriesProvider(DeliveryFilters(
      status: _statusFilter,
      date: _selectedDate,
    )));
    final activeAsync = ref.watch(activeDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao hàng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Lịch sử'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Today tab
          _buildDeliveriesList(deliveriesAsync),
          // Active tab
          _buildActiveDeliveries(activeAsync),
          // History tab
          _buildDeliveriesList(deliveriesAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDeliverySheet(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo chuyến'),
      ),
    );
  }

  Widget _buildDeliveriesList(AsyncValue<List<OdoriDelivery>> deliveriesAsync) {
    return deliveriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(deliveriesProvider(const DeliveryFilters())),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (deliveries) {
        if (deliveries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Không có chuyến giao nào'),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(deliveriesProvider(DeliveryFilters(
            date: _selectedDate,
          )).future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return _DeliveryCard(delivery: delivery);
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveDeliveries(AsyncValue<List<OdoriDelivery>> activeAsync) {
    return activeAsync.when(
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
      data: (deliveries) {
        if (deliveries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gps_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Không có tài xế nào đang giao hàng'),
              ],
            ),
          );
        }
        return Column(
          children: [
            // Active drivers map placeholder
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Bản đồ theo dõi GPS', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            // Active drivers list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final delivery = deliveries[index];
                  return _ActiveDeliveryCard(delivery: delivery);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _showCreateDeliverySheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryFormPage()),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final OdoriDelivery delivery;

  const _DeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final dateFormat = DateFormat('HH:mm dd/MM');

    final progress = delivery.plannedStops > 0
        ? (delivery.completedStops + delivery.failedStops) / delivery.plannedStops
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDeliveryDetail(context),
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
                          delivery.deliveryNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (delivery.driverName != null)
                          Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                delivery.driverName!,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: delivery.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (delivery.vehicle != null) ...[
                    Icon(Icons.local_shipping, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      delivery.vehicle!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (delivery.vehiclePlate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        delivery.vehiclePlate!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${delivery.completedStops}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(' / ${delivery.plannedStops} điểm'),
                            if (delivery.failedStops > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${delivery.failedStops} lỗi',
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
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            delivery.failedStops > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(delivery.collectedAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Thu được',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              if (delivery.startedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Bắt đầu: ${dateFormat.format(delivery.startedAt!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (delivery.completedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '- Hoàn thành: ${dateFormat.format(delivery.completedAt!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryDetail(BuildContext context) {
    // TODO: Navigate to delivery detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chi tiết chuyến ${delivery.deliveryNumber}')),
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  final OdoriDelivery delivery;

  const _ActiveDeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.blue.withValues(alpha: 0.05),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                delivery.driverName?[0].toUpperCase() ?? 'D',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(delivery.driverName ?? 'Tài xế'),
        subtitle: Text(
          '${delivery.completedStops}/${delivery.plannedStops} điểm - ${delivery.deliveryNumber}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.navigation, color: Colors.blue),
          onPressed: () {
            // TODO: Show on map
          },
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'planned':
        color = Colors.grey;
        label = 'Đã lên kế hoạch';
        icon = Icons.schedule;
        break;
      case 'loading':
        color = Colors.orange;
        label = 'Đang lấy hàng';
        icon = Icons.inventory;
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'Đang giao';
        icon = Icons.local_shipping;
        break;
      case 'completed':
        color = Colors.green;
        label = 'Hoàn thành';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Đã hủy';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
