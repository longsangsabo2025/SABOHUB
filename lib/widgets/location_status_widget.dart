import 'package:flutter/material.dart';

import '../services/location_service.dart';

/// Widget hiển thị trạng thái vị trí và kiểm tra location cho check-in
class LocationStatusWidget extends StatefulWidget {
  final String? companyId;
  final String? branchId;
  final Function(LocationValidationResult?)? onLocationValidated;

  const LocationStatusWidget({
    super.key,
    this.companyId,
    this.branchId,
    this.onLocationValidated,
  });

  @override
  State<LocationStatusWidget> createState() => _LocationStatusWidgetState();
}

class _LocationStatusWidgetState extends State<LocationStatusWidget> {
  final LocationService _locationService = LocationService();
  LocationValidationResult? _locationResult;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _locationService.validateCheckInLocation(
        companyId: widget.companyId,
        branchId: widget.branchId,
      );

      setState(() {
        _locationResult = result;
        _isLoading = false;
      });

      widget.onLocationValidated?.call(result);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _locationResult = null;
      });

      widget.onLocationValidated?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getIconColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kiểm tra vị trí',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(),
                  ),
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _checkLocation,
                  icon: const Icon(Icons.refresh, size: 20),
                  color: _getTextColor(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Text(
              'Đang kiểm tra vị trí...',
              style: TextStyle(color: Colors.grey),
            )
          else if (_error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lỗi: $_error',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Kiểm tra kết nối internet\n• Bật GPS và cho phép truy cập vị trí\n• Đảm bảo bạn đang ở gần công ty',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else if (_locationResult != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationResult!.statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _locationResult!.accuracyMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (!_locationResult!.isValid) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ Bạn cần ở gần công ty để điểm danh',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (_isLoading) return Colors.blue.shade50;
    if (_error != null) return Colors.red.shade50;
    if (_locationResult?.isValid == true) return Colors.green.shade50;
    return Colors.orange.shade50;
  }

  Color _getBorderColor() {
    if (_isLoading) return Colors.blue.shade300;
    if (_error != null) return Colors.red.shade300;
    if (_locationResult?.isValid == true) return Colors.green.shade300;
    return Colors.orange.shade300;
  }

  Color _getIconColor() {
    if (_isLoading) return Colors.blue;
    if (_error != null) return Colors.red;
    if (_locationResult?.isValid == true) return Colors.green;
    return Colors.orange;
  }

  Color _getTextColor() {
    if (_isLoading) return Colors.blue.shade800;
    if (_error != null) return Colors.red.shade800;
    if (_locationResult?.isValid == true) return Colors.green.shade800;
    return Colors.orange.shade800;
  }

  IconData _getStatusIcon() {
    if (_isLoading) return Icons.location_searching;
    if (_error != null) return Icons.location_off;
    if (_locationResult?.isValid == true) return Icons.location_on;
    return Icons.location_city;
  }
}

/// Widget hiển thị thông tin chi tiết về location
class LocationDetailsWidget extends StatelessWidget {
  final LocationValidationResult locationResult;

  const LocationDetailsWidget({
    super.key,
    required this.locationResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết vị trí',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildLocationInfo(
            'Vị trí hiện tại',
            '${locationResult.currentLocation.latitude.toStringAsFixed(6)}, ${locationResult.currentLocation.longitude.toStringAsFixed(6)}',
            Icons.my_location,
          ),
          const SizedBox(height: 8),
          _buildLocationInfo(
            'Vị trí công ty',
            '${locationResult.companyLocation.latitude.toStringAsFixed(6)}, ${locationResult.companyLocation.longitude.toStringAsFixed(6)}',
            Icons.business,
          ),
          const SizedBox(height: 8),
          _buildLocationInfo(
            'Khoảng cách',
            '${locationResult.distance.toInt()}m (cho phép: ${locationResult.allowedRadius.toInt()}m)',
            Icons.straighten,
          ),
          const SizedBox(height: 8),
          _buildLocationInfo(
            'Độ chính xác GPS',
            '±${locationResult.accuracy.toInt()}m',
            Icons.gps_fixed,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
