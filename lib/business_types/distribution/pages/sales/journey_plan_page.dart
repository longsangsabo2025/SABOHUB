import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/sales_route_service.dart';
import '../../services/store_visit_service.dart';
import 'package:geolocator/geolocator.dart';

/// Journey Plan Page - for daily route planning and execution
class JourneyPlanPage extends ConsumerStatefulWidget {
  const JourneyPlanPage({super.key});

  @override
  ConsumerState<JourneyPlanPage> createState() => _JourneyPlanPageState();
}

class _JourneyPlanPageState extends ConsumerState<JourneyPlanPage> {
  bool _isStarting = false;
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final journeyPlanAsync = ref.watch(todayJourneyPlanProvider);
    final todayStatsAsync = ref.watch(todayVisitStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch hành trình'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Chọn ngày',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(todayJourneyPlanProvider);
              ref.invalidate(todayVisitStatsProvider);
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: journeyPlanAsync.when(
        data: (journeyPlan) {
          if (journeyPlan == null) {
            return _buildNoJourneyPlan();
          }
          return Column(
            children: [
              _buildJourneyHeader(journeyPlan, todayStatsAsync),
              Expanded(
                child: _buildStopsList(journeyPlan),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(todayJourneyPlanProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: journeyPlanAsync.value != null
          ? _buildActionButton(journeyPlanAsync.value!)
          : null,
    );
  }

  Widget _buildNoJourneyPlan() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có kế hoạch hành trình hôm nay',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo kế hoạch từ tuyến bán hàng',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createFromRoute,
            icon: const Icon(Icons.add),
            label: const Text('Tạo kế hoạch'),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyHeader(JourneyPlan plan, AsyncValue<TodayVisitStats> statsAsync) {
    final statusColor = _getStatusColor(plan.status);
    final statusText = _getStatusText(plan.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(30),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (plan.routeName != null)
                Chip(
                  avatar: const Icon(Icons.route, size: 18),
                  label: Text(plan.routeName!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(plan.planDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatItem(
                Icons.store,
                '${plan.visitsCompleted}/${plan.totalVisitsPlanned}',
                'Đã ghé thăm',
              ),
              const SizedBox(width: 24),
              statsAsync.when(
                data: (stats) => _buildStatItem(
                  Icons.timer,
                  '${stats.avgDurationMinutes} phút',
                  'TB/điểm',
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 24),
              statsAsync.when(
                data: (stats) => _buildStatItem(
                  Icons.attach_money,
                  NumberFormat.compact().format(stats.totalOrderAmount),
                  'Doanh số',
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: plan.completionRate,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStopsList(JourneyPlan plan) {
    final stops = plan.stops ?? [];
    if (stops.isEmpty) {
      return const Center(child: Text('Không có điểm dừng'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        return _buildStopCard(stop, index == 0, index == stops.length - 1);
      },
    );
  }

  Widget _buildStopCard(JourneyPlanStop stop, bool isFirst, bool isLast) {
    final statusColor = _getStopStatusColor(stop.status);
    final isActive = stop.status == 'pending' || stop.status == 'arrived';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: isActive ? () => _showStopActions(stop) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Timeline indicator
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${stop.stopOrder}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stop.customerName ?? 'Khách hàng',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildStopStatusChip(stop.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (stop.customerAddress != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stop.customerAddress!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (stop.actualArrivalTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Check-in: ${DateFormat('HH:mm').format(stop.actualArrivalTime!)}',
                            style: TextStyle(color: Colors.green[600], fontSize: 12),
                          ),
                          if (stop.departureTime != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Check-out: ${DateFormat('HH:mm').format(stop.departureTime!)}',
                              style: TextStyle(color: Colors.blue[600], fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (stop.skipReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lý do bỏ qua: ${stop.skipReason}',
                        style: TextStyle(color: Colors.orange[700], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              // Action button
              if (isActive)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Hoàn thành';
        icon = Icons.check_circle;
        break;
      case 'arrived':
        color = Colors.blue;
        text = 'Đang ghé';
        icon = Icons.location_on;
        break;
      case 'skipped':
        color = Colors.orange;
        text = 'Bỏ qua';
        icon = Icons.skip_next;
        break;
      default:
        color = Colors.grey;
        text = 'Chờ';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget? _buildActionButton(JourneyPlan plan) {
    if (plan.status == 'planned') {
      return FloatingActionButton.extended(
        onPressed: _isStarting ? null : () => _startJourney(plan.id),
        icon: _isStarting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isStarting ? 'Đang bắt đầu...' : 'Bắt đầu hành trình'),
        backgroundColor: Colors.green,
      );
    } else if (plan.status == 'in-progress' &&
        plan.visitsCompleted >= plan.totalVisitsPlanned) {
      return FloatingActionButton.extended(
        onPressed: _isCompleting ? null : () => _completeJourney(plan.id),
        icon: _isCompleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check),
        label: Text(_isCompleting ? 'Đang hoàn thành...' : 'Kết thúc hành trình'),
        backgroundColor: Colors.blue,
      );
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in-progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'planned':
        return 'Đã lên kế hoạch';
      case 'in-progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getStopStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'arrived':
        return Colors.blue;
      case 'skipped':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      // TODO: Load journey plan for selected date
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xem kế hoạch ngày ${DateFormat('dd/MM').format(date)}')),
      );
    }
  }

  Future<void> _createFromRoute() async {
    // Show route selection dialog
    final routes = await ref.read(salesRoutesProvider.future);
    if (!mounted) return;

    final selectedRoute = await showDialog<SalesRoute>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn tuyến bán hàng'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return ListTile(
                leading: const Icon(Icons.route),
                title: Text(route.name),
                subtitle: Text(route.territory ?? 'Không có khu vực'),
                onTap: () => Navigator.pop(context, route),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedRoute != null) {
      try {
        final service = ref.read(salesRouteServiceProvider);
        await service.createJourneyPlanFromRoute(
          routeId: selectedRoute.id,
          employeeId: '', // TODO: Get current user ID
          planDate: DateTime.now(),
        );
        ref.invalidate(todayJourneyPlanProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tạo kế hoạch hành trình')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _startJourney(String planId) async {
    setState(() => _isStarting = true);
    try {
      final location = await _getCurrentLocation();
      final service = ref.read(salesRouteServiceProvider);
      await service.startJourney(planId, location: location);
      ref.invalidate(todayJourneyPlanProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bắt đầu hành trình!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _completeJourney(String planId) async {
    setState(() => _isCompleting = true);
    try {
      final location = await _getCurrentLocation();
      final service = ref.read(salesRouteServiceProvider);
      await service.completeJourney(planId, location: location);
      ref.invalidate(todayJourneyPlanProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn thành hành trình!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  void _showStopActions(JourneyPlanStop stop) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.store, color: Colors.blue),
              title: Text(stop.customerName ?? 'Khách hàng'),
              subtitle: Text(stop.customerAddress ?? ''),
            ),
            const Divider(),
            if (stop.status == 'pending')
              ListTile(
                leading: const Icon(Icons.login, color: Colors.green),
                title: const Text('Check-in'),
                onTap: () {
                  Navigator.pop(context);
                  _checkInStop(stop);
                },
              ),
            if (stop.status == 'arrived')
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.blue),
                title: const Text('Check-out'),
                onTap: () {
                  Navigator.pop(context);
                  _checkOutStop(stop);
                },
              ),
            if (stop.status == 'pending')
              ListTile(
                leading: const Icon(Icons.skip_next, color: Colors.orange),
                title: const Text('Bỏ qua điểm này'),
                onTap: () {
                  Navigator.pop(context);
                  _skipStop(stop);
                },
              ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.teal),
              title: const Text('Gọi điện'),
              onTap: () async {
                Navigator.pop(context);
                if (stop.customerPhone != null && stop.customerPhone!.isNotEmpty) {
                  final uri = Uri.parse('tel:${stop.customerPhone}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions, color: Colors.indigo),
              title: const Text('Chỉ đường'),
              onTap: () async {
                Navigator.pop(context);
                // Use coordinates if available, otherwise use address
                String destination;
                if (stop.latitude != null && stop.longitude != null) {
                  destination = '${stop.latitude},${stop.longitude}';
                } else if (stop.customerAddress != null && stop.customerAddress!.isNotEmpty) {
                  // Clean address: remove notes after '--'
                  String cleanAddress = stop.customerAddress!;
                  if (cleanAddress.contains('--')) {
                    cleanAddress = cleanAddress.split('--').first.trim();
                  }
                  destination = Uri.encodeComponent(cleanAddress);
                } else {
                  return;
                }
                final uri = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=$destination&travelmode=driving',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkInStop(JourneyPlanStop stop) async {
    try {
      final location = await _getCurrentLocation();
      
      // Check in via store visit service
      final visitService = ref.read(storeVisitServiceProvider);
      await visitService.checkIn(
        customerId: stop.customerId,
        location: location ?? {},
        journeyPlanStopId: stop.id,
      );
      
      // Update stop status
      final routeService = ref.read(salesRouteServiceProvider);
      await routeService.updateStopStatus(
        stopId: stop.id,
        status: 'arrived',
        location: location,
      );
      
      ref.invalidate(todayJourneyPlanProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi check-in: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkOutStop(JourneyPlanStop stop) async {
    // Show checkout dialog for notes
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _CheckoutDialog(),
    );
    
    if (result == null) return;
    
    try {
      final location = await _getCurrentLocation();
      
      // Check out via store visit service
      if (stop.storeVisitId != null) {
        final visitService = ref.read(storeVisitServiceProvider);
        await visitService.checkOut(
          visitId: stop.storeVisitId!,
          location: location ?? {},
          outcomes: result['outcomes'],
          issuesReported: result['issues'],
        );
      }
      
      // Update stop status
      final routeService = ref.read(salesRouteServiceProvider);
      await routeService.updateStopStatus(
        stopId: stop.id,
        status: 'completed',
        location: location,
      );
      
      ref.invalidate(todayJourneyPlanProvider);
      ref.invalidate(todayVisitStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-out thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi check-out: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _skipStop(JourneyPlanStop stop) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ qua điểm dừng'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Lý do bỏ qua',
            hintText: 'VD: Cửa hàng đóng cửa...',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Không có lý do cụ thể'),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final service = ref.read(salesRouteServiceProvider);
        await service.updateStopStatus(
          stopId: stop.id,
          status: 'skipped',
          skipReason: reason,
        );
        ref.invalidate(todayJourneyPlanProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      final position = await Geolocator.getCurrentPosition();
      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }
}

class _CheckoutDialog extends StatefulWidget {
  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _outcomesController = TextEditingController();
  final _issuesController = TextEditingController();

  @override
  void dispose() {
    _outcomesController.dispose();
    _issuesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Check-out'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _outcomesController,
            decoration: const InputDecoration(
              labelText: 'Kết quả ghé thăm',
              hintText: 'VD: Đặt hàng 10 thùng...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _issuesController,
            decoration: const InputDecoration(
              labelText: 'Vấn đề ghi nhận (nếu có)',
              hintText: 'VD: Cần hỗ trợ kỹ thuật...',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'outcomes': _outcomesController.text,
            'issues': _issuesController.text,
          }),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
