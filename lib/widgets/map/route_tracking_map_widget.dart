import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'sabo_map_widget.dart';
import '../../services/location_service.dart';

/// Widget map theo dõi route giao hàng real-time
class RouteTrackingMapWidget extends StatefulWidget {
  /// Danh sách điểm dừng (customers)
  final List<RouteStop> stops;
  
  /// Index điểm dừng hiện tại
  final int currentStopIndex;
  
  /// Callback khi chọn điểm dừng
  final void Function(int index)? onStopSelected;
  
  /// Hiển thị route line
  final bool showRouteLine;
  
  /// Tự động cập nhật vị trí
  final bool autoTrack;
  
  /// Interval cập nhật (seconds)
  final int trackingInterval;

  const RouteTrackingMapWidget({
    super.key,
    required this.stops,
    this.currentStopIndex = 0,
    this.onStopSelected,
    this.showRouteLine = true,
    this.autoTrack = true,
    this.trackingInterval = 5,
  });

  @override
  State<RouteTrackingMapWidget> createState() => _RouteTrackingMapWidgetState();
}

class _RouteTrackingMapWidgetState extends State<RouteTrackingMapWidget> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  
  LatLng? _currentLocation;
  StreamSubscription? _positionSubscription;
  List<LatLng> _traveledPath = [];

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initTracking() async {
    try {
      // Get initial position
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _traveledPath.add(_currentLocation!);
        });
      }

      // Start continuous tracking if enabled
      if (widget.autoTrack) {
        _positionSubscription = _locationService.getPositionStream(
          distanceFilter: 10,
        ).listen((position) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
              _traveledPath.add(_currentLocation!);
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing tracking: $e');
    }
  }

  List<SaboMapMarker> _buildMarkers() {
    final markers = <SaboMapMarker>[];
    
    for (int i = 0; i < widget.stops.length; i++) {
      final stop = widget.stops[i];
      final isCompleted = i < widget.currentStopIndex;
      final isCurrent = i == widget.currentStopIndex;
      
      markers.add(SaboMapMarker(
        id: stop.id,
        position: stop.location,
        color: isCompleted 
            ? Colors.green 
            : isCurrent 
                ? Colors.orange 
                : Colors.grey,
        icon: isCompleted 
            ? Icons.check_circle 
            : isCurrent 
                ? Icons.location_on 
                : Icons.radio_button_unchecked,
        label: '${i + 1}. ${stop.name}',
        data: i,
      ));
    }
    
    return markers;
  }

  List<SaboMapPolyline> _buildPolylines() {
    final polylines = <SaboMapPolyline>[];
    
    // Traveled path (green)
    if (_traveledPath.length >= 2) {
      polylines.add(SaboMapPolyline(
        id: 'traveled',
        points: _traveledPath,
        color: Colors.green,
        strokeWidth: 4,
      ));
    }
    
    // Remaining route (blue dotted)
    if (widget.showRouteLine && widget.stops.isNotEmpty) {
      final remainingPoints = <LatLng>[];
      
      if (_currentLocation != null) {
        remainingPoints.add(_currentLocation!);
      }
      
      for (int i = widget.currentStopIndex; i < widget.stops.length; i++) {
        remainingPoints.add(widget.stops[i].location);
      }
      
      if (remainingPoints.length >= 2) {
        polylines.add(SaboMapPolyline(
          id: 'remaining',
          points: remainingPoints,
          color: Colors.blue,
          strokeWidth: 3,
          isDotted: true,
        ));
      }
    }
    
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SaboMapWidget(
          mapController: _mapController,
          initialCenter: widget.stops.isNotEmpty 
              ? widget.stops[widget.currentStopIndex].location 
              : null,
          initialZoom: 14,
          currentLocation: _currentLocation,
          showCurrentLocation: true,
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
          onMarkerTap: (marker) {
            if (marker.data is int && widget.onStopSelected != null) {
              widget.onStopSelected!(marker.data as int);
            }
          },
        ),
        
        // Control buttons
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              // Center on current location
              _MapButton(
                icon: Icons.my_location,
                onPressed: () {
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 16);
                  }
                },
              ),
              const SizedBox(height: 8),
              // Fit all stops
              _MapButton(
                icon: Icons.fit_screen,
                onPressed: () {
                  if (widget.stops.isNotEmpty) {
                    final points = widget.stops.map((s) => s.location).toList();
                    if (_currentLocation != null) {
                      points.add(_currentLocation!);
                    }
                    final bounds = LatLngBounds.fromPoints(points);
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(50),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              // Center on current stop
              _MapButton(
                icon: Icons.store,
                onPressed: () {
                  if (widget.currentStopIndex < widget.stops.length) {
                    _mapController.move(
                      widget.stops[widget.currentStopIndex].location,
                      16,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        
        // Progress indicator
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.currentStopIndex}/${widget.stops.length} điểm',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Button điều khiển map
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

/// Model cho điểm dừng trên route
class RouteStop {
  final String id;
  final String name;
  final LatLng location;
  final String? address;
  final String? phone;
  final RouteStopStatus status;
  final dynamic data;

  const RouteStop({
    required this.id,
    required this.name,
    required this.location,
    this.address,
    this.phone,
    this.status = RouteStopStatus.pending,
    this.data,
  });
}

enum RouteStopStatus {
  pending,
  inProgress,
  completed,
  skipped,
}
