import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service quản lý location và kiểm tra vị trí check-in
class LocationService {
  static const double _allowedRadiusMeters = 100.0; // Bán kính cho phép 100m

  // Vị trí công ty mặc định (có thể config từ database)
  static final Map<String, Position> _companyLocations = {
    'default': Position(
      latitude: 10.762622, // TP.HCM center
      longitude: 106.660172,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    ),
  };

  /// Kiểm tra và yêu cầu quyền truy cập location
  Future<bool> checkAndRequestLocationPermission() async {
    // Kiểm tra quyền trong app
    PermissionStatus permission = await Permission.location.status;

    if (permission.isDenied) {
      permission = await Permission.location.request();
    }

    if (permission.isPermanentlyDenied) {
      // Người dùng từ chối vĩnh viễn, cần mở cài đặt
      await openAppSettings();
      return false;
    }

    // Kiểm tra GPS service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
          'GPS chưa được bật. Vui lòng bật GPS để tiếp tục.');
    }

    return permission.isGranted;
  }

  /// Lấy vị trí hiện tại của người dùng
  Future<Position> getCurrentLocation() async {
    bool hasPermission = await checkAndRequestLocationPermission();
    if (!hasPermission) {
      throw LocationServiceException('Không có quyền truy cập vị trí');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      throw LocationServiceException('Không thể lấy vị trí hiện tại: $e');
    }
  }

  /// Kiểm tra xem vị trí hiện tại có trong phạm vi cho phép không
  Future<LocationValidationResult> validateCheckInLocation({
    String? companyId,
    String? branchId,
  }) async {
    try {
      Position currentLocation = await getCurrentLocation();
      Position companyLocation = _getCompanyLocation(companyId ?? 'default');

      double distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        companyLocation.latitude,
        companyLocation.longitude,
      );

      bool isValid = distance <= _allowedRadiusMeters;

      return LocationValidationResult(
        isValid: isValid,
        currentLocation: currentLocation,
        companyLocation: companyLocation,
        distance: distance,
        allowedRadius: _allowedRadiusMeters,
        accuracy: currentLocation.accuracy,
      );
    } catch (e) {
      throw LocationServiceException('Lỗi kiểm tra vị trí: $e');
    }
  }

  /// Lấy thông tin vị trí của công ty
  Position _getCompanyLocation(String companyId) {
    return _companyLocations[companyId] ?? _companyLocations['default']!;
  }

  /// Format thông tin location thành chuỗi để lưu database
  String formatLocationForStorage(Position position) {
    return '${position.latitude},${position.longitude}';
  }

  /// Parse location từ chuỗi đã lưu
  Position? parseLocationFromStorage(String? locationString) {
    if (locationString == null || locationString.isEmpty) return null;

    try {
      List<String> parts = locationString.split(',');
      if (parts.length >= 2) {
        return Position(
          latitude: double.parse(parts[0]),
          longitude: double.parse(parts[1]),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      // Invalid format
    }
    return null;
  }

  /// Tính khoảng cách giữa 2 điểm
  double calculateDistance(Position pos1, Position pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }

  /// Kiểm tra xem GPS có độ chính xác tốt không
  bool hasGoodAccuracy(Position position) {
    return position.accuracy <= 20.0; // Độ chính xác <= 20m
  }
}

/// Kết quả kiểm tra vị trí check-in
class LocationValidationResult {
  final bool isValid;
  final Position currentLocation;
  final Position companyLocation;
  final double distance;
  final double allowedRadius;
  final double accuracy;

  LocationValidationResult({
    required this.isValid,
    required this.currentLocation,
    required this.companyLocation,
    required this.distance,
    required this.allowedRadius,
    required this.accuracy,
  });

  String get statusMessage {
    if (isValid) {
      return 'Vị trí hợp lệ (cách ${distance.toInt()}m)';
    } else {
      return 'Vị trí không hợp lệ (cách ${distance.toInt()}m, cho phép ${allowedRadius.toInt()}m)';
    }
  }

  String get accuracyMessage {
    if (accuracy <= 10) {
      return 'Độ chính xác cao (±${accuracy.toInt()}m)';
    } else if (accuracy <= 20) {
      return 'Độ chính xác tốt (±${accuracy.toInt()}m)';
    } else {
      return 'Độ chính xác thấp (±${accuracy.toInt()}m)';
    }
  }
}

/// Exception cho location service
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
