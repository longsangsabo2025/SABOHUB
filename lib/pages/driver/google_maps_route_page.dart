import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleMapsRoutePage extends StatefulWidget {
  final List<Map<String, dynamic>> deliveryStops;
  final double? currentLat;
  final double? currentLng;

  const GoogleMapsRoutePage({
    super.key,
    required this.deliveryStops,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<GoogleMapsRoutePage> createState() => _GoogleMapsRoutePageState();
}

class _GoogleMapsRoutePageState extends State<GoogleMapsRoutePage> {
  List<Map<String, dynamic>> _optimizedStops = [];
  double _totalDistance = 0;
  String _googleMapsUrl = '';

  @override
  void initState() {
    super.initState();
    _optimizeAndBuildRoute();
  }

  void _optimizeAndBuildRoute() {
    // Optimize route using Nearest Neighbor
    _optimizedStops = _optimizeRouteNearestNeighbor(
      widget.deliveryStops,
      widget.currentLat ?? 10.8,
      widget.currentLng ?? 106.7,
    );

    // Calculate total distance
    _calculateTotalDistance();

    // Build Google Maps URL
    _buildGoogleMapsUrl();
  }

  // Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  // Nearest Neighbor algorithm
  List<Map<String, dynamic>> _optimizeRouteNearestNeighbor(
    List<Map<String, dynamic>> stops,
    double startLat,
    double startLng,
  ) {
    if (stops.length <= 2) return stops;

    final List<Map<String, dynamic>> optimized = [];
    final List<Map<String, dynamic>> remaining = List.from(stops);

    double currentLat = startLat;
    double currentLng = startLng;

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

  void _calculateTotalDistance() {
    _totalDistance = 0;
    double prevLat = widget.currentLat ?? 10.8;
    double prevLng = widget.currentLng ?? 106.7;

    for (final stop in _optimizedStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = (customer?['lat'] as num?)?.toDouble();
      final lng = (customer?['lng'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        _totalDistance += _calculateDistance(prevLat, prevLng, lat, lng);
        prevLat = lat;
        prevLng = lng;
      }
    }
  }

  void _buildGoogleMapsUrl() {
    // Collect addresses for Google Maps (prefer customer address over coordinates)
    final List<String> waypoints = [];
    for (final stop in _optimizedStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      
      // Use delivery_address or customer address first, fallback to coordinates
      final deliveryAddress = salesOrder?['delivery_address'] as String?;
      final customerAddress = customer?['address'] as String?;
      final lat = customer?['lat'] as num?;
      final lng = customer?['lng'] as num?;
      
      // Prefer text address for better Google Maps display
      if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
        waypoints.add(deliveryAddress);
      } else if (customerAddress != null && customerAddress.isNotEmpty) {
        waypoints.add(customerAddress);
      } else if (lat != null && lng != null) {
        waypoints.add('$lat,$lng');
      }
    }

    if (waypoints.isEmpty) return;

    // Build URL using Google Maps Directions API format
    // This format auto-fills origin, waypoints, and destination
    if (waypoints.length == 1) {
      // Single destination - use simple navigation
      _googleMapsUrl = 'https://www.google.com/maps/dir/?api=1'
          '&destination=${Uri.encodeComponent(waypoints.first)}'
          '&travelmode=driving';
    } else {
      // Multiple waypoints: origin (current location or first stop), waypoints (middle stops), destination (last stop)
      final origin = widget.currentLat != null && widget.currentLng != null
          ? '${widget.currentLat},${widget.currentLng}'
          : waypoints.first;
      
      final destination = waypoints.last;
      
      // Middle waypoints (exclude first if using current location, exclude last always)
      final middleWaypoints = widget.currentLat != null && widget.currentLng != null
          ? waypoints.sublist(0, waypoints.length - 1) // All except last
          : waypoints.sublist(1, waypoints.length - 1); // Exclude first and last
      
      _googleMapsUrl = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${Uri.encodeComponent(origin)}'
          '&destination=${Uri.encodeComponent(destination)}'
          '&travelmode=driving';
      
      if (middleWaypoints.isNotEmpty) {
        // Google Maps supports up to 9 waypoints in URL
        final waypointsStr = middleWaypoints.take(9).join('|');
        _googleMapsUrl += '&waypoints=${Uri.encodeComponent(waypointsStr)}';
      }
    }
  }

  Future<void> _openInGoogleMapsApp() async {
    if (_googleMapsUrl.isEmpty) return;

    final uri = Uri.parse(_googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInBrowser() async {
    if (_googleMapsUrl.isEmpty) return;

    final uri = Uri.parse(_googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuyến đường giao hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Mở trong trình duyệt',
            onPressed: _openInBrowser,
          ),
          IconButton(
            icon: const Icon(Icons.navigation),
            tooltip: 'Mở Google Maps',
            onPressed: _openInGoogleMapsApp,
          ),
        ],
      ),
      body: Column(
        children: [
          // Google Maps Embed (WebView-like for all platforms)
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade200,
              child: _buildMapPreview(),
            ),
          ),

          // Route info panel
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.route, color: Colors.blue.shade700, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_optimizedStops.length} điểm giao hàng',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.straighten, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${_totalDistance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '✓ Đã tối ưu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Stop list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _optimizedStops.length,
                      itemBuilder: (context, index) {
                        final stop = _optimizedStops[index];
                        final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
                        final customer = salesOrder?['customers'] as Map<String, dynamic>?;
                        final name = customer?['name'] ?? 'Khách hàng ${index + 1}';
                        final address = customer?['address'] ?? '';
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Number badge
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.green :
                                         index == _optimizedStops.length - 1 ? Colors.red :
                                         Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (address.isNotEmpty)
                                      Text(
                                        address,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              // Label
                              if (index == 0)
                                _buildLabel('Bắt đầu', Colors.green)
                              else if (index == _optimizedStops.length - 1)
                                _buildLabel('Kết thúc', Colors.red),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Navigation button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openInGoogleMapsApp,
                      icon: const Icon(Icons.navigation, size: 20),
                      label: const Text('Bắt đầu điều hướng với Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
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
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    // Show a static map preview with markers
    if (_optimizedStops.isEmpty) {
      return const Center(
        child: Text('Không có điểm giao hàng'),
      );
    }

    // Build static map URL (works everywhere without SDK)
    final List<String> markers = [];
    for (int i = 0; i < _optimizedStops.length; i++) {
      final stop = _optimizedStops[i];
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as num?;
      final lng = customer?['lng'] as num?;
      if (lat != null && lng != null) {
        final color = i == 0 ? 'green' : (i == _optimizedStops.length - 1 ? 'red' : 'orange');
        markers.add('color:$color|label:${i + 1}|$lat,$lng');
      }
    }

    // Use Google Static Maps API for preview
    // Note: This requires the same API key
    // Calculate center point for map but not using Static Maps API currently
    // ignore: unused_local_variable
    final center = _optimizedStops.isNotEmpty 
        ? () {
            final stop = _optimizedStops[0];
            final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
            final customer = salesOrder?['customers'] as Map<String, dynamic>?;
            final lat = customer?['lat'] ?? 10.8;
            final lng = customer?['lng'] ?? 106.7;
            return '$lat,$lng';
          }()
        : '10.8,106.7';

    return Stack(
      children: [
        // Placeholder map with route visualization
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade100,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 64,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tuyến đường đã được tối ưu',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút bên dưới để xem trên Google Maps',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Quick action button
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: ElevatedButton.icon(
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Xem bản đồ trong trình duyệt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
