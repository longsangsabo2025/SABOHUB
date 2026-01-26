import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget bản đồ chính của SABOHUB
/// Sử dụng OpenStreetMap (FREE) thông qua flutter_map
class SaboMapWidget extends StatefulWidget {
  /// Vị trí trung tâm ban đầu
  final LatLng? initialCenter;
  
  /// Zoom level ban đầu (1-18)
  final double initialZoom;
  
  /// Danh sách markers hiển thị
  final List<SaboMapMarker> markers;
  
  /// Danh sách polylines (đường đi)
  final List<SaboMapPolyline> polylines;
  
  /// Callback khi tap vào map
  final void Function(LatLng position)? onTap;
  
  /// Callback khi tap vào marker
  final void Function(SaboMapMarker marker)? onMarkerTap;
  
  /// Hiển thị vị trí hiện tại
  final bool showCurrentLocation;
  
  /// Vị trí hiện tại (nếu có)
  final LatLng? currentLocation;
  
  /// Controller để điều khiển map từ bên ngoài
  final MapController? mapController;

  const SaboMapWidget({
    super.key,
    this.initialCenter,
    this.initialZoom = 15.0,
    this.markers = const [],
    this.polylines = const [],
    this.onTap,
    this.onMarkerTap,
    this.showCurrentLocation = true,
    this.currentLocation,
    this.mapController,
  });

  @override
  State<SaboMapWidget> createState() => _SaboMapWidgetState();
}

class _SaboMapWidgetState extends State<SaboMapWidget> {
  late MapController _mapController;
  
  // Mặc định: TP.HCM center
  static const LatLng _defaultCenter = LatLng(10.762622, 106.660172);

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialCenter ?? 
                   widget.currentLocation ?? 
                   _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: widget.initialZoom,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: widget.onTap != null 
            ? (tapPosition, point) => widget.onTap!(point)
            : null,
      ),
      children: [
        // Tile Layer - OpenStreetMap (FREE)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sabohub.flutter_sabohub',
          maxZoom: 19,
        ),
        
        // Polylines (routes)
        if (widget.polylines.isNotEmpty)
          PolylineLayer(
            polylines: widget.polylines.map((p) => Polyline(
              points: p.points,
              color: p.color,
              strokeWidth: p.strokeWidth,
              pattern: p.isDotted 
                  ? const StrokePattern.dotted() 
                  : const StrokePattern.solid(),
            )).toList(),
          ),
        
        // Markers
        MarkerLayer(
          markers: [
            // Current location marker
            if (widget.showCurrentLocation && widget.currentLocation != null)
              Marker(
                point: widget.currentLocation!,
                width: 40,
                height: 40,
                child: const _CurrentLocationMarker(),
              ),
            
            // Custom markers
            ...widget.markers.map((m) => Marker(
              point: m.position,
              width: m.width,
              height: m.height,
              child: GestureDetector(
                onTap: () => widget.onMarkerTap?.call(m),
                child: m.child ?? _DefaultMarker(
                  color: m.color,
                  icon: m.icon,
                  label: m.label,
                ),
              ),
            )),
          ],
        ),
      ],
    );
  }

  /// Di chuyển camera đến vị trí
  void moveToLocation(LatLng location, {double? zoom}) {
    _mapController.move(location, zoom ?? widget.initialZoom);
  }

  /// Fit tất cả markers vào view
  void fitAllMarkers() {
    if (widget.markers.isEmpty) return;
    
    final bounds = LatLngBounds.fromPoints(
      widget.markers.map((m) => m.position).toList(),
    );
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }
}

/// Marker hiển thị vị trí hiện tại
class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marker mặc định
class _DefaultMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String? label;

  const _DefaultMarker({
    this.color = Colors.red,
    this.icon = Icons.location_on,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        if (label != null)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              label!,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

/// Model cho marker
class SaboMapMarker {
  final String id;
  final LatLng position;
  final Color color;
  final IconData icon;
  final String? label;
  final Widget? child;
  final double width;
  final double height;
  final dynamic data; // Custom data attached to marker

  const SaboMapMarker({
    required this.id,
    required this.position,
    this.color = Colors.red,
    this.icon = Icons.location_on,
    this.label,
    this.child,
    this.width = 40,
    this.height = 50,
    this.data,
  });
}

/// Model cho polyline
class SaboMapPolyline {
  final String id;
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final bool isDotted;

  const SaboMapPolyline({
    required this.id,
    required this.points,
    this.color = Colors.blue,
    this.strokeWidth = 4.0,
    this.isDotted = false,
  });
}
