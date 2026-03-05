import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/sales_route_service.dart';
import '../../../../utils/route_optimizer.dart';
import '../../../../widgets/map/sabo_map_widget.dart';
import '../../../../utils/app_logger.dart';

/// Bản đồ hành trình sales — hiển thị tất cả điểm dừng trên bản đồ
/// GPS tracking real-time + route line + stop info
class SalesJourneyMapPage extends StatefulWidget {
  final JourneyPlan journeyPlan;

  const SalesJourneyMapPage({super.key, required this.journeyPlan});

  @override
  State<SalesJourneyMapPage> createState() => _SalesJourneyMapPageState();
}

class _SalesJourneyMapPageState extends State<SalesJourneyMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  int? _selectedStopIndex;
  RouteEstimate? _routeEstimate;
  bool _isOptimizing = false;
  bool _isRouteOptimized = false;
  late List<JourneyPlanStop> _stops;

  // Stops that have valid coordinates
  List<JourneyPlanStop> get _mappableStops =>
      _stops.where((s) => s.latitude != null && s.longitude != null).toList();

  int get _currentStopIndex {
    // First non-completed stop
    for (int i = 0; i < _stops.length; i++) {
      if (_stops[i].status == 'pending' || _stops[i].status == 'arrived') {
        return i;
      }
    }
    return _stops.length; // all completed
  }

  @override
  void initState() {
    super.initState();
    _stops = List<JourneyPlanStop>.from(widget.journeyPlan.stops ?? []);
    _initLocation();
    _calculateRouteEstimate();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _fitAllMarkers();
      }

      // Start tracking
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((position) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });
        }
      });
    } catch (e) {
      AppLogger.error('Location error: $e');
    }
  }

  void _calculateRouteEstimate() {
    if (_mappableStops.isEmpty) return;
    
    final waypoints = _mappableStops
        .map((s) => LatLng(s.latitude!, s.longitude!))
        .toList();

    final startPoint = _currentLocation ?? waypoints.first;

    setState(() {
      _routeEstimate = RouteOptimizer.estimateRoute(
        startPoint: startPoint,
        waypoints: waypoints,
        stopDurationMinutes: 20,
        averageSpeedKmh: 20.0,
      );
    });
  }

  /// Tối ưu hành trình — Nearest Neighbor + persist to DB
  Future<void> _optimizeRoute() async {
    if (_mappableStops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 2 điểm có tọa độ để tối ưu')),
      );
      return;
    }

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tối ưu hành trình?'),
        content: Text(
          'Sắp xếp lại ${_mappableStops.length} điểm dừng theo khoảng cách ngắn nhất '
          '(thuật toán Nearest Neighbor).\n\n'
          'Thứ tự mới sẽ được lưu vào hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.route, size: 18),
            label: const Text('Tối ưu'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isOptimizing = true);

    try {
      final startPoint = _currentLocation ?? LatLng(10.8, 106.7);

      // Calculate distance before optimization
      final waypointsBefore = _mappableStops
          .map((s) => LatLng(s.latitude!, s.longitude!))
          .toList();
      final distanceBefore = RouteOptimizer.calculateTotalDistance(
        startPoint: startPoint,
        waypoints: waypointsBefore,
      );

      // Optimize using generic RouteOptimizer
      final optimized = RouteOptimizer.optimizeRoute<JourneyPlanStop>(
        startPoint: startPoint,
        stops: _mappableStops,
        getLocation: (stop) => LatLng(stop.latitude!, stop.longitude!),
      );

      // Merge: keep stops without coords at end, replace mappable stops with optimized order
      final noCoordStops = _stops
          .where((s) => s.latitude == null || s.longitude == null)
          .toList();
      final reordered = [...optimized, ...noCoordStops];

      // Save to database
      final service = SalesRouteService();
      final stopIds = reordered.map((s) => s.id).toList();
      await service.reorderJourneyStops(stopIds);

      // Calculate distance after optimization
      final waypointsAfter = optimized
          .map((s) => LatLng(s.latitude!, s.longitude!))
          .toList();
      final distanceAfter = RouteOptimizer.calculateTotalDistance(
        startPoint: startPoint,
        waypoints: waypointsAfter,
      );

      if (!mounted) return;

      setState(() {
        _stops = reordered;
        _isRouteOptimized = true;
        _isOptimizing = false;
        _selectedStopIndex = null;
      });

      _calculateRouteEstimate();
      _fitAllMarkers();

      final saved = distanceBefore - distanceAfter;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã tối ưu hành trình! '
            '${distanceAfter.toStringAsFixed(1)} km '
            '(tiết kiệm ${saved.toStringAsFixed(1)} km)',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isOptimizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tối ưu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fitAllMarkers() {
    final points = <LatLng>[];
    if (_currentLocation != null) points.add(_currentLocation!);
    for (final stop in _mappableStops) {
      points.add(LatLng(stop.latitude!, stop.longitude!));
    }
    if (points.length < 2) return;
    
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
        ),
      );
    } catch (e) {
      debugPrint('SalesJourneyMapPage._fitAllMarkers error: $e');
    }
  }

  List<SaboMapMarker> _buildMarkers() {
    final markers = <SaboMapMarker>[];
    
    for (int i = 0; i < _stops.length; i++) {
      final stop = _stops[i];
      if (stop.latitude == null || stop.longitude == null) continue;

      final isCompleted = stop.status == 'completed';
      final isArrived = stop.status == 'arrived';
      final isSkipped = stop.status == 'skipped';
      final isSelected = _selectedStopIndex == i;

      Color bgColor;
      if (isCompleted) {
        bgColor = Colors.green;
      } else if (isArrived) {
        bgColor = Colors.blue;
      } else if (isSkipped) {
        bgColor = Colors.orange;
      } else {
        bgColor = Colors.grey.shade600;
      }

      markers.add(SaboMapMarker(
        id: stop.id,
        position: LatLng(stop.latitude!, stop.longitude!),
        color: bgColor,
        width: isSelected ? 56 : 44,
        height: isSelected ? 64 : 52,
        data: i,
        child: GestureDetector(
          onTap: () => setState(() => _selectedStopIndex = i),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSelected ? 36 : 28,
                height: isSelected ? 36 : 28,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withOpacity(0.4),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.surface, size: 16)
                      : isSkipped
                          ? Icon(Icons.close, color: Theme.of(context).colorScheme.surface, size: 14)
                          : Text(
                              '${stop.stopOrder}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                ),
              ),
              if (isSelected && stop.customerName != null)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    stop.customerName!,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ));
    }
    
    return markers;
  }

  List<SaboMapPolyline> _buildPolylines() {
    final polylines = <SaboMapPolyline>[];
    final routePoints = <LatLng>[];

    // Current location as start
    if (_currentLocation != null) {
      routePoints.add(_currentLocation!);
    }

    // Add all stop locations in order
    for (final stop in _stops) {
      if (stop.latitude != null && stop.longitude != null) {
        routePoints.add(LatLng(stop.latitude!, stop.longitude!));
      }
    }

    if (routePoints.length >= 2) {
      // Completed path (green solid)
      final completedPoints = <LatLng>[];
      if (_currentLocation != null) completedPoints.add(_currentLocation!);
      for (int i = 0; i < _stops.length; i++) {
        if (_stops[i].latitude == null || _stops[i].longitude == null) continue;
        if (_stops[i].status == 'completed') {
          completedPoints.add(LatLng(_stops[i].latitude!, _stops[i].longitude!));
        } else {
          break;
        }
      }
      if (completedPoints.length >= 2) {
        polylines.add(SaboMapPolyline(
          id: 'completed',
          points: completedPoints,
          color: Colors.green,
          strokeWidth: 4,
        ));
      }

      // Remaining path (blue dotted)
      final remainingPoints = <LatLng>[];
      if (_currentLocation != null) {
        remainingPoints.add(_currentLocation!);
      }
      for (int i = _currentStopIndex; i < _stops.length; i++) {
        if (_stops[i].latitude != null && _stops[i].longitude != null) {
          remainingPoints.add(LatLng(_stops[i].latitude!, _stops[i].longitude!));
        }
      }
      if (remainingPoints.length >= 2) {
        polylines.add(SaboMapPolyline(
          id: 'remaining',
          points: remainingPoints,
          color: Colors.blue.shade400,
          strokeWidth: 3,
          isDotted: true,
        ));
      }
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final noCoords = _stops.where((s) => s.latitude == null || s.longitude == null).length;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          SaboMapWidget(
            mapController: _mapController,
            initialCenter: _currentLocation,
            initialZoom: 13,
            currentLocation: _currentLocation,
            showCurrentLocation: true,
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            onMarkerTap: (marker) {
              if (marker.data is int) {
                setState(() => _selectedStopIndex = marker.data as int);
              }
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(noCoords),
          ),

          // Route estimate
          if (_routeEstimate != null)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 60,
              child: _buildRouteEstimateChip(),
            ),

          // Control buttons
          Positioned(
            right: 16,
            bottom: _selectedStopIndex != null ? 180 : 100,
            child: _buildControlButtons(),
          ),

          // Bottom stop list
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomStopList(),
          ),

          // Selected stop detail card
          if (_selectedStopIndex != null && _selectedStopIndex! < _stops.length)
            Positioned(
              bottom: 100,
              left: 16,
              right: 70,
              child: _buildSelectedStopCard(_stops[_selectedStopIndex!]),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(int noCoords) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
        left: 8,
        right: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
            Theme.of(context).colorScheme.surface.withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            elevation: 2,
            child: InkWell(
              onTap: () => Navigator.pop(context, _isRouteOptimized),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back, size: 22),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.map, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Bản đồ hành trình',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_mappableStops.length}/${_stops.length} điểm',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteEstimateChip() {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              _routeEstimate!.distanceFormatted,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blue.shade700,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 14,
              color: Colors.grey.shade300,
            ),
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              _routeEstimate!.totalTimeFormatted,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        // Optimize route button
        if (_mappableStops.length >= 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _isOptimizing
                ? Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Material(
                    color: _isRouteOptimized ? Colors.green.shade50 : Colors.amber.shade50,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      onTap: _optimizeRoute,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          _isRouteOptimized ? Icons.check_circle : Icons.alt_route,
                          size: 22,
                          color: _isRouteOptimized ? Colors.green : Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ),
          ),
        _buildMapButton(
          Icons.my_location,
          'Vị trí của tôi',
          () {
            if (_currentLocation != null) {
              _mapController.move(_currentLocation!, 16);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildMapButton(
          Icons.fit_screen,
          'Xem tất cả',
          _fitAllMarkers,
        ),
        const SizedBox(height: 8),
        _buildMapButton(
          Icons.navigate_next,
          'Điểm tiếp theo',
          () {
            if (_currentStopIndex < _stops.length) {
              final stop = _stops[_currentStopIndex];
              if (stop.latitude != null && stop.longitude != null) {
                _mapController.move(LatLng(stop.latitude!, stop.longitude!), 16);
                setState(() => _selectedStopIndex = _currentStopIndex);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildMapButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: Colors.blue.shade700),
        ),
      ),
    );
  }

  Widget _buildBottomStopList() {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.0),
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
            Theme.of(context).colorScheme.surface,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 24),
        itemCount: _stops.length,
        itemBuilder: (context, index) {
          final stop = _stops[index];
          final isSelected = _selectedStopIndex == index;
          final hasCoords = stop.latitude != null && stop.longitude != null;

          Color statusColor;
          switch (stop.status) {
            case 'completed':
              statusColor = Colors.green;
              break;
            case 'arrived':
              statusColor = Colors.blue;
              break;
            case 'skipped':
              statusColor = Colors.orange;
              break;
            default:
              statusColor = Colors.grey;
          }

          return GestureDetector(
            onTap: () {
              setState(() => _selectedStopIndex = index);
              if (hasCoords) {
                _mapController.move(LatLng(stop.latitude!, stop.longitude!), 16);
              }
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? statusColor.withOpacity(0.15) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? statusColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 6)]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: stop.status == 'completed'
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.surface, size: 14)
                          : Text(
                              '${stop.stopOrder}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stop.customerName ?? 'KH',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!hasCoords)
                          Text(
                            'Chưa có toạ độ',
                            style: TextStyle(fontSize: 9, color: Colors.red.shade400),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedStopCard(JourneyPlanStop stop) {
    final hasCoords = stop.latitude != null && stop.longitude != null;

    Color statusColor;
    String statusText;
    switch (stop.status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
      case 'arrived':
        statusColor = Colors.blue;
        statusText = 'Đang ghé';
        break;
      case 'skipped':
        statusColor = Colors.orange;
        statusText = 'Bỏ qua';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Chờ ghé';
    }

    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${stop.stopOrder}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stop.customerName ?? 'Khách hàng',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => setState(() => _selectedStopIndex = null),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ],
            ),
            if (stop.customerAddress != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      stop.customerAddress!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (stop.customerPhone != null && stop.customerPhone!.isNotEmpty)
                  _buildActionChip(
                    Icons.phone,
                    'Gọi',
                    Colors.teal,
                    () async {
                      final uri = Uri.parse('tel:${stop.customerPhone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                const SizedBox(width: 8),
                if (hasCoords)
                  _buildActionChip(
                    Icons.directions,
                    'Chỉ đường',
                    Colors.indigo,
                    () async {
                      final destination = '${stop.latitude},${stop.longitude}';
                      final uri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
