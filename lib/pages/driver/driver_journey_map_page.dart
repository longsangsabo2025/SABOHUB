import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_logger.dart';
import 'driver_providers.dart';
import 'google_maps_route_page.dart';

/// Driver Journey Map Page - Bản đồ hành trình với GPS tracking và Route Optimization
class DriverJourneyMapPage extends ConsumerStatefulWidget {
  const DriverJourneyMapPage({super.key});

  @override
  ConsumerState<DriverJourneyMapPage> createState() => _DriverJourneyMapPageState();
}

class _DriverJourneyMapPageState extends ConsumerState<DriverJourneyMapPage> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  bool _isLocating = false;
  bool _isEditingLocation = false;
  bool _isUpdatingLocation = false;
  bool _mapReady = false;
  bool _isRouteOptimized = false;
  LatLng? _currentLocation;
  LatLng? _pickedLocation;
  String? _pickedAddress;
  List<Map<String, dynamic>> _deliveryStops = [];
  int _selectedStopIndex = -1;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  
  // GPS Tracking
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  
  // Default location (Ho Chi Minh City center)
  static const LatLng _defaultLocation = LatLng(10.8231, 106.6297);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadDeliveryStops();
    _startGPSTracking();
  }

  // ============================================================================
  // GPS TRACKING
  // ============================================================================

  Future<void> _startGPSTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật dịch vụ vị trí (GPS)'),
              action: SnackBarAction(
                label: 'Mở cài đặt',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cần quyền truy cập vị trí để theo dõi GPS'),
              action: SnackBarAction(
                label: 'Mở cài đặt',
                onPressed: () => Geolocator.openAppSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() => _isTracking = true);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
          }
        },
        onError: (error) {
          AppLogger.error('GPS stream error', error);
          setState(() => _isTracking = false);
        },
      );
    } catch (e) {
      AppLogger.error('Failed to start GPS tracking', e);
      setState(() => _isTracking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể bật GPS: ${e.toString()}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _stopGPSTracking() {
    _positionStream?.cancel();
    setState(() => _isTracking = false);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = _defaultLocation;
          _isLocating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dịch vụ vị trí (GPS) chưa được bật'),
              action: SnackBarAction(
                label: 'Bật GPS',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
        }
        if (_mapReady && mounted) {
          _mapController.move(_defaultLocation, 12);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = _defaultLocation;
            _isLocating = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền truy cập vị trí bị từ chối'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = _defaultLocation;
          _isLocating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật quyền truy cập vị trí trong cài đặt'),
              action: SnackBarAction(
                label: 'Mở cài đặt',
                onPressed: () => Geolocator.openAppSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocating = false;
      });

      if (_mapReady && mounted) {
        _mapController.move(_currentLocation!, 14);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Đã xác định vị trí: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get location', e);
      setState(() {
        _currentLocation = _defaultLocation;
        _isLocating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xác định vị trí: ${e.toString().length > 50 ? e.toString().substring(0, 50) : e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // DATA LOADING
  // ============================================================================

  Future<void> _loadDeliveryStops() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final driverId = authState.user?.id;

      if (companyId == null || driverId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      final deliveries = await supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, delivery_address,
              delivery_status, payment_method, payment_status,
              customers(id, name, phone, address, lat, lng)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .inFilter('status', ['planned', 'loading', 'in_progress'])
          .order('created_at', ascending: true)
          .limit(20);

      setState(() {
        _deliveryStops = List<Map<String, dynamic>>.from(deliveries);
        _isLoading = false;
        _isRouteOptimized = false;
      });

      if (_deliveryStops.isNotEmpty) {
        _fitMapToMarkers();
      }
    } catch (e) {
      AppLogger.error('Failed to load delivery stops', e);
      setState(() => _isLoading = false);
    }
  }

  void _fitMapToMarkers() {
    if (!_mapReady) return;
    if (_deliveryStops.isEmpty && _currentLocation == null) return;

    final points = <LatLng>[];
    
    if (_currentLocation != null) {
      points.add(_currentLocation!);
    }

    for (final stop in _deliveryStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as double?;
      final lng = customer?['lng'] as double?;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15);
    } else {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  // ============================================================================
  // GEOCODING
  // ============================================================================

  Future<String?> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street?.isNotEmpty == true) parts.add(place.street!);
        if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
        return parts.join(', ');
      }
    } catch (e) {
      AppLogger.error('Reverse geocoding failed', e);
    }
    return null;
  }

  // ============================================================================
  // MAP INTERACTIONS
  // ============================================================================

  void _onMapTap(TapPosition tapPosition, LatLng point) async {
    if (!_isEditingLocation) {
      setState(() => _selectedStopIndex = -1);
      return;
    }

    setState(() {
      _pickedLocation = point;
      _pickedAddress = 'Đang tìm địa chỉ...';
    });

    final address = await _getAddressFromCoordinates(point.latitude, point.longitude);
    setState(() {
      _pickedAddress = address ?? 'Không tìm thấy địa chỉ';
    });
  }

  Future<void> _updateCustomerLocation() async {
    if (_selectedStopIndex < 0 || _pickedLocation == null) return;

    final stop = _deliveryStops[_selectedStopIndex];
    final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
    final customer = salesOrder?['customers'] as Map<String, dynamic>?;
    final customerId = customer?['id'];

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin khách hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUpdatingLocation = true);

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('customers').update({
        'lat': _pickedLocation!.latitude,
        'lng': _pickedLocation!.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', customerId);

      await _loadDeliveryStops();

      setState(() {
        _isEditingLocation = false;
        _pickedLocation = null;
        _pickedAddress = null;
        _isUpdatingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã cập nhật vị trí khách hàng!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to update customer location', e);
      setState(() => _isUpdatingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // ROUTE OPTIMIZATION
  // ============================================================================

  Future<void> _optimizeAndReorderStops() async {
    if (_deliveryStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có điểm giao hàng để tối ưu')),
      );
      return;
    }

    int stopsWithCoords = 0;
    for (final stop in _deliveryStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as num?;
      final lng = customer?['lng'] as num?;
      if (lat != null && lng != null) {
        stopsWithCoords++;
      }
    }

    if (stopsWithCoords < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 2 điểm có tọa độ để tối ưu')),
      );
      return;
    }

    final optimizedStops = _optimizeRouteNearestNeighbor(
      _deliveryStops,
      _currentLocation?.latitude,
      _currentLocation?.longitude,
    );

    // Save route_order to database for each delivery
    await _saveRouteOrderToDatabase(optimizedStops);

    setState(() {
      _deliveryStops = optimizedStops;
      _isRouteOptimized = true;
      _selectedStopIndex = -1;
    });

    double totalDistance = 0;
    double? prevLat = _currentLocation?.latitude;
    double? prevLng = _currentLocation?.longitude;
    
    for (final stop in optimizedStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = (customer?['lat'] as num?)?.toDouble();
      final lng = (customer?['lng'] as num?)?.toDouble();
      
      if (lat != null && lng != null && prevLat != null && prevLng != null) {
        totalDistance += _calculateDistance(prevLat, prevLng, lat, lng);
        prevLat = lat;
        prevLng = lng;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tối ưu tuyến đường! Tổng: ${totalDistance.toStringAsFixed(1)} km'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _fitMapToMarkers();
  }

  /// Save route_order to database for each delivery
  /// This allows the deliveries list to be sorted by optimized route order
  Future<void> _saveRouteOrderToDatabase(List<Map<String, dynamic>> optimizedStops) async {
    try {
      final supabase = Supabase.instance.client;
      
      for (int i = 0; i < optimizedStops.length; i++) {
        final stop = optimizedStops[i];
        final deliveryId = stop['id'] as String?;
        
        if (deliveryId != null) {
          await supabase
              .from('deliveries')
              .update({'route_order': i + 1})
              .eq('id', deliveryId);
        }
      }
      
      AppLogger.info('Route order saved to database for ${optimizedStops.length} deliveries');
      
      // Notify other pages (like DriverDeliveriesPage) to refresh their data
      notifyRouteOptimized(ref);
    } catch (e) {
      AppLogger.error('Failed to save route order to database', e);
      // Don't show error to user - route optimization still works locally
    }
  }

  List<Map<String, dynamic>> _optimizeRouteNearestNeighbor(
    List<Map<String, dynamic>> stops,
    double? startLat,
    double? startLng,
  ) {
    if (stops.length <= 2) return stops;

    final List<Map<String, dynamic>> optimized = [];
    final List<Map<String, dynamic>> remaining = List.from(stops);

    double currentLat = startLat ?? 10.8;
    double currentLng = startLng ?? 106.7;

    while (remaining.isNotEmpty) {
      int nearestIndex = 0;
      double nearestDistance = double.infinity;

      for (int i = 0; i < remaining.length; i++) {
        final stop = remaining[i];
        final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
        final customer = salesOrder?['customers'] as Map<String, dynamic>?;
        final lat = (customer?['lat'] as num?)?.toDouble();
        final lng = (customer?['lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          final distance = _calculateDistance(currentLat, currentLng, lat, lng);
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestIndex = i;
          }
        }
      }

      final nearest = remaining.removeAt(nearestIndex);
      optimized.add(nearest);

      final salesOrder = nearest['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      currentLat = (customer?['lat'] as num?)?.toDouble() ?? currentLat;
      currentLng = (customer?['lng'] as num?)?.toDouble() ?? currentLng;
    }

    return optimized;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  // ============================================================================
  // GOOGLE MAPS INTEGRATION
  // ============================================================================

  Future<void> _openGoogleMapsSearch(String? currentAddress) async {
    String query = currentAddress ?? '';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openGoogleMapsNavigation(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFullRouteInGoogleMaps() async {
    if (_deliveryStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có điểm giao hàng')),
      );
      return;
    }

    final optimizedStops = _optimizeRouteNearestNeighbor(
      _deliveryStops,
      _currentLocation?.latitude,
      _currentLocation?.longitude,
    );

    final List<String> waypoints = [];
    for (final stop in optimizedStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      
      final deliveryAddress = salesOrder?['delivery_address'] as String?;
      final customerAddress = customer?['address'] as String?;
      final lat = customer?['lat'] as num?;
      final lng = customer?['lng'] as num?;
      
      if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
        waypoints.add(deliveryAddress);
      } else if (customerAddress != null && customerAddress.isNotEmpty) {
        waypoints.add(customerAddress);
      } else if (lat != null && lng != null) {
        waypoints.add('$lat,$lng');
      }
    }

    if (waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Các điểm giao hàng chưa có tọa độ')),
      );
      return;
    }

    String url;
    if (waypoints.length == 1) {
      url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=${waypoints.first}'
          '&travelmode=driving';
    } else {
      final origin = _currentLocation != null
          ? '${_currentLocation!.latitude},${_currentLocation!.longitude}'
          : waypoints.first;
      
      final destination = waypoints.last;
      
      final middleWaypoints = _currentLocation != null
          ? waypoints.sublist(0, waypoints.length - 1)
          : waypoints.sublist(1, waypoints.length - 1);
      
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${Uri.encodeComponent(origin)}'
          '&destination=${Uri.encodeComponent(destination)}'
          '&travelmode=driving';
      
      if (middleWaypoints.isNotEmpty) {
        final waypointsStr = middleWaypoints.take(9).join('|');
        url += '&waypoints=${Uri.encodeComponent(waypointsStr)}';
      }
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openGoogleMapsRoutePage() {
    if (_deliveryStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có điểm giao hàng')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoogleMapsRoutePage(
          deliveryStops: _deliveryStops,
          currentLat: _currentLocation?.latitude,
          currentLng: _currentLocation?.longitude,
        ),
      ),
    );
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ============================================================================
  // BUILD UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _defaultLocation,
              initialZoom: 13,
              onTap: _onMapTap,
              onMapReady: () {
                setState(() => _mapReady = true);
                if (_deliveryStops.isNotEmpty || _currentLocation != null) {
                  _fitMapToMarkers();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sabohub.app',
              ),

              // Route polyline
              if (_deliveryStops.isNotEmpty && _currentLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _buildRoutePoints(),
                      color: Colors.blue.shade600,
                      strokeWidth: 4,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // Header
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isEditingLocation ? Colors.orange.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: _isEditingLocation 
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isEditingLocation 
                          ? Colors.orange.shade100 
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditingLocation ? Icons.edit_location : Icons.map,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isEditingLocation 
                              ? 'Chạm vào map để chọn vị trí' 
                              : 'Hành trình giao hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isEditingLocation ? Colors.orange.shade800 : Colors.black87,
                          ),
                        ),
                        Text(
                          _isEditingLocation 
                              ? 'Sau đó nhấn "Lưu vị trí"'
                              : '${_deliveryStops.length} điểm giao • GPS ${_isTracking ? "ON" : "OFF"}',
                          style: TextStyle(
                            color: _isEditingLocation 
                                ? Colors.orange.shade600 
                                : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditingLocation)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingLocation = false;
                          _pickedLocation = null;
                          _pickedAddress = null;
                        });
                      },
                      child: const Text('Hủy'),
                    )
                  else
                    IconButton(
                      onPressed: _initializeMap,
                      icon: _isLoading || _isLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
          ),

          // Picked location info card
          if (_isEditingLocation && _pickedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              top: 100,
              child: _buildPickedLocationCard(),
            ),

          // Action buttons
          Positioned(
            right: 16,
            bottom: _selectedStopIndex >= 0 ? 280 : 120,
            child: _buildActionButtons(),
          ),

          // Bottom delivery stops list
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStopsList(),
          ),

          // Selected stop detail card
          if (_selectedStopIndex >= 0 && _selectedStopIndex < _deliveryStops.length && !_isEditingLocation)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: _buildSelectedStopCard(_deliveryStops[_selectedStopIndex]),
            ),
        ],
      ),
    );
  }

  Widget _buildPickedLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text(
                'Vị trí đã chọn:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _pickedAddress ?? 'Đang tìm địa chỉ...',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            '${_pickedLocation!.latitude.toStringAsFixed(6)}, ${_pickedLocation!.longitude.toStringAsFixed(6)}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdatingLocation ? null : _updateCustomerLocation,
              icon: _isUpdatingLocation 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isUpdatingLocation ? 'Đang lưu...' : 'Lưu vị trí này'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Optimize route button
        FloatingActionButton.small(
          heroTag: 'optimize_route',
          onPressed: _optimizeAndReorderStops,
          backgroundColor: _isRouteOptimized ? Colors.green : Colors.white,
          tooltip: 'Tối ưu tuyến đường',
          child: Icon(
            Icons.route,
            color: _isRouteOptimized ? Colors.white : Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 8),
        // Open full route in Google Maps (embedded view)
        FloatingActionButton.small(
          heroTag: 'google_maps_route',
          onPressed: () => _openGoogleMapsRoutePage(),
          backgroundColor: Colors.white,
          tooltip: 'Xem tuyến đường Google Maps',
          child: Icon(Icons.map_outlined, color: Colors.red.shade700),
        ),
        const SizedBox(height: 8),
        // Open in external Google Maps app
        FloatingActionButton.small(
          heroTag: 'google_maps_external',
          onPressed: _openFullRouteInGoogleMaps,
          backgroundColor: Colors.white,
          tooltip: 'Mở Google Maps App',
          child: Icon(Icons.navigation_outlined, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 8),
        // GPS tracking toggle
        FloatingActionButton.small(
          heroTag: 'gps_toggle',
          onPressed: _isTracking ? _stopGPSTracking : _startGPSTracking,
          backgroundColor: _isTracking ? Colors.green : Colors.white,
          child: Icon(
            _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: _isTracking ? Colors.white : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        // Fit all markers
        FloatingActionButton.small(
          heroTag: 'fit_bounds',
          onPressed: _fitMapToMarkers,
          backgroundColor: Colors.white,
          child: Icon(Icons.zoom_out_map, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        // My location
        FloatingActionButton(
          heroTag: 'my_location',
          onPressed: _getCurrentLocation,
          backgroundColor: Colors.white,
          child: _isLocating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.my_location, color: Colors.blue.shade700),
        ),
      ],
    );
  }

  List<LatLng> _buildRoutePoints() {
    final points = <LatLng>[];
    
    if (_currentLocation != null) {
      points.add(_currentLocation!);
    }

    for (final stop in _deliveryStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as double?;
      final lng = customer?['lng'] as double?;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }

    return points;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Picked location marker (when editing)
    if (_isEditingLocation && _pickedLocation != null) {
      markers.add(
        Marker(
          point: _pickedLocation!,
          width: 60,
          height: 60,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 60,
          ),
        ),
      );
    }

    // Current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    // Delivery stop markers
    for (int i = 0; i < _deliveryStops.length; i++) {
      final stop = _deliveryStops[i];
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as double?;
      final lng = customer?['lng'] as double?;

      if (lat != null && lng != null) {
        final deliveryStatus = stop['status'] as String? ?? 'planned';
        final isSelected = _selectedStopIndex == i;
        
        Color markerColor;
        switch (deliveryStatus) {
          case 'in_progress':
            markerColor = Colors.blue;
            break;
          case 'loading':
            markerColor = Colors.purple;
            break;
          case 'planned':
            markerColor = Colors.orange;
            break;
          case 'completed':
            markerColor = Colors.green;
            break;
          default:
            markerColor = Colors.orange;
        }

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: isSelected ? 60 : 45,
            height: isSelected ? 60 : 45,
            child: GestureDetector(
              onTap: () => setState(() => _selectedStopIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 4 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withOpacity(0.4),
                      blurRadius: isSelected ? 12 : 6,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSelected ? 18 : 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildStopsList() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveryStops.isEmpty
              ? Center(
                  child: Text(
                    'Không có điểm giao hàng',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 8, right: 16),
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_deliveryStops.length} điểm giao',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _deliveryStops.length,
                        itemBuilder: (context, index) {
                          final stop = _deliveryStops[index];
                          final isSelected = _selectedStopIndex == index;
                          return _buildStopChip(stop, index, isSelected);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStopChip(Map<String, dynamic> stop, int index, bool isSelected) {
    final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
    final customer = salesOrder?['customers'] as Map<String, dynamic>?;
    final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'KH ${index + 1}';
    final deliveryStatus = stop['status'] as String? ?? 'planned';
    final hasLocation = customer?['lat'] != null && customer?['lng'] != null;
    
    Color statusColor;
    switch (deliveryStatus) {
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'loading':
        statusColor = Colors.purple;
        break;
      case 'planned':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedStopIndex = index);
        
        final lat = customer?['lat'] as double?;
        final lng = customer?['lng'] as double?;
        if (lat != null && lng != null) {
          _mapController.move(LatLng(lat, lng), 16);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? statusColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? statusColor : (hasLocation ? Colors.grey.shade300 : Colors.red.shade300),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : statusColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: hasLocation
                    ? Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : const Icon(Icons.location_off, color: Colors.white, size: 14),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  customerName.length > 15 ? '${customerName.substring(0, 15)}...' : customerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  hasLocation ? _getStatusText(deliveryStatus) : '⚠️ Chưa có tọa độ',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected 
                        ? Colors.white.withOpacity(0.8) 
                        : (hasLocation ? Colors.grey.shade600 : Colors.red.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'delivering':
      case 'in_progress':
        return 'Đang giao';
      case 'awaiting_pickup':
      case 'planned':
        return 'Chờ giao';
      case 'loading':
        return 'Đang lấy hàng';
      case 'completed':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Widget _buildSelectedStopCard(Map<String, dynamic> stop) {
    final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
    final customer = salesOrder?['customers'] as Map<String, dynamic>?;
    final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = salesOrder?['delivery_address'] ?? customer?['address'] ?? 'Chưa có địa chỉ';
    final customerPhone = customer?['phone'];
    final total = (salesOrder?['total'] as num?)?.toDouble() ?? 
                  (stop['total_amount'] as num?)?.toDouble() ?? 0;
    final orderNumber = salesOrder?['order_number']?.toString() ?? 
                        stop['delivery_number']?.toString() ?? 
                        stop['id'].toString().substring(0, 8).toUpperCase();
    final hasLocation = customer?['lat'] != null && customer?['lng'] != null;
    final lat = customer?['lat'] as double?;
    final lng = customer?['lng'] as double?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$orderNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!hasLocation)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Thiếu tọa độ',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedStopIndex = -1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Customer info
          Text(
            customerName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _openGoogleMapsSearch(customerAddress),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customerAddress,
                    style: TextStyle(
                      color: Colors.blue.shade600, 
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.open_in_new, size: 12, color: Colors.blue.shade400),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              if (customerPhone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(customerPhone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Gọi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (customerPhone != null) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasLocation 
                      ? () => _openGoogleMapsNavigation(lat!, lng!)
                      : () => _openGoogleMapsSearch(customerAddress),
                  icon: Icon(hasLocation ? Icons.directions : Icons.search, size: 16),
                  label: Text(hasLocation ? 'Chỉ đường' : 'Tìm trên Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Edit location button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditingLocation = true;
                  _pickedLocation = null;
                  _pickedAddress = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.touch_app, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Chạm vào bản đồ để chọn vị trí mới'),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.edit_location_alt, size: 16),
              label: Text(hasLocation ? 'Sửa vị trí trên map' : 'Thêm vị trí trên map'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.orange.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
