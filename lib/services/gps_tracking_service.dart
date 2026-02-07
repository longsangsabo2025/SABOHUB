// GPS Tracking Service for Deliveries
// Handles real-time location tracking for delivery drivers
// Updated: v2.0 - Geolocator 14.x với Platform-specific Settings

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../business_types/distribution/services/odori_service.dart';
import '../business_types/distribution/models/odori_models.dart';

/// GPS Position Data
class GpsPosition {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  const GpsPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  factory GpsPosition.fromPosition(Position position) {
    return GpsPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Tracking State
enum TrackingState {
  idle,
  starting,
  tracking,
  paused,
  error,
}

/// GPS Tracking Service
class GpsTrackingService {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _uploadTimer;
  
  String? _currentDeliveryId;
  List<GpsPosition> _pendingPositions = [];
  
  TrackingState _state = TrackingState.idle;
  TrackingState get state => _state;
  
  GpsPosition? _lastPosition;
  GpsPosition? get lastPosition => _lastPosition;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Callbacks
  Function(GpsPosition position)? onPositionUpdate;
  Function(TrackingState state)? onStateChange;
  Function(String error)? onError;

  /// Lấy LocationSettings phù hợp với từng platform
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
        // Background tracking notification
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Đang theo dõi vị trí giao hàng",
          notificationTitle: "SABOHUB Delivery Tracking",
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
        activityType: ActivityType.automotiveNavigation, // Tối ưu cho delivery
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: false, // Luôn tracking
        showBackgroundLocationIndicator: true,
      );
    }
    
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }

  /// Check if location permission is granted
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<GpsPosition?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        _setError('Không có quyền truy cập vị trí');
        return null;
      }

      // Sử dụng platform-specific settings
      final locationSettings = _getLocationSettings(distanceFilter: 0);
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      final gpsPosition = GpsPosition.fromPosition(position);
      _lastPosition = gpsPosition;
      return gpsPosition;
    } catch (e) {
      _setError('Lỗi lấy vị trí: $e');
      return null;
    }
  }

  /// Start tracking for a delivery
  Future<bool> startTracking(String deliveryId) async {
    if (_state == TrackingState.tracking) {
      await stopTracking();
    }

    _setState(TrackingState.starting);
    _currentDeliveryId = deliveryId;
    _pendingPositions = [];

    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        _setError('Không có quyền truy cập vị trí');
        _setState(TrackingState.error);
        return false;
      }

      // Get initial position
      final initialPosition = await getCurrentPosition();
      if (initialPosition == null) {
        _setState(TrackingState.error);
        return false;
      }

      // Update delivery start location
      await odoriService.startDelivery(
        deliveryId,
        initialPosition.latitude,
        initialPosition.longitude,
      );

      // Start continuous tracking với platform-specific settings
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _getLocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20, // Update every 20 meters
        ),
      ).listen(
        _onPositionUpdate,
        onError: (error) => _setError('Lỗi tracking: $error'),
      );

      // Start upload timer (upload every 30 seconds)
      _uploadTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _uploadPendingPositions(),
      );

      _setState(TrackingState.tracking);
      return true;
    } catch (e) {
      _setError('Lỗi khởi động tracking: $e');
      _setState(TrackingState.error);
      return false;
    }
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    
    _uploadTimer?.cancel();
    _uploadTimer = null;

    // Upload any remaining positions
    await _uploadPendingPositions();

    _currentDeliveryId = null;
    _pendingPositions = [];
    _setState(TrackingState.idle);
  }

  /// Pause tracking
  void pauseTracking() {
    _positionSubscription?.pause();
    _setState(TrackingState.paused);
  }

  /// Resume tracking
  void resumeTracking() {
    _positionSubscription?.resume();
    _setState(TrackingState.tracking);
  }

  /// Handle position update
  void _onPositionUpdate(Position position) {
    final gpsPosition = GpsPosition.fromPosition(position);
    _lastPosition = gpsPosition;
    _pendingPositions.add(gpsPosition);
    
    onPositionUpdate?.call(gpsPosition);
  }

  /// Upload pending positions to server
  Future<void> _uploadPendingPositions() async {
    if (_pendingPositions.isEmpty || _currentDeliveryId == null) return;

    final positionsToUpload = List<GpsPosition>.from(_pendingPositions);
    _pendingPositions.clear();

    try {
      // Upload the latest position
      final latest = positionsToUpload.last;
      await odoriService.updateDeliveryLocation(
        _currentDeliveryId!,
        latest.latitude,
        latest.longitude,
      );
    } catch (e) {
      // Re-add positions if upload failed
      _pendingPositions.insertAll(0, positionsToUpload);
      _setError('Lỗi upload vị trí: $e');
    }
  }

  /// Complete delivery at current location
  Future<OdoriDelivery?> completeDelivery({String? signatureUrl}) async {
    if (_currentDeliveryId == null) return null;

    try {
      final position = await getCurrentPosition();
      
      final delivery = await odoriService.completeDelivery(
        _currentDeliveryId!,
        latitude: position?.latitude,
        longitude: position?.longitude,
        signatureUrl: signatureUrl,
      );

      await stopTracking();
      return delivery;
    } catch (e) {
      _setError('Lỗi hoàn thành giao hàng: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculate distance to destination
  double? distanceToDestination(double destLat, double destLng) {
    if (_lastPosition == null) return null;
    return calculateDistance(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      destLat,
      destLng,
    );
  }

  void _setState(TrackingState state) {
    _state = state;
    _errorMessage = null;
    onStateChange?.call(state);
  }

  void _setError(String message) {
    _errorMessage = message;
    onError?.call(message);
  }

  void dispose() {
    stopTracking();
  }
}

// Singleton instance
final gpsTrackingService = GpsTrackingService();

// ==================== RIVERPOD PROVIDERS ====================

/// GPS Tracking Service Provider
final gpsTrackingServiceProvider = Provider((ref) => gpsTrackingService);

/// Tracking State Provider
final trackingStateProvider = NotifierProvider<TrackingStateNotifier, TrackingStateData>(
  TrackingStateNotifier.new,
);

class TrackingStateData {
  final TrackingState state;
  final GpsPosition? lastPosition;
  final String? deliveryId;
  final String? error;

  const TrackingStateData({
    this.state = TrackingState.idle,
    this.lastPosition,
    this.deliveryId,
    this.error,
  });

  TrackingStateData copyWith({
    TrackingState? state,
    GpsPosition? lastPosition,
    String? deliveryId,
    String? error,
  }) {
    return TrackingStateData(
      state: state ?? this.state,
      lastPosition: lastPosition ?? this.lastPosition,
      deliveryId: deliveryId ?? this.deliveryId,
      error: error,
    );
  }
}

class TrackingStateNotifier extends Notifier<TrackingStateData> {
  late final GpsTrackingService _service;

  @override
  TrackingStateData build() {
    _service = ref.watch(gpsTrackingServiceProvider);
    _service.onStateChange = (newState) {
      state = state.copyWith(state: newState);
    };
    _service.onPositionUpdate = (position) {
      state = state.copyWith(lastPosition: position);
    };
    _service.onError = (error) {
      state = state.copyWith(error: error);
    };
    return const TrackingStateData();
  }

  Future<bool> startTracking(String deliveryId) async {
    state = state.copyWith(deliveryId: deliveryId);
    return await _service.startTracking(deliveryId);
  }

  Future<void> stopTracking() async {
    await _service.stopTracking();
    state = state.copyWith(deliveryId: null);
  }

  void pauseTracking() => _service.pauseTracking();
  void resumeTracking() => _service.resumeTracking();

  Future<OdoriDelivery?> completeDelivery({String? signatureUrl}) async {
    return await _service.completeDelivery(signatureUrl: signatureUrl);
  }
}

/// Current Position Provider
final currentPositionProvider = FutureProvider<GpsPosition?>((ref) async {
  return await gpsTrackingService.getCurrentPosition();
});

/// Distance to Customer Provider
final distanceToCustomerProvider = Provider.family<double?, OdoriCustomer>((ref, customer) {
  final trackingState = ref.watch(trackingStateProvider);
  final position = trackingState.lastPosition;
  
  if (position == null || customer.latitude == null || customer.longitude == null) {
    return null;
  }
  
  return gpsTrackingService.calculateDistance(
    position.latitude,
    position.longitude,
    customer.latitude!,
    customer.longitude!,
  );
});
