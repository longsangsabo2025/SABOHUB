import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Route Optimization Utilities
/// Các thuật toán tối ưu hóa tuyến đường
class RouteOptimizer {
  /// Tối ưu hóa thứ tự các điểm dừng theo khoảng cách ngắn nhất
  /// Sử dụng thuật toán Nearest Neighbor (greedy)
  static List<T> optimizeRoute<T>({
    required LatLng startPoint,
    required List<T> stops,
    required LatLng Function(T) getLocation,
    LatLng? endPoint,
  }) {
    if (stops.isEmpty) return [];
    if (stops.length == 1) return stops;

    final remaining = List<T>.from(stops);
    final optimized = <T>[];
    var currentPoint = startPoint;

    while (remaining.isNotEmpty) {
      // Tìm điểm gần nhất
      T? nearest;
      double minDistance = double.infinity;

      for (final stop in remaining) {
        final distance = _calculateDistance(currentPoint, getLocation(stop));
        if (distance < minDistance) {
          minDistance = distance;
          nearest = stop;
        }
      }

      if (nearest != null) {
        optimized.add(nearest);
        currentPoint = getLocation(nearest);
        remaining.remove(nearest);
      }
    }

    return optimized;
  }

  /// Tối ưu hóa với ràng buộc thời gian (time windows)
  static List<T> optimizeWithTimeWindows<T>({
    required LatLng startPoint,
    required List<T> stops,
    required LatLng Function(T) getLocation,
    required DateTime? Function(T) getTimeWindowStart,
    required DateTime? Function(T) getTimeWindowEnd,
    required DateTime startTime,
    double averageSpeedKmh = 30.0,
  }) {
    if (stops.isEmpty) return [];

    // Sắp xếp theo time window trước
    final sortedByTime = List<T>.from(stops);
    sortedByTime.sort((a, b) {
      final timeA = getTimeWindowStart(a);
      final timeB = getTimeWindowStart(b);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeA.compareTo(timeB);
    });

    // Phân nhóm theo time slots
    final urgentStops = <T>[]; // Có deadline gần
    final flexibleStops = <T>[]; // Không có deadline hoặc deadline xa

    final now = startTime;
    for (final stop in sortedByTime) {
      final windowEnd = getTimeWindowEnd(stop);
      if (windowEnd != null && windowEnd.difference(now).inHours <= 2) {
        urgentStops.add(stop);
      } else {
        flexibleStops.add(stop);
      }
    }

    // Tối ưu từng nhóm
    final optimizedUrgent = optimizeRoute(
      startPoint: startPoint,
      stops: urgentStops,
      getLocation: getLocation,
    );

    final lastUrgentPoint = optimizedUrgent.isNotEmpty
        ? getLocation(optimizedUrgent.last)
        : startPoint;

    final optimizedFlexible = optimizeRoute(
      startPoint: lastUrgentPoint,
      stops: flexibleStops,
      getLocation: getLocation,
    );

    return [...optimizedUrgent, ...optimizedFlexible];
  }

  /// Tính tổng khoảng cách của route (km)
  static double calculateTotalDistance({
    required LatLng startPoint,
    required List<LatLng> waypoints,
    LatLng? endPoint,
  }) {
    if (waypoints.isEmpty) return 0;

    double total = _calculateDistance(startPoint, waypoints.first);

    for (int i = 0; i < waypoints.length - 1; i++) {
      total += _calculateDistance(waypoints[i], waypoints[i + 1]);
    }

    if (endPoint != null) {
      total += _calculateDistance(waypoints.last, endPoint);
    }

    return total / 1000; // Convert to km
  }

  /// Ước tính thời gian di chuyển (phút)
  static int estimateTravelTime({
    required double distanceKm,
    double averageSpeedKmh = 25.0, // Tốc độ trong nội thành
  }) {
    return (distanceKm / averageSpeedKmh * 60).ceil();
  }

  /// Ước tính thời gian hoàn thành route
  static RouteEstimate estimateRoute({
    required LatLng startPoint,
    required List<LatLng> waypoints,
    int stopDurationMinutes = 15, // Thời gian tại mỗi điểm
    double averageSpeedKmh = 25.0,
  }) {
    final distance = calculateTotalDistance(
      startPoint: startPoint,
      waypoints: waypoints,
    );

    final travelTime = estimateTravelTime(
      distanceKm: distance,
      averageSpeedKmh: averageSpeedKmh,
    );

    final totalStopTime = waypoints.length * stopDurationMinutes;
    final totalTime = travelTime + totalStopTime;

    return RouteEstimate(
      totalDistanceKm: distance,
      travelTimeMinutes: travelTime,
      stopTimeMinutes: totalStopTime,
      totalTimeMinutes: totalTime,
      stopsCount: waypoints.length,
    );
  }

  /// Tính khoảng cách giữa 2 điểm (meters) - Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Kiểm tra xem điểm có nằm trong polygon không
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    int intersections = 0;
    for (int i = 0; i < polygon.length; i++) {
      final j = (i + 1) % polygon.length;
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      if (((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }

  /// Tạo bounding box từ danh sách điểm
  static LatLngBounds getBoundingBox(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        const LatLng(0, 0),
        const LatLng(0, 0),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  /// Tính center point của danh sách điểm
  static LatLng getCenterPoint(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);

    double sumLat = 0;
    double sumLng = 0;

    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(
      sumLat / points.length,
      sumLng / points.length,
    );
  }
}

/// Kết quả ước tính route
class RouteEstimate {
  final double totalDistanceKm;
  final int travelTimeMinutes;
  final int stopTimeMinutes;
  final int totalTimeMinutes;
  final int stopsCount;

  const RouteEstimate({
    required this.totalDistanceKm,
    required this.travelTimeMinutes,
    required this.stopTimeMinutes,
    required this.totalTimeMinutes,
    required this.stopsCount,
  });

  String get distanceFormatted => '${totalDistanceKm.toStringAsFixed(1)} km';
  
  String get travelTimeFormatted {
    if (travelTimeMinutes < 60) {
      return '$travelTimeMinutes phút';
    } else {
      final hours = travelTimeMinutes ~/ 60;
      final mins = travelTimeMinutes % 60;
      return '$hours giờ ${mins > 0 ? '$mins phút' : ''}';
    }
  }

  String get totalTimeFormatted {
    if (totalTimeMinutes < 60) {
      return '$totalTimeMinutes phút';
    } else {
      final hours = totalTimeMinutes ~/ 60;
      final mins = totalTimeMinutes % 60;
      return '$hours giờ ${mins > 0 ? '$mins phút' : ''}';
    }
  }

  DateTime estimatedEndTime(DateTime startTime) {
    return startTime.add(Duration(minutes: totalTimeMinutes));
  }
}

/// Geofence Zone Model
class GeofenceZone {
  final String id;
  final String name;
  final LatLng center;
  final double radiusMeters;
  final GeofenceType type;
  final Map<String, dynamic>? metadata;

  const GeofenceZone({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
    this.type = GeofenceType.customer,
    this.metadata,
  });

  bool containsPoint(LatLng point) {
    final distance = RouteOptimizer._calculateDistance(center, point);
    return distance <= radiusMeters;
  }
}

enum GeofenceType {
  customer,
  warehouse,
  office,
  restrictedArea,
}
