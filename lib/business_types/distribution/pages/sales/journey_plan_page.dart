import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/sales_route_service.dart';
import '../../services/store_visit_service.dart';
import '../../layouts/sales/sheets/sales_create_order_form.dart';
import '../../pages/receivables/receivable_payment_page.dart';
import '../../providers/odori_providers.dart';
import '../../pages/manager/inventory/add_sample_sheet.dart';

import '../../widgets/sales_features_widgets.dart';
import '../../widgets/sales_features_widgets_2.dart';
import 'sales_journey_map_page.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          // Map view button - only show when journey has stops
          if (journeyPlanAsync.value?.stops?.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => _openJourneyMap(journeyPlanAsync.value!),
              tooltip: 'Xem bản đồ',
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.route, size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có hành trình hôm nay',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn khách hàng cần ghé thăm để bắt đầu',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Primary: Quick create from customers
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createQuickPlan,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Lên tuyến hôm nay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary: Create from existing route
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _createFromRoute,
                icon: const Icon(Icons.route),
                label: const Text('Tạo từ tuyến có sẵn'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          const SizedBox(height: 8),
          // Map + Optimize buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openJourneyMap(plan),
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Bản đồ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openJourneyMap(plan),
                  icon: const Icon(Icons.alt_route, size: 18),
                  label: const Text('Tối ưu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade800,
                    side: BorderSide(color: Colors.amber.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
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

  void _openJourneyMap(JourneyPlan plan) async {
    final wasOptimized = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SalesJourneyMapPage(journeyPlan: plan),
      ),
    );
    // Refresh journey plan data if route was optimized
    if (wasOptimized == true && mounted) {
      ref.invalidate(todayJourneyPlanProvider);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (!mounted) return;
    if (date != null) {
      // TODO: Load journey plan for selected date
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xem kế hoạch ngày ${DateFormat('dd/MM').format(date)}')),
      );
    }
  }

  Future<void> _createFromRoute() async {
    // Show route selection dialog
    try {
      final routes = await ref.read(salesRoutesProvider.future);
      if (!mounted) return;

      if (routes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa có tuyến nào. Hãy dùng "Lên tuyến hôm nay" để chọn khách hàng trực tiếp.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

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
        final service = ref.read(salesRouteServiceProvider);
        final currentUser = ref.read(authProvider).user;
        await service.createJourneyPlanFromRoute(
          routeId: selectedRoute.id,
          employeeId: currentUser?.id ?? '',
          planDate: DateTime.now(),
        );
        ref.invalidate(todayJourneyPlanProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tạo kế hoạch hành trình')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Quick plan: let sale pick customers directly
  Future<void> _createQuickPlan() async {
    final currentUser = ref.read(authProvider).user;
    final companyId = currentUser?.companyId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin công ty'), backgroundColor: Colors.red),
      );
      return;
    }

    final selectedIds = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CustomerSelectionDialog(companyId: companyId),
    );

    if (selectedIds == null || selectedIds.isEmpty) return;

    try {
      final service = ref.read(salesRouteServiceProvider);
      await service.createQuickJourneyPlan(
        companyId: companyId,
        employeeId: currentUser!.id,
        planDate: DateTime.now(),
        customerIds: selectedIds,
      );
      ref.invalidate(todayJourneyPlanProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo hành trình với ${selectedIds.length} điểm!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo hành trình: $e'), backgroundColor: Colors.red),
        );
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
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: stop.status == 'arrived' ? 0.75 : 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => SafeArea(
        child: ListView(
          controller: scrollController,
          shrinkWrap: true,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
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
            if (stop.status == 'arrived') ...
              _buildVisitActionTiles(stop),
            // Quick actions available for pending stops too
            if (stop.status == 'pending') ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined, color: Colors.green),
                title: const Text('Tạo đơn hàng'),
                subtitle: const Text('Lên đơn trước khi đến', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _createOrderForCustomer(stop);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blueGrey),
                title: const Text('Lịch sử đơn hàng'),
                onTap: () {
                  Navigator.pop(context);
                  _showOrderHistory(stop);
                },
              ),
            ],
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
      ),
    );
  }

  /// Build action tiles for visit activities
  /// Only shown when stop is in 'arrived' status (sales has checked in)
  List<Widget> _buildVisitActionTiles(JourneyPlanStop stop) {
    return [
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 8),
        child: Text(
          'Hoạt động tại điểm bán',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // === CORE SALES ACTIONS ===
      ListTile(
        leading: const Icon(Icons.shopping_cart, color: Colors.green),
        title: const Text('Tạo đơn hàng'),
        subtitle: const Text('Lên đơn cho khách hàng này', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.pop(context);
          _createOrderForCustomer(stop);
        },
      ),
      ListTile(
        leading: const Icon(Icons.payments, color: Colors.teal),
        title: const Text('Thu tiền'),
        subtitle: const Text('Ghi nhận thanh toán / thu công nợ', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.pop(context);
          _collectPayment(stop);
        },
      ),
      ListTile(
        leading: const Icon(Icons.history, color: Colors.blueGrey),
        title: const Text('Lịch sử đơn hàng'),
        subtitle: const Text('Xem đơn hàng trước đây', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.pop(context);
          _showOrderHistory(stop);
        },
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 8),
        child: Text(
          'Khảo sát & Báo cáo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // === SURVEY & REPORTING ===
      ListTile(
        leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
        title: const Text('Chụp ảnh điểm bán'),
        subtitle: const Text('Trưng bày, kệ hàng, POSM', style: TextStyle(fontSize: 12)),
        onTap: () {
          Navigator.pop(context);
          if (stop.storeVisitId != null) {
            _showPhotoCapture(stop.storeVisitId!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cần check-in trước khi chụp ảnh')),
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.inventory, color: Colors.amber),
        title: const Text('Kiểm tồn kho'),
        subtitle: const Text('Kiểm tra tồn kệ & kho sau', style: TextStyle(fontSize: 12)),
        onTap: () {
          Navigator.pop(context);
          if (stop.storeVisitId != null) {
            _showStockCheck(stop.storeVisitId!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cần check-in trước khi kiểm tồn')),
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.card_giftcard, color: Colors.deepOrange),
        title: const Text('Gửi mẫu sản phẩm'),
        subtitle: const Text('Gửi mẫu SP cho khách hàng này', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.pop(context);
          _showSendSample(stop);
        },
      ),
      ListTile(
        leading: const Icon(Icons.people_alt, color: Colors.red),
        title: const Text('Báo cáo đối thủ'),
        subtitle: const Text('Ghi nhận hoạt động đối thủ', style: TextStyle(fontSize: 12)),
        onTap: () {
          Navigator.pop(context);
          _showCompetitorReport(stop);
        },
      ),
      ListTile(
        leading: const Icon(Icons.poll, color: Colors.purple),
        title: const Text('Khảo sát'),
        subtitle: const Text('Thực hiện khảo sát tại điểm bán', style: TextStyle(fontSize: 12)),
        onTap: () {
          Navigator.pop(context);
          _showSurveys(stop);
        },
      ),
      const Divider(),
      const Padding(
        padding: EdgeInsets.only(left: 16, top: 4, bottom: 4),
        child: Text('Quản lý khách hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ),
      ListTile(
        leading: const Icon(Icons.thermostat, color: Colors.deepPurple),
        title: const Text('Cập nhật trạng thái KH'),
        subtitle: const Text('Cold / Warm / Hot & ghi chú tương tác', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.pop(context);
          _showUpdateCustomerStatus(stop);
        },
      ),
    ];
  }

  void _createOrderForCustomer(JourneyPlanStop stop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SalesCreateOrderFormPage(
          preselectedCustomer: {
            'id': stop.customerId,
            'name': stop.customerName ?? '',
            'address': stop.customerAddress ?? '',
            'phone': stop.customerPhone ?? '',
          },
        ),
      ),
    );
  }

  void _collectPayment(JourneyPlanStop stop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceivablePaymentPage(
          preselectedCustomerId: stop.customerId,
        ),
      ),
    );
  }

  void _showOrderHistory(JourneyPlanStop stop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Đơn hàng - ${stop.customerName ?? ''}')),
          body: CustomerOrderHistory(
            customerId: stop.customerId,
          ),
        ),
      ),
    );
  }

  void _showPhotoCapture(String visitId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chụp ảnh điểm bán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: VisitPhotoCaptureButton(
                      visitId: visitId,
                      category: 'shelf_display',
                      onPhotoAdded: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ảnh đã lưu!'), backgroundColor: Colors.green),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Chụp ảnh trưng bày kệ, sản phẩm, POSM, đối thủ...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendSample(JourneyPlanStop stop) async {
    try {
      final products = await ref.read(allProductsProvider.future);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: AddSampleSheet(
              products: products,
              preselectedCustomerId: stop.customerId,
              preselectedCustomerName: stop.customerName,
              onSaved: () {
                ref.invalidate(todayJourneyPlanProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi mẫu sản phẩm thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải sản phẩm: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showUpdateCustomerStatus(JourneyPlanStop stop) async {
    // Fetch current lead_status from DB
    String currentStatus = 'cold';
    try {
      final row = await Supabase.instance.client.from('customers')
          .select('lead_status')
          .eq('id', stop.customerId)
          .maybeSingle();
      if (row != null && row['lead_status'] != null) {
        currentStatus = row['lead_status'] as String;
      }
    } catch (_) {}

    if (!mounted) return;

    String selectedStatus = currentStatus;
    final notesController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.thermostat, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Trạng thái KH\n${stop.customerName ?? ''}', style: const TextStyle(fontSize: 16))),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mức độ quan tâm:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusChip('cold', '❄️ Cold', Colors.blue, selectedStatus, (v) {
                          setDialogState(() => selectedStatus = v);
                        }),
                        const SizedBox(width: 8),
                        _buildStatusChip('warm', '🔥 Warm', Colors.orange, selectedStatus, (v) {
                          setDialogState(() => selectedStatus = v);
                        }),
                        const SizedBox(width: 8),
                        _buildStatusChip('hot', '🔴 Hot', Colors.red, selectedStatus, (v) {
                          setDialogState(() => selectedStatus = v);
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Ghi chú tương tác:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: KH quan tâm sản phẩm mới, hẹn gặp lại tuần sau...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, {
                    'status': selectedStatus,
                    'notes': notesController.text.trim(),
                  }),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    try {
      final currentUser = ref.read(authProvider).user;
      await Supabase.instance.client.from('customers').update({
        'lead_status': result['status'],
        'last_interaction_notes': result['notes'],
        'last_interaction_date': DateTime.now().toIso8601String(),
        'last_interaction_by': currentUser?.id,
      }).eq('id', stop.customerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái KH → ${_leadStatusLabel(result['status'] as String)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatusChip(String value, String label, Color color, String selected, ValueChanged<String> onSelected) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey.shade700,
              fontSize: 13,
            )),
          ),
        ),
      ),
    );
  }

  String _leadStatusLabel(String status) {
    switch (status) {
      case 'hot': return '🔴 Hot';
      case 'warm': return '🔥 Warm';
      default: return '❄️ Cold';
    }
  }

  void _showCompetitorReport(JourneyPlanStop stop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompetitorReportForm(
          customerId: stop.customerId,
          visitId: stop.storeVisitId,
          onSaved: () {
            ref.invalidate(todayJourneyPlanProvider);
          },
        ),
      ),
    );
  }

  void _showStockCheck(String visitId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StockCheckForm(
          visitId: visitId,
          onSaved: () {
            ref.invalidate(todayJourneyPlanProvider);
          },
        ),
      ),
    );
  }

  void _showSurveys(JourneyPlanStop stop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Khảo sát tại điểm bán')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SurveysList(
              customerId: stop.customerId,
              visitId: stop.storeVisitId,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkInStop(JourneyPlanStop stop) async {
    try {
      final location = await _getCurrentLocation();
      final currentUser = ref.read(authProvider).user;
      
      // Check in via store visit service
      final visitService = ref.read(storeVisitServiceProvider);
      await visitService.checkIn(
        customerId: stop.customerId,
        location: location ?? {},
        journeyPlanId: stop.journeyPlanId,
        journeyPlanStopId: stop.id,
        visitPurpose: ['sales'],
        visitType: 'scheduled',
        employeeId: currentUser?.id,
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
        final currentUser = ref.read(authProvider).user;
        await visitService.checkOut(
          visitId: stop.storeVisitId!,
          location: location ?? {},
          customerFeedback: result['outcomes'],
          nextVisitNotes: result['issues'],
          employeeId: currentUser?.id,
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

/// Dialog for selecting customers to create a quick journey plan
class _CustomerSelectionDialog extends StatefulWidget {
  final String companyId;

  const _CustomerSelectionDialog({required this.companyId});

  @override
  State<_CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<_CustomerSelectionDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _customers = [];
  final Set<String> _selectedIds = {};
  final List<Map<String, dynamic>> _selectedCustomers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  // Area filters
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _routes = [];
  String? _selectedDistrict;
  String? _selectedRoute;
  bool _filtersLoaded = false;
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final service = SalesRouteService();
      final districtsFuture = service.getDistrictsDirect(companyId: widget.companyId);
      final routesFuture = service.getRoutesDirect(companyId: widget.companyId);
      final results = await Future.wait([districtsFuture, routesFuture]);
      if (mounted) {
        setState(() {
          _districts = results[0];
          _routes = results[1];
          _filtersLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> _loadCustomers({String? search, String? district, String? route}) async {
    setState(() => _isLoading = true);
    try {
      final service = SalesRouteService();
      final customers = await service.getCustomersForSelection(
        companyId: widget.companyId,
        search: search,
        district: district,
        route: route,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải KH: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    if (_isSearching) return;
    _isSearching = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      _isSearching = false;
      if (mounted) {
        _applyFilters();
      }
    });
  }

  void _applyFilters() {
    _loadCustomers(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      district: _selectedDistrict,
      route: _selectedRoute,
    );
  }

  void _toggleCustomer(Map<String, dynamic> customer) {
    final id = customer['id'] as String;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectedCustomers.removeWhere((c) => c['id'] == id);
      } else {
        _selectedIds.add(id);
        _selectedCustomers.add(customer);
      }
    });
  }

  void _selectAllVisible() {
    setState(() {
      for (final c in _customers) {
        final id = c['id'] as String;
        if (!_selectedIds.contains(id)) {
          _selectedIds.add(id);
          _selectedCustomers.add(c);
        }
      }
    });
  }

  void _reorderSelected(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _selectedCustomers.removeAt(oldIndex);
      _selectedCustomers.insert(newIndex, item);
    });
  }

  String _formatDistrictLabel(String district) {
    // Prefix quận/huyện numbers
    final numOnly = int.tryParse(district);
    if (numOnly != null) return 'Quận $district';
    return district;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedDistrict != null || _selectedRoute != null;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Chọn khách hàng (${_selectedIds.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_customers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: 'Chọn tất cả đang hiển thị',
                onPressed: _selectAllVisible,
              ),
            TextButton(
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () {
                      final orderedIds = _selectedCustomers
                          .map((c) => c['id'] as String)
                          .toList();
                      Navigator.pop(context, orderedIds);
                    },
              child: Text(
                'Xác nhận (${_selectedIds.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _selectedIds.isEmpty ? Colors.grey : Colors.blue,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Selected customers strip (reorderable)
            if (_selectedCustomers.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Thứ tự ghé thăm (kéo để sắp xếp)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 40,
                      child: ReorderableListView(
                        scrollDirection: Axis.horizontal,
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(20),
                            child: child,
                          );
                        },
                        onReorder: _reorderSelected,
                        children: [
                          for (int i = 0; i < _selectedCustomers.length; i++)
                            ReorderableDragStartListener(
                              key: ValueKey(_selectedCustomers[i]['id']),
                              index: i,
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${i + 1}.',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedCustomers[i]['name'] as String? ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _toggleCustomer(_selectedCustomers[i]),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Area filter section
            if (_filtersLoaded && (_districts.isNotEmpty || _routes.isNotEmpty)) ...[
              InkWell(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: hasActiveFilters ? Colors.green.shade50 : Colors.grey.shade50,
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 18,
                        color: hasActiveFilters ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lọc theo khu vực',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: hasActiveFilters ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                      ),
                      if (hasActiveFilters) ...[  
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_customers.length} KH',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (hasActiveFilters)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDistrict = null;
                              _selectedRoute = null;
                            });
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.clear, size: 14, color: Colors.red.shade600),
                                const SizedBox(width: 4),
                                Text('Xóa lọc', style: TextStyle(fontSize: 12, color: Colors.red.shade600)),
                              ],
                            ),
                          ),
                        ),
                      Icon(
                        _showFilters ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showFilters) ...[
                // District chips
                if (_districts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_city, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('Quận/Huyện', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _districts.map((d) {
                              final name = d['district'] as String;
                              final count = d['count'] as int;
                              final isActive = _selectedDistrict == name;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(
                                    '${_formatDistrictLabel(name)} ($count)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive ? Colors.white : Colors.grey.shade800,
                                    ),
                                  ),
                                  selected: isActive,
                                  selectedColor: Colors.teal.shade600,
                                  backgroundColor: Colors.grey.shade100,
                                  checkmarkColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  onSelected: (selected) {
                                    setState(() => _selectedDistrict = selected ? name : null);
                                    _applyFilters();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Route chips
                if (_routes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.alt_route, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('Tuyến đường', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _routes.map((r) {
                              final name = r['route'] as String;
                              final count = r['count'] as int;
                              final isActive = _selectedRoute == name;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(
                                    '$name ($count)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive ? Colors.white : Colors.grey.shade800,
                                    ),
                                  ),
                                  selected: isActive,
                                  selectedColor: Colors.indigo.shade600,
                                  backgroundColor: Colors.grey.shade100,
                                  checkmarkColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  onSelected: (selected) {
                                    setState(() => _selectedRoute = selected ? name : null);
                                    _applyFilters();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                Divider(height: 1, color: Colors.grey.shade200),
              ],
            ],

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm khách hàng (tên, SĐT, địa chỉ)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),

            // Customer list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Không tìm thấy khách hàng',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                              ),
                              if (hasActiveFilters) ...[  
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDistrict = null;
                                      _selectedRoute = null;
                                    });
                                    _applyFilters();
                                  },
                                  child: const Text('Xóa bộ lọc'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            final id = customer['id'] as String;
                            final isSelected = _selectedIds.contains(id);
                            final name = customer['name'] as String? ?? '';
                            final address = customer['address'] as String? ?? '';
                            final phone = customer['phone'] as String? ?? '';
                            final district = customer['district'] as String? ?? '';
                            final route = customer['route'] as String? ?? '';

                            final orderNum = isSelected
                                ? _selectedCustomers.indexWhere((c) => c['id'] == id) + 1
                                : 0;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade200,
                                child: isSelected
                                    ? Text(
                                        '$orderNum',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Icon(
                                        Icons.store,
                                        color: Colors.grey.shade500,
                                        size: 20,
                                      ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      if (district.isNotEmpty) ...[  
                                        Icon(Icons.location_city, size: 11, color: Colors.teal.shade400),
                                        const SizedBox(width: 2),
                                        Text(
                                          _formatDistrictLabel(district),
                                          style: TextStyle(fontSize: 11, color: Colors.teal.shade600),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (route.isNotEmpty) ...[  
                                        Icon(Icons.alt_route, size: 11, color: Colors.indigo.shade400),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            route,
                                            style: TextStyle(fontSize: 11, color: Colors.indigo.shade600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (phone.isNotEmpty) ...[  
                                        Icon(Icons.phone, size: 11, color: Colors.grey.shade500),
                                        const SizedBox(width: 2),
                                        Text(phone, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.blue)
                                  : Icon(Icons.circle_outlined, color: Colors.grey.shade400),
                              onTap: () => _toggleCustomer(customer),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.shade50,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
