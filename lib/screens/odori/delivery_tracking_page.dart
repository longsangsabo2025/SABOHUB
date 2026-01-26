import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/odori_models.dart';
import '../../services/odori_service.dart';
import '../../services/gps_tracking_service.dart';

/// Delivery Tracking Page - Real-time GPS tracking during deliveries
class DeliveryTrackingPage extends ConsumerStatefulWidget {
  final String deliveryId;

  const DeliveryTrackingPage({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends ConsumerState<DeliveryTrackingPage> {
  OdoriDelivery? _delivery;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDelivery();
  }

  Future<void> _loadDelivery() async {
    try {
      final delivery = await odoriService.getDeliveryById(widget.deliveryId);
      setState(() {
        _delivery = delivery;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingStateProvider);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Theo dõi giao hàng')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Theo dõi giao hàng')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDelivery,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn ${_delivery?.deliveryNumber ?? ''}'),
        actions: [
          _buildStatusChip(trackingState.state),
        ],
      ),
      body: Column(
        children: [
          // Delivery Info Card
          _buildDeliveryInfoCard(),
          
          // GPS Position Card
          _buildPositionCard(trackingState),
          
          // Tracking Controls
          Expanded(
            child: _buildTrackingContent(trackingState),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(trackingState),
    );
  }

  Widget _buildStatusChip(TrackingState state) {
    Color color;
    String label;
    
    switch (state) {
      case TrackingState.idle:
        color = Colors.grey;
        label = 'Chưa bắt đầu';
        break;
      case TrackingState.starting:
        color = Colors.orange;
        label = 'Đang khởi động...';
        break;
      case TrackingState.tracking:
        color = Colors.green;
        label = 'Đang theo dõi';
        break;
      case TrackingState.paused:
        color = Colors.amber;
        label = 'Tạm dừng';
        break;
      case TrackingState.error:
        color = Colors.red;
        label = 'Lỗi';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    if (_delivery == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _delivery!.customer?.name ?? 'Khách hàng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _delivery!.shippingAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (_delivery!.driverId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.drive_eta, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Tài xế: ${_delivery!.driverId}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  'Trạng thái',
                  _delivery!.statusLabel,
                  _getStatusColor(_delivery!.status),
                ),
                _buildInfoItem(
                  'Ngày giao',
                  _formatDate(_delivery!.expectedDate),
                  Colors.black87,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionCard(TrackingStateData trackingState) {
    final position = trackingState.lastPosition;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Vị trí hiện tại',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (position != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildCoordinate('Vĩ độ', position.latitude.toStringAsFixed(6)),
                  ),
                  Expanded(
                    child: _buildCoordinate('Kinh độ', position.longitude.toStringAsFixed(6)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCoordinate('Độ chính xác', '${position.accuracy.toStringAsFixed(1)}m'),
                  ),
                  if (position.speed != null)
                    Expanded(
                      child: _buildCoordinate('Tốc độ', '${(position.speed! * 3.6).toStringAsFixed(1)} km/h'),
                    ),
                ],
              ),
            ] else ...[
              const Center(
                child: Text(
                  'Chưa có dữ liệu vị trí',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinate(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingContent(TrackingStateData trackingState) {
    if (trackingState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              trackingState.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    switch (trackingState.state) {
      case TrackingState.idle:
        return _buildIdleState();
      case TrackingState.starting:
        return _buildStartingState();
      case TrackingState.tracking:
        return _buildTrackingState(trackingState);
      case TrackingState.paused:
        return _buildPausedState();
      case TrackingState.error:
        return _buildErrorState(trackingState);
    }
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gps_fixed, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Nhấn "Bắt đầu giao hàng" để theo dõi GPS',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vị trí sẽ được cập nhật tự động',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Đang khởi động GPS...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng đợi trong giây lát',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingState(TrackingStateData trackingState) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Animated tracking indicator
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
            border: Border.all(color: Colors.green, width: 3),
          ),
          child: const Icon(
            Icons.navigation,
            size: 48,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Đang theo dõi vị trí',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cập nhật lần cuối: ${_formatTime(trackingState.lastPosition?.timestamp)}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        
        // Distance to destination (if available)
        if (_delivery?.currentLatitude != null && trackingState.lastPosition != null)
          _buildDistanceCard(trackingState),
      ],
    );
  }

  Widget _buildDistanceCard(TrackingStateData trackingState) {
    final distance = gpsTrackingService.calculateDistance(
      trackingState.lastPosition!.latitude,
      trackingState.lastPosition!.longitude,
      _delivery!.currentLatitude!,
      _delivery!.currentLongitude!,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.straighten, color: Colors.orange.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Khoảng cách đến điểm giao',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDistance(distance),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
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

  Widget _buildPausedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_filled, size: 64, color: Colors.amber.shade600),
          const SizedBox(height: 16),
          const Text(
            'Theo dõi tạm dừng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn tiếp tục để theo dõi lại',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TrackingStateData trackingState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            trackingState.error ?? 'Đã xảy ra lỗi',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(trackingStateProvider.notifier).startTracking(widget.deliveryId),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(TrackingStateData trackingState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (trackingState.state == TrackingState.idle ||
                trackingState.state == TrackingState.error)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(trackingStateProvider.notifier).startTracking(widget.deliveryId),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu giao hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (trackingState.state == TrackingState.tracking) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(trackingStateProvider.notifier).pauseTracking(),
                  icon: const Icon(Icons.pause),
                  label: const Text('Tạm dừng'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCompleteDialog,
                  icon: const Icon(Icons.check),
                  label: const Text('Hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            if (trackingState.state == TrackingState.paused) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(trackingStateProvider.notifier).stopTracking(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Hủy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(trackingStateProvider.notifier).resumeTracking(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Tiếp tục'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành giao hàng?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xác nhận đã giao hàng thành công cho khách hàng.'),
            SizedBox(height: 12),
            Text(
              'Vị trí hiện tại sẽ được ghi nhận làm điểm giao hàng.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _completeDelivery();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeDelivery() async {
    final delivery = await ref.read(trackingStateProvider.notifier).completeDelivery();
    
    if (delivery != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giao hàng thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.inTransit:
        return Colors.blue;
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
