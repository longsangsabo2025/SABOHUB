# 🛰️ GPS Development Strategy - SABOHUB

> **Ngày lập**: 21/01/2026  
> **Phiên bản**: 2.0  
> **Cập nhật**: 21/01/2026 - ✅ HOÀN THÀNH TẤT CẢ PHASES  
> **Mục tiêu**: Nâng cấp hệ thống GPS lên công nghệ mới nhất 2025-2026

---

## ✅ TẤT CẢ PHASES ĐÃ HOÀN THÀNH

### Phase 1: Core GPS Upgrade ✅
- [x] Nâng cấp geolocator 13.0.4 → 14.0.2
- [x] Thêm geolocator_android ^5.0.2
- [x] Thêm geolocator_apple ^2.3.10  
- [x] Thêm geocoding ^3.0.0
- [x] Refactor location_service.dart với platform-specific settings
- [x] Refactor gps_tracking_service.dart với AndroidSettings/AppleSettings

### Phase 2: Map Integration ✅
- [x] Thêm flutter_map ^8.2.2 (OpenStreetMap - FREE)
- [x] Thêm latlong2 ^0.9.1
- [x] Thêm flutter_polyline_points ^2.1.0
- [x] Tạo `lib/widgets/map/sabo_map_widget.dart` - Core map widget
- [x] Tạo `lib/widgets/map/destination_map_widget.dart` - Destination preview
- [x] Tạo `lib/widgets/map/route_tracking_map_widget.dart` - Real-time tracking
- [x] Cập nhật `sales_route_navigation_screen.dart` với map thực

### Phase 3: Background Tracking ✅
- [x] Thêm flutter_background_geolocation ^4.17.5
- [x] Tạo `lib/services/background_location_service.dart`
- [x] Cấu hình Android foreground service notification
- [x] Cấu hình iOS background modes
- [x] Riverpod providers cho background tracking

### Phase 4: Geofencing & Route Optimization ✅
- [x] Tạo `lib/utils/route_optimizer.dart`
- [x] Thuật toán Nearest Neighbor cho route optimization
- [x] Time-window based scheduling
- [x] Geofence zones với customer arrival detection
- [x] Route estimate calculation

---

## 📊 Tổng quan công nghệ đã cài đặt

### 1. Geolocator Package
| Version | Status | Notes |
|---------|--------|-------|
| **14.0.2** | ✅ Installed | Flutter Favorite, 6K likes |

### 2. Flutter Map (OpenStreetMap - FREE)
| Version | Status | Notes |
|---------|--------|-------|
| **8.2.2** | ✅ Installed | Vendor-free, FREE |

### 3. Flutter Background Geolocation
| Version | Status | Notes |
|---------|--------|-------|
| **4.18.3** | ✅ Installed | Motion detection AI |

---

## 📁 Files đã tạo/cập nhật

```
lib/
├── services/
│   ├── location_service.dart           # ✅ Refactored v2.0
│   ├── gps_tracking_service.dart       # ✅ Refactored v2.0
│   └── background_location_service.dart # ✅ NEW
├── widgets/
│   └── map/
│       ├── map_widgets.dart            # ✅ NEW (exports)
│       ├── sabo_map_widget.dart        # ✅ NEW
│       ├── destination_map_widget.dart # ✅ NEW
│       └── route_tracking_map_widget.dart # ✅ NEW
├── screens/
│   └── dms/
│       └── sales_route_navigation_screen.dart # ✅ Refactored
└── utils/
    └── route_optimizer.dart            # ✅ NEW
```

---

## 🔧 Cấu hình cần thiết

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SABOHUB cần truy cập vị trí để check-in và điều hướng</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>SABOHUB cần truy cập vị trí liên tục để theo dõi giao hàng</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
</array>
```
**Mục tiêu**: Tích hợp bản đồ hiển thị

**Option A: Google Maps (Recommended cho enterprise)**
```yaml
dependencies:
  google_maps_flutter: ^2.14.0
```
- ✅ Chất lượng cao, đầy đủ tính năng
- ⚠️ Cần API key, có phí nếu vượt quota

**Option B: Flutter Map (FREE - Recommended cho startup)**
```yaml
dependencies:
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
```
- ✅ Miễn phí hoàn toàn
- ✅ Sử dụng OpenStreetMap
- ⚠️ Tính năng ít hơn Google Maps

**Tasks:**
- [ ] Quyết định Google Maps hoặc Flutter Map
- [ ] Tích hợp map widget
- [ ] Hiển thị vị trí người dùng trên bản đồ
- [ ] Hiển thị điểm check-in công ty

### Phase 3: Route & Navigation (Tuần 5-6)
**Mục tiêu**: Điều hướng cho Sales/Delivery

```yaml
dependencies:
  # Directions API
  google_directions_api: ^0.10.0     # Nếu dùng Google
  flutter_polyline_points: ^2.1.0    # Vẽ đường đi
  
  # Hoặc free alternative
  open_route_service: ^1.2.0         # OpenRouteService API
```

**Tasks:**
- [ ] Tích hợp Directions API
- [ ] Vẽ route trên bản đồ
- [ ] Tính thời gian & khoảng cách
- [ ] Turn-by-turn navigation (optional)

### Phase 4: Background Tracking (Tuần 7-8)
**Mục tiêu**: Tracking delivery trong background

```yaml
dependencies:
  flutter_background_geolocation: ^5.0.1  # Premium cho Android release
  # Hoặc
  background_locator_2: ^2.0.6           # Free alternative
```

**Tasks:**
- [ ] Background location service
- [ ] Battery optimization
- [ ] Geofencing cho điểm giao hàng
- [ ] Motion detection AI

---

## 🏗️ Kiến trúc hệ thống GPS mới

```
┌─────────────────────────────────────────────────────────────┐
│                    GPS Module Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Attendance   │  │   Delivery   │  │    Sales     │       │
│  │  Check-in    │  │   Tracking   │  │   Route      │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │                │
│  ┌──────┴─────────────────┴─────────────────┴───────┐       │
│  │              GPS Service Layer (v2.0)             │       │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────┐  │       │
│  │  │ Location    │  │ Tracking    │  │ Map      │  │       │
│  │  │ Service     │  │ Service     │  │ Service  │  │       │
│  │  └─────────────┘  └─────────────┘  └──────────┘  │       │
│  └──────────────────────────────────────────────────┘       │
│                          │                                   │
│  ┌──────────────────────┴───────────────────────────┐       │
│  │              Platform Layer                       │       │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐          │       │
│  │  │ Android │  │  iOS    │  │   Web   │          │       │
│  │  │Settings │  │Settings │  │Settings │          │       │
│  │  └─────────┘  └─────────┘  └─────────┘          │       │
│  └──────────────────────────────────────────────────┘       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Code Migration Guide

### 1. Location Service - BEFORE (v13)
```dart
// ❌ Deprecated
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
  timeLimit: const Duration(seconds: 10),
);
```

### 1. Location Service - AFTER (v14)
```dart
// ✅ New API
final locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 0,
  timeLimit: const Duration(seconds: 10),
);
Position position = await Geolocator.getCurrentPosition(
  locationSettings: locationSettings,
);
```

### 2. Platform Specific Settings
```dart
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';

LocationSettings getLocationSettings() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      intervalDuration: const Duration(seconds: 5),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "SABOHUB đang theo dõi vị trí của bạn",
        notificationTitle: "GPS Tracking Active",
        enableWakeLock: true,
      ),
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.otherNavigation,
      distanceFilter: 10,
      pauseLocationUpdatesAutomatically: true,
      showBackgroundLocationIndicator: true,
    );
  }
  return LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );
}
```

---

## 📦 Package Dependencies - Final

```yaml
# pubspec.yaml - GPS Section (Updated)
dependencies:
  # Core Location (Phase 1)
  geolocator: ^14.0.2
  geolocator_android: ^4.6.2
  geolocator_apple: ^2.3.10
  permission_handler: ^12.0.1
  geocoding: ^3.0.0
  
  # Maps (Phase 2) - Choose ONE
  flutter_map: ^8.2.2           # FREE option
  latlong2: ^0.9.1
  # OR
  # google_maps_flutter: ^2.14.0  # Paid option
  
  # Routes (Phase 3)
  flutter_polyline_points: ^2.1.0
  
  # Background Tracking (Phase 4) - Optional
  # flutter_background_geolocation: ^5.0.1
```

---

## 🔒 Quyền truy cập cần thiết

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Background location (Phase 4) -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SABOHUB cần truy cập vị trí để chấm công và theo dõi giao hàng</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>SABOHUB cần truy cập vị trí liên tục để theo dõi giao hàng</string>

<key>UIBackgroundModes</key>
<array>
  <string>location</string>
</array>
```

---

## 📈 Timeline & Milestones

```
Tuần 1-2: Phase 1 - Core GPS Upgrade
├── Day 1-2: Upgrade dependencies
├── Day 3-4: Refactor LocationService
├── Day 5-7: Refactor GpsTrackingService
└── Day 8-14: Testing & bug fixes

Tuần 3-4: Phase 2 - Maps Integration
├── Day 1-3: Integrate flutter_map
├── Day 4-6: User location on map
├── Day 7-10: Company locations markers
└── Day 11-14: Map UI polish

Tuần 5-6: Phase 3 - Route & Navigation
├── Day 1-3: Directions API integration
├── Day 4-7: Route drawing
├── Day 8-10: Distance & time calculation
└── Day 11-14: Sales route navigation screen

Tuần 7-8: Phase 4 - Background Tracking
├── Day 1-4: Background service setup
├── Day 5-7: Battery optimization
├── Day 8-10: Geofencing
└── Day 11-14: Final testing & optimization
```

---

## 💡 Khuyến nghị

### Cho giai đoạn đầu (Phase 1-2):
1. **Nâng cấp geolocator ngay** - Sửa deprecated warnings
2. **Sử dụng Flutter Map** - Miễn phí, đủ tính năng cho startup
3. **Tập trung check-in GPS** - Tính năng core quan trọng nhất

### Cho giai đoạn sau (Phase 3-4):
1. **Đánh giá nhu cầu thực tế** trước khi thêm navigation
2. **Cân nhắc cost** nếu cần Google Maps API
3. **Background tracking** chỉ cần cho delivery module

---

## ✅ Action Items - Bắt đầu ngay

1. [ ] **Upgrade geolocator** từ 13.0.4 → 14.0.2
2. [ ] **Refactor location_service.dart** với LocationSettings mới
3. [ ] **Refactor gps_tracking_service.dart** với platform settings
4. [ ] **Thêm flutter_map** cho map visualization
5. [ ] **Update AndroidManifest.xml** với permissions mới
6. [ ] **Update Info.plist** với location descriptions

---

*Tài liệu này sẽ được cập nhật theo tiến độ triển khai.*
