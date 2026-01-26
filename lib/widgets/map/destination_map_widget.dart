import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'sabo_map_widget.dart';
import '../../services/location_service.dart';

/// Widget hiển thị vị trí cần đến với map
class DestinationMapWidget extends StatefulWidget {
  /// Vị trí đích
  final LatLng destination;
  
  /// Tên địa điểm
  final String? destinationName;
  
  /// Địa chỉ
  final String? address;
  
  /// Callback khi bắt đầu điều hướng
  final VoidCallback? onStartNavigation;
  
  /// Chiều cao widget
  final double height;

  const DestinationMapWidget({
    super.key,
    required this.destination,
    this.destinationName,
    this.address,
    this.onStartNavigation,
    this.height = 250,
  });

  @override
  State<DestinationMapWidget> createState() => _DestinationMapWidgetState();
}

class _DestinationMapWidgetState extends State<DestinationMapWidget> {
  final LocationService _locationService = LocationService();
  LatLng? _currentLocation;
  double? _distance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            widget.destination.latitude,
            widget.destination.longitude,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Map
          SaboMapWidget(
            initialCenter: widget.destination,
            initialZoom: 15,
            currentLocation: _currentLocation,
            showCurrentLocation: _currentLocation != null,
            markers: [
              SaboMapMarker(
                id: 'destination',
                position: widget.destination,
                color: Colors.red,
                icon: Icons.store,
                label: widget.destinationName,
              ),
            ],
            polylines: _currentLocation != null ? [
              SaboMapPolyline(
                id: 'route',
                points: [_currentLocation!, widget.destination],
                color: Colors.blue,
                strokeWidth: 3,
                isDotted: true,
              ),
            ] : [],
          ),
          
          // Info overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.destinationName != null)
                          Text(
                            widget.destinationName!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.address != null)
                          Text(
                            widget.address!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (_distance != null)
                          Text(
                            'Cách ${_formatDistance(_distance!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue[200],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.onStartNavigation != null)
                    ElevatedButton.icon(
                      onPressed: widget.onStartNavigation,
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Đi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Loading
          if (_isLoading)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
