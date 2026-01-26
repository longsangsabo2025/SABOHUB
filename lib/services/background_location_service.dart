import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background Location Service v2.0
/// Sử dụng Geolocator 14.x với foreground service cho Android
/// - Battery-efficient tracking với distance filter
/// - Foreground notification trên Android
/// - Geofence tự implement bằng distance calculation
class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final _supabase = Supabase.instance.client;
  
  bool _isTracking = false;
  String? _currentDeliveryId;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  
  // Geofences storage
  final Map<String, _Geofence> _geofences = {};
  
  // Stream controllers
  final _locationController = StreamController<Position>.broadcast();
  final _trackingStateController = StreamController<bool>.broadcast();
  final _geofenceEventController = StreamController<GeofenceEvent>.broadcast();
  
  Stream<Position> get locationStream => _locationController.stream;
  Stream<bool> get trackingStateStream => _trackingStateController.stream;
  Stream<GeofenceEvent> get geofenceEventStream => _geofenceEventController.stream;
  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastPosition;

  /// Lấy LocationSettings phù hợp với platform
  LocationSettings _getLocationSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 20,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "SABOHUB đang theo dõi vị trí giao hàng",
          notificationTitle: "Delivery Tracking Active",
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
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }

  /// Khởi tạo service - kiểm tra permission
  Future<bool> initialize() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission permanently denied');
        return false;
      }

      debugPrint('✅ BackgroundLocationService initialized');
      return true;
    } catch (e) {
      debugPrint('❌ BackgroundLocationService init error: $e');
      return false;
    }
  }

  /// Bắt đầu tracking cho delivery
  Future<bool> startTracking({required String deliveryId}) async {
    if (_isTracking) await stopTracking();

    try {
      final initialized = await initialize();
      if (!initialized) return false;

      _currentDeliveryId = deliveryId;
      
      // Get initial position
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: _getLocationSettings(distanceFilter: 0),
      );
      _lastPosition = initialPosition;
      _locationController.add(initialPosition);
      await _uploadLocation(initialPosition);
      _checkGeofences(initialPosition);

      // Start continuous tracking
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _getLocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          debugPrint('❌ Tracking error: $error');
        },
      );

      _isTracking = true;
      _trackingStateController.add(_isTracking);
      
      debugPrint('🛰️ Background tracking started for delivery: $deliveryId');
      return true;
    } catch (e) {
      debugPrint('❌ Start tracking error: $e');
      return false;
    }
  }

  /// Dừng tracking
  Future<void> stopTracking() async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      
      _isTracking = false;
      _currentDeliveryId = null;
      _trackingStateController.add(_isTracking);
      
      debugPrint('⏹️ Background tracking stopped');
    } catch (e) {
      debugPrint('❌ Stop tracking error: $e');
    }
  }

  /// Tạm dừng tracking
  Future<void> pauseTracking() async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _isTracking = false;
      _trackingStateController.add(_isTracking);
    } catch (e) {
      debugPrint('❌ Pause tracking error: $e');
    }
  }

  /// Tiếp tục tracking
  Future<void> resumeTracking() async {
    if (_currentDeliveryId == null) return;
    await startTracking(deliveryId: _currentDeliveryId!);
  }

  /// Lấy vị trí hiện tại
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _getLocationSettings(distanceFilter: 0),
      );
    } catch (e) {
      debugPrint('❌ Get current position error: $e');
      return null;
    }
  }

  /// Thêm geofence cho customer location
  Future<void> addCustomerGeofence({
    required String customerId,
    required double latitude,
    required double longitude,
    double radius = 100,
  }) async {
    _geofences['customer_$customerId'] = _Geofence(
      identifier: 'customer_$customerId',
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      customerId: customerId,
    );
    debugPrint('📍 Geofence added for customer: $customerId');
    
    // Check immediately if we have a position
    if (_lastPosition != null) {
      _checkGeofences(_lastPosition!);
    }
  }

  /// Xóa geofence
  Future<void> removeCustomerGeofence(String customerId) async {
    _geofences.remove('customer_$customerId');
    debugPrint('📍 Geofence removed for customer: $customerId');
  }

  /// Xóa tất cả geofences
  Future<void> removeAllGeofences() async {
    _geofences.clear();
    debugPrint('📍 All geofences removed');
  }

  // === Private Methods ===

  void _onPositionUpdate(Position position) {
    debugPrint('📍 Location: ${position.latitude}, ${position.longitude}');
    _lastPosition = position;
    _locationController.add(position);
    _uploadLocation(position);
    _checkGeofences(position);
  }

  void _checkGeofences(Position position) {
    for (final geofence in _geofences.values) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.latitude,
        geofence.longitude,
      );
      
      final wasInside = geofence.isInside;
      final isInside = distance <= geofence.radius;
      
      if (isInside != wasInside) {
        geofence.isInside = isInside;
        
        final action = isInside ? GeofenceAction.enter : GeofenceAction.exit;
        final event = GeofenceEvent(
          identifier: geofence.identifier,
          action: action,
          customerId: geofence.customerId,
          distance: distance,
        );
        
        _geofenceEventController.add(event);
        
        if (action == GeofenceAction.enter) {
          debugPrint('🎯 Arrived at customer: ${geofence.customerId}');
        } else {
          debugPrint('👋 Left customer: ${geofence.customerId}');
        }
      }
    }
  }

  Future<void> _uploadLocation(Position position) async {
    if (_currentDeliveryId == null) return;

    try {
      await _supabase.from('delivery_tracking_points').insert({
        'delivery_id': _currentDeliveryId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'altitude': position.altitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Upload location error: $e');
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
    _trackingStateController.close();
    _geofenceEventController.close();
  }
}

// === Geofence Models ===

class _Geofence {
  final String identifier;
  final double latitude;
  final double longitude;
  final double radius;
  final String? customerId;
  bool isInside = false;

  _Geofence({
    required this.identifier,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.customerId,
  });
}

enum GeofenceAction { enter, exit, dwell }

class GeofenceEvent {
  final String identifier;
  final GeofenceAction action;
  final String? customerId;
  final double distance;

  GeofenceEvent({
    required this.identifier,
    required this.action,
    this.customerId,
    required this.distance,
  });
}

// === RIVERPOD PROVIDERS ===

final backgroundLocationServiceProvider = Provider((ref) {
  return BackgroundLocationService();
});

final backgroundTrackingStateProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(backgroundLocationServiceProvider);
  return service.trackingStateStream;
});

final backgroundLocationStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(backgroundLocationServiceProvider);
  return service.locationStream;
});

final geofenceEventProvider = StreamProvider<GeofenceEvent>((ref) {
  final service = ref.watch(backgroundLocationServiceProvider);
  return service.geofenceEventStream;
});
