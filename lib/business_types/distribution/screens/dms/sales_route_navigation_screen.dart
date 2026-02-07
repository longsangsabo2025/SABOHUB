import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../widgets/map/map_widgets.dart';
import '../../../../services/gps_tracking_service.dart';

/// Sales Route Navigation Screen - GPS-based route navigation
/// Cập nhật: v2.0 - Tích hợp flutter_map
class SalesRouteNavigationScreen extends ConsumerStatefulWidget {
  final String routeId;
  final String journeyPlanId;

  const SalesRouteNavigationScreen({
    super.key,
    required this.routeId,
    required this.journeyPlanId,
  });

  @override
  ConsumerState<SalesRouteNavigationScreen> createState() => 
      _SalesRouteNavigationScreenState();
}

class _SalesRouteNavigationScreenState 
    extends ConsumerState<SalesRouteNavigationScreen> {
  int _currentStopIndex = 0;
  bool _isNavigating = false;
  
  // Demo data - Sẽ load từ API thực tế
  late List<RouteStop> _stops;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    // TODO: Load từ Supabase dựa trên routeId và journeyPlanId
    // Demo data cho development
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _stops = [
          const RouteStop(
            id: '1',
            name: 'Cửa hàng Minh Tâm',
            location: LatLng(10.7769, 106.7009),
            address: '123 Nguyễn Huệ, Q.1',
            phone: '0901234567',
            status: RouteStopStatus.completed,
          ),
          const RouteStop(
            id: '2', 
            name: 'Siêu thị ABC',
            location: LatLng(10.7820, 106.6950),
            address: '456 Lê Lợi, Q.1',
            phone: '0907654321',
            status: RouteStopStatus.inProgress,
          ),
          const RouteStop(
            id: '3',
            name: 'Tạp hóa Hương',
            location: LatLng(10.7750, 106.6880),
            address: '789 Trần Hưng Đạo, Q.5',
            phone: '0909876543',
            status: RouteStopStatus.pending,
          ),
          const RouteStop(
            id: '4',
            name: 'Đại lý Phước Thành',
            location: LatLng(10.7680, 106.6820),
            address: '321 Nguyễn Trãi, Q.5',
            phone: '0903456789',
            status: RouteStopStatus.pending,
          ),
        ];
        _currentStopIndex = 1;
        _isLoading = false;
      });
    }
  }

  void _onStopSelected(int index) {
    setState(() => _currentStopIndex = index);
    _showStopDetails(_stops[index]);
  }

  void _showStopDetails(RouteStop stop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StopDetailsSheet(
        stop: stop,
        onNavigate: () => _openExternalNavigation(stop),
        onCall: () => _callCustomer(stop),
        onCheckIn: () => _checkInAtStop(stop),
      ),
    );
  }

  Future<void> _openExternalNavigation(RouteStop stop) async {
    Navigator.pop(context);
    
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${stop.location.latitude},${stop.location.longitude}&travelmode=driving'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng bản đồ')),
        );
      }
    }
  }

  Future<void> _callCustomer(RouteStop stop) async {
    if (stop.phone == null) return;
    
    final url = Uri.parse('tel:${stop.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _checkInAtStop(RouteStop stop) async {
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã check-in tại ${stop.name}')),
    );
    
    if (_currentStopIndex < _stops.length - 1) {
      setState(() => _currentStopIndex++);
    }
  }

  void _completeRoute() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành tuyến'),
        content: Text(
          'Bạn đã hoàn thành $_currentStopIndex/${_stops.length} điểm.\n'
          'Xác nhận kết thúc tuyến đường?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều hướng tuyến đường'),
        actions: [
          if (trackingState.state == TrackingState.tracking)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gps_fixed, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text('GPS', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: RouteTrackingMapWidget(
                    stops: _stops,
                    currentStopIndex: _currentStopIndex,
                    onStopSelected: _onStopSelected,
                    showRouteLine: true,
                    autoTrack: _isNavigating,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _StopsList(
                    stops: _stops,
                    currentIndex: _currentStopIndex,
                    onStopTap: _onStopSelected,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _completeRoute,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Kết thúc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _currentStopIndex < _stops.length
                      ? () => _showStopDetails(_stops[_currentStopIndex])
                      : null,
                  icon: const Icon(Icons.navigation),
                  label: Text(
                    _currentStopIndex < _stops.length
                        ? 'Đến ${_stops[_currentStopIndex].name}'
                        : 'Hoàn thành',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopsList extends StatelessWidget {
  final List<RouteStop> stops;
  final int currentIndex;
  final void Function(int) onStopTap;

  const _StopsList({required this.stops, required this.currentIndex, required this.onStopTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.list_alt, size: 20),
                const SizedBox(width: 8),
                Text('Danh sách điểm dừng', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$currentIndex/${stops.length}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];
                return _StopListItem(stop: stop, index: index, isCompleted: index < currentIndex, isCurrent: index == currentIndex, onTap: () => onStopTap(index));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StopListItem extends StatelessWidget {
  final RouteStop stop;
  final int index;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback onTap;

  const _StopListItem({required this.stop, required this.index, required this.isCompleted, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrent ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green : isCurrent ? Theme.of(context).primaryColor : Colors.grey[300],
          child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 18) : Text('${index + 1}', style: TextStyle(color: isCurrent ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
        title: Text(stop.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, decoration: isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: stop.address != null ? Text(stop.address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12)) : null,
        trailing: isCurrent ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      ),
    );
  }
}

class _StopDetailsSheet extends StatelessWidget {
  final RouteStop stop;
  final VoidCallback? onNavigate;
  final VoidCallback? onCall;
  final VoidCallback? onCheckIn;

  const _StopDetailsSheet({required this.stop, this.onNavigate, this.onCall, this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.store, color: Theme.of(context).primaryColor)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(stop.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), if (stop.address != null) Text(stop.address!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]))])),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _ActionButton(icon: Icons.phone, label: 'Gọi điện', color: Colors.green, onTap: onCall)),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(icon: Icons.navigation, label: 'Chỉ đường', color: Colors.blue, onTap: onNavigate)),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(icon: Icons.check_circle, label: 'Check-in', color: Theme.of(context).primaryColor, onTap: onCheckIn)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))]),
      ),
    );
  }
}
