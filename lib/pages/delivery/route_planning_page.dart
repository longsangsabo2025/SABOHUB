import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

final supabase = Supabase.instance.client;

// Helper extension for AsyncValue
extension AsyncValueX<T> on AsyncValue<T> {
  T? get valueOrNull => whenOrNull(data: (value) => value);
}

// Provider for deliveries ready for route planning
final routeDeliveriesProvider = FutureProvider.autoDispose<List<RouteDelivery>>((ref) async {
  final authState = ref.watch(authProvider);
  final companyId = authState.user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('deliveries')
      .select('''
        *,
        employees!deliveries_driver_id_fkey(full_name),
        sales_orders(order_number, customers(name, address, phone, latitude, longitude))
      ''')
      .eq('company_id', companyId)
      .inFilter('status', ['assigned', 'ready', 'in_progress'])
      .order('delivery_date', ascending: true);

  return (response as List).map((json) => RouteDelivery.fromJson(json)).toList();
});

// Provider for drivers
final routeDriversProvider = FutureProvider.autoDispose<List<RouteDriver>>((ref) async {
  final authState = ref.watch(authProvider);
  final companyId = authState.user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('employees')
      .select('id, full_name, phone')
      .eq('company_id', companyId)
      .eq('role', 'driver')
      .eq('is_active', true);

  return (response as List).map((json) => RouteDriver.fromJson(json)).toList();
});

class RouteDelivery {
  final String id;
  final String deliveryNumber;
  final String status;
  final String? driverId;
  final String? driverName;
  final String? orderNumber;
  final String? customerName;
  final String? customerAddress;
  final String? customerPhone;
  final double? latitude;
  final double? longitude;
  final DateTime deliveryDate;
  bool isSelected;

  RouteDelivery({
    required this.id,
    required this.deliveryNumber,
    required this.status,
    this.driverId,
    this.driverName,
    this.orderNumber,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
    this.latitude,
    this.longitude,
    required this.deliveryDate,
    this.isSelected = false,
  });

  factory RouteDelivery.fromJson(Map<String, dynamic> json) {
    final order = json['sales_orders'];
    final customer = order?['customers'];
    return RouteDelivery(
      id: json['id'],
      deliveryNumber: json['delivery_number'] ?? 'DL-???',
      status: json['status'],
      driverId: json['driver_id'],
      driverName: json['employees']?['full_name'],
      orderNumber: order?['order_number'],
      customerName: customer?['name'],
      customerAddress: json['delivery_address'] as String? ?? customer?['address'],
      customerPhone: customer?['phone'],
      latitude: customer?['lat']?.toDouble(),  // DB uses 'lat' not 'latitude'
      longitude: customer?['lng']?.toDouble(),  // DB uses 'lng' not 'longitude'
      deliveryDate: DateTime.parse(json['delivery_date']),
    );
  }
}

class RouteDriver {
  final String id;
  final String fullName;
  final String? phone;

  RouteDriver({
    required this.id,
    required this.fullName,
    this.phone,
  });

  factory RouteDriver.fromJson(Map<String, dynamic> json) {
    return RouteDriver(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
    );
  }
}

class RoutePlanningPage extends ConsumerStatefulWidget {
  const RoutePlanningPage({super.key});

  @override
  ConsumerState<RoutePlanningPage> createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends ConsumerState<RoutePlanningPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _selectedDeliveryIds = [];

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
    final deliveriesAsync = ref.watch(routeDeliveriesProvider);
    final driversAsync = ref.watch(routeDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình giao hàng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chờ phân'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Theo tài xế'),
          ],
        ),
        actions: [
          if (_selectedDeliveryIds.isNotEmpty)
            Badge(
              label: Text('${_selectedDeliveryIds.length}'),
              child: IconButton(
                icon: const Icon(Icons.local_shipping),
                onPressed: () => _showAssignDriverDialog(driversAsync.valueOrNull ?? []),
                tooltip: 'Phân tài xế',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(routeDeliveriesProvider),
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
                onPressed: () => ref.refresh(routeDeliveriesProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (deliveries) {
          final pendingDeliveries = deliveries.where((d) => d.driverId == null).toList();
          final activeDeliveries = deliveries.where((d) => d.status == 'in_progress').toList();
          final drivers = driversAsync.valueOrNull ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              // Pending tab - deliveries without driver
              _buildPendingDeliveriesList(pendingDeliveries),
              // Active tab - in_progress deliveries
              _buildActiveDeliveriesList(activeDeliveries),
              // By driver tab
              _buildByDriverList(deliveries, drivers),
            ],
          );
        },
      ),
      floatingActionButton: _selectedDeliveryIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAssignDriverDialog(driversAsync.valueOrNull ?? []),
              icon: const Icon(Icons.person_add),
              label: Text('Phân ${_selectedDeliveryIds.length} đơn'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildPendingDeliveriesList(List<RouteDelivery> deliveries) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              'Tất cả đơn đã được phân tài xế',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(routeDeliveriesProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          final isSelected = _selectedDeliveryIds.contains(delivery.id);
          
          return _DeliveryCard(
            delivery: delivery,
            isSelectable: true,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDeliveryIds.remove(delivery.id);
                } else {
                  _selectedDeliveryIds.add(delivery.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveDeliveriesList(List<RouteDelivery> deliveries) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có đơn đang giao',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(routeDeliveriesProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return _DeliveryCard(
            delivery: delivery,
            isSelectable: false,
            showDriver: true,
          );
        },
      ),
    );
  }

  Widget _buildByDriverList(List<RouteDelivery> deliveries, List<RouteDriver> drivers) {
    // Group deliveries by driver
    final Map<String, List<RouteDelivery>> byDriver = {};
    
    for (final delivery in deliveries) {
      if (delivery.driverId != null) {
        byDriver.putIfAbsent(delivery.driverId!, () => []);
        byDriver[delivery.driverId!]!.add(delivery);
      }
    }

    if (byDriver.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn nào được phân',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: byDriver.length,
      itemBuilder: (context, index) {
        final driverId = byDriver.keys.elementAt(index);
        final driverDeliveries = byDriver[driverId]!;
        final driver = drivers.firstWhere(
          (d) => d.id == driverId,
          orElse: () => RouteDriver(id: driverId, fullName: 'Unknown'),
        );

        return _DriverRouteCard(
          driver: driver,
          deliveries: driverDeliveries,
          onStartRoute: () => _startRoute(driverId, driverDeliveries),
        );
      },
    );
  }

  void _showAssignDriverDialog(List<RouteDriver> drivers) {
    String? selectedDriverId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Phân tài xế'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân ${_selectedDeliveryIds.length} đơn hàng cho tài xế:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDriverId,
                decoration: const InputDecoration(
                  labelText: 'Chọn tài xế',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: drivers.map((driver) => DropdownMenuItem(
                  value: driver.id,
                  child: Text(driver.fullName),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedDriverId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedDriverId != null
                  ? () => _assignDriver(selectedDriverId!)
                  : null,
              child: const Text('Phân công'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignDriver(String driverId) async {
    try {
      Navigator.pop(context);
      
      for (final deliveryId in _selectedDeliveryIds) {
        await supabase.from('deliveries').update({
          'driver_id': driverId,
          'status': 'planned',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', deliveryId);
      }

      setState(() {
        _selectedDeliveryIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã phân công tài xế thành công'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(routeDeliveriesProvider);
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

  Future<void> _startRoute(String driverId, List<RouteDelivery> deliveries) async {
    try {
      for (final delivery in deliveries) {
        await supabase.from('deliveries').update({
          'status': 'in_progress',
          'started_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', delivery.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bắt đầu lộ trình với ${deliveries.length} điểm giao'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(routeDeliveriesProvider);
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

class _DeliveryCard extends StatelessWidget {
  final RouteDelivery delivery;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDriver;

  const _DeliveryCard({
    required this.delivery,
    this.isSelectable = false,
    this.isSelected = false,
    this.onTap,
    this.showDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isSelectable)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap?.call(),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          delivery.orderNumber ?? delivery.deliveryNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(delivery.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getStatusLabel(delivery.status),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getStatusColor(delivery.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delivery.customerName ?? 'Khách hàng',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (delivery.customerAddress != null)
                      Text(
                        delivery.customerAddress!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(delivery.deliveryDate),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (showDriver && delivery.driverName != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.person, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            delivery.driverName!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                        if (delivery.latitude != null) ...[
                          const Spacer(),
                          Icon(Icons.location_on, size: 12, color: Colors.green[500]),
                          const SizedBox(width: 4),
                          Text(
                            'GPS',
                            style: TextStyle(fontSize: 12, color: Colors.green[600]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'ready':
        return Colors.orange;
      case 'in_progress':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Đã phân';
      case 'ready':
        return 'Sẵn sàng';
      case 'in_progress':
        return 'Đang giao';
      default:
        return status;
    }
  }
}

class _DriverRouteCard extends StatelessWidget {
  final RouteDriver driver;
  final List<RouteDelivery> deliveries;
  final VoidCallback onStartRoute;

  const _DriverRouteCard({
    required this.driver,
    required this.deliveries,
    required this.onStartRoute,
  });

  @override
  Widget build(BuildContext context) {
    final hasGPS = deliveries.any((d) => d.latitude != null);
    final inProgress = deliveries.any((d) => d.status == 'in_progress');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    driver.fullName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${deliveries.length} điểm giao',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!inProgress)
                  ElevatedButton.icon(
                    onPressed: onStartRoute,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Bắt đầu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Đang giao',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Deliveries list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: deliveries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
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
                          delivery.customerName ?? 'Khách hàng',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (delivery.customerAddress != null)
                          Text(
                            delivery.customerAddress!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (delivery.latitude != null)
                    Icon(Icons.location_on, size: 16, color: Colors.green[500]),
                ],
              );
            },
          ),
          if (hasGPS)
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Open route in map
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng bản đồ đang phát triển')),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('Xem trên bản đồ'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
