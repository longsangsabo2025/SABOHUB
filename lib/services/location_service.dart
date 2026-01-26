import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geolocator/geolocator.dart' show Position, LocationAccuracy, Geolocator, LocationAccuracyStatus;
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service quản lý location và kiểm tra vị trí check-in
/// Updated: v2.0 - Sử dụng Geolocator 14.x với Platform-specific Settings
class LocationService {
  static const double _allowedRadiusMeters = 100.0; // Bán kính mặc định 100m
  final _supabase = Supabase.instance.client;

  // Vị trí công ty mặc định (nếu chưa cấu hình trong database)
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

  /// Lấy LocationSettings phù hợp với từng platform
  /// Tối ưu cho từng hệ điều hành
  LocationSettings _getLocationSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 0,
    Duration? timeLimit,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
        // Foreground notification cho background tracking
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "SABOHUB đang xác định vị trí của bạn",
          notificationTitle: "GPS Active",
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
               defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.otherNavigation,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: true,
      );
    }
    
    // Default settings cho các platform khác (web, linux, windows)
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }

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

  /// Kiểm tra loại quyền location đã cấp (precise/approximate)
  Future<LocationAccuracyStatus> getLocationAccuracyStatus() async {
    return await Geolocator.getLocationAccuracy();
  }

  /// Yêu cầu quyền location chính xác (Android 12+)
  Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) async {
    return await Geolocator.requestTemporaryFullAccuracy(
      purposeKey: purposeKey,
    );
  }

  /// Lấy vị trí hiện tại của người dùng - Cập nhật với API mới
  Future<Position> getCurrentLocation() async {
    bool hasPermission = await checkAndRequestLocationPermission();
    if (!hasPermission) {
      throw LocationServiceException('Không có quyền truy cập vị trí');
    }

    try {
      // Sử dụng platform-specific settings
      final locationSettings = _getLocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: const Duration(seconds: 15),
      );
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      return position;
    } catch (e) {
      throw LocationServiceException('Không thể lấy vị trí hiện tại: $e');
    }
  }

  /// Lấy vị trí đã lưu trước đó (nhanh hơn getCurrentLocation)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Stream vị trí liên tục - Cập nhật với API mới
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    final locationSettings = _getLocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
    
    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }

  /// Kiểm tra xem vị trí hiện tại có trong phạm vi cho phép không
  Future<LocationValidationResult> validateCheckInLocation({
    String? companyId,
    String? branchId,
  }) async {
    try {
      Position currentLocation = await getCurrentLocation();
      
      // Lấy thông tin vị trí công ty từ database
      double allowedRadius = _allowedRadiusMeters;
      Position companyLocation;
      
      if (companyId != null) {
        try {
          final companyData = await _supabase
              .from('companies')
              .select('check_in_latitude, check_in_longitude, check_in_radius')
              .eq('id', companyId)
              .maybeSingle();
          
          if (companyData != null) {
            final lat = companyData['check_in_latitude'] as double?;
            final lng = companyData['check_in_longitude'] as double?;
            final radius = companyData['check_in_radius'] as double?;
            
            if (lat != null && lng != null) {
              companyLocation = Position(
                latitude: lat,
                longitude: lng,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );
            
              if (radius != null) {
                allowedRadius = radius;
              }
            } else {
              // Nếu chưa cấu hình, dùng mặc định
              companyLocation = _getCompanyLocation(companyId);
            }
          } else {
            // Nếu không tìm thấy company data, dùng mặc định
            companyLocation = _getCompanyLocation(companyId);
          }
        } catch (e) {
          // Nếu có lỗi, dùng vị trí mặc định
          companyLocation = _getCompanyLocation(companyId);
        }
      } else {
        companyLocation = _getCompanyLocation('default');
      }

      double distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        companyLocation.latitude,
        companyLocation.longitude,
      );

      bool isValid = distance <= allowedRadius;

      return LocationValidationResult(
        isValid: isValid,
        currentLocation: currentLocation,
        companyLocation: companyLocation,
        distance: distance,
        allowedRadius: allowedRadius,
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

  /// Tính khoảng cách giữa 2 điểm (mét)
  double calculateDistance(Position pos1, Position pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }

  /// Tính góc hướng giữa 2 điểm (độ)
  double calculateBearing(Position from, Position to) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Kiểm tra xem GPS có độ chính xác tốt không
  bool hasGoodAccuracy(Position position) {
    return position.accuracy <= 20.0; // Độ chính xác <= 20m
  }

  /// Kiểm tra xem GPS có độ chính xác cao không
  bool hasHighAccuracy(Position position) {
    return position.accuracy <= 10.0; // Độ chính xác <= 10m
  }

  /// Mở cài đặt location của thiết bị
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Mở cài đặt app để cấp quyền
  Future<bool> openAppPermissionSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Lắng nghe thay đổi trạng thái GPS service
  Stream<geo.ServiceStatus> getServiceStatusStream() {
    return Geolocator.getServiceStatusStream();
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

  /// Kiểm tra xem có thể check-in không
  bool get canCheckIn => isValid && accuracy <= 50;

  /// Thông báo chi tiết cho người dùng
  String get detailedMessage {
    final buffer = StringBuffer();
    buffer.writeln(statusMessage);
    buffer.writeln(accuracyMessage);
    if (!canCheckIn) {
      if (!isValid) {
        buffer.writeln('💡 Di chuyển gần hơn đến vị trí công ty');
      }
      if (accuracy > 50) {
        buffer.writeln('💡 Đợi GPS ổn định hơn hoặc ra ngoài trời');
      }
    }
    return buffer.toString().trim();
  }
}

/// Exception cho location service
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
