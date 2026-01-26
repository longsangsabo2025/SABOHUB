# SABOHUB Developer Onboarding Guide

## 🚀 Chào mừng đến với SABOHUB!

Guide này sẽ giúp bạn nhanh chóng làm quen với codebase SABOHUB.

## 📋 Prerequisites

- Flutter SDK 3.29+
- Dart 3.0+
- VS Code với Flutter extension
- Git

## 🏁 Quick Start

### 1. Clone & Setup

```bash
git clone <repository-url>
cd sabohub-app/SABOHUB
flutter pub get
```

### 2. Environment Setup

Tạo file `.env` trong root directory:

```env
SUPABASE_URL=https://dqddxowyikefqcdiioyh.supabase.co
SUPABASE_ANON_KEY=<your-key>
```

### 3. Run App

```bash
flutter run
```

## 📁 Cấu trúc Project

### Quan trọng nhất:

```
lib/
├── providers/
│   └── cached_providers.dart  ⭐ Đọc file này đầu tiên!
├── layouts/                    # Role-based UI
├── pages/                      # Screen pages
├── services/                   # Business logic
└── widgets/                    # Reusable components
```

## 🎯 Concepts Chính

### 1. Role-Based Architecture

SABOHUB có nhiều role: CEO, Manager, Driver, Warehouse, Sales, etc.

Mỗi role có layout riêng:
```dart
// lib/layouts/
manager_main_layout.dart
driver_main_layout.dart
warehouse_main_layout.dart
// ...
```

### 2. Cached Providers (Riverpod)

Tất cả data providers đều có caching:

```dart
// Sử dụng provider
final data = ref.watch(cachedDriverDeliveriesProvider);

// Refresh data
refreshAllDataByRole(ref);
```

### 3. Realtime Updates

```dart
// Enable realtime listener
ref.watch(driverDeliveryListenerProvider);

// Data auto-refreshes khi có changes
```

## 🔧 Common Tasks

### Thêm một Screen mới

1. Tạo file trong `lib/pages/{role}/`
2. Tạo ConsumerWidget (hoặc ConsumerStatefulWidget)
3. Thêm vào layout tương ứng

```dart
class MyNewPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(cachedMyDataProvider);
    
    return Scaffold(
      body: data.when(
        data: (items) => MyList(items: items),
        loading: () => SkeletonDashboard(),
        error: (e, _) => ErrorDisplay(error: e),
      ),
    );
  }
}
```

### Thêm một Provider mới

1. Thêm vào `lib/providers/cached_providers.dart`:

```dart
final cachedMyDataProvider = FutureProvider.autoDispose<List<MyData>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated) return [];
  
  final cacheKey = 'my_data_${authState.user!.id}';
  final cached = memoryCache.get<List<MyData>>(cacheKey);
  if (cached != null) return cached;
  
  // Fetch from API
  final result = await fetchData();
  memoryCache.set(cacheKey, result);
  return result;
});
```

2. Thêm refresh function:

```dart
void refreshMyData(WidgetRef ref) {
  ref.invalidate(cachedMyDataProvider);
}
```

### Sử dụng Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    refreshMyData(ref);
    await Future.delayed(Duration(milliseconds: 300));
  },
  child: YourContent(),
)
```

### Hiển thị Loading/Error States

```dart
// Skeleton loading
const SkeletonDashboard()
const SkeletonOrderList()

// Error display
ErrorDisplay(
  error: exception,
  onRetry: () => refreshMyData(ref),
)

// Empty state
EmptyStateDisplay.noData()
EmptyStateDisplay.noDeliveries()
```

## 📐 Coding Conventions

### File Naming
- snake_case cho files: `my_widget.dart`
- PascalCase cho classes: `MyWidget`

### Widget Structure
```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch providers
    final data = ref.watch(myProvider);
    
    // 2. Return widget
    return Scaffold(...);
  }
}
```

### Provider Usage
- Luôn dùng `ref.watch()` trong build method
- Dùng `ref.read()` trong callbacks
- Dùng `ref.invalidate()` để refresh

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widgets/state_displays_test.dart

# Run with coverage
flutter test --coverage
```

## 🐛 Debugging Tips

### 1. Check Provider State
```dart
print('Provider state: ${ref.read(myProvider)}');
```

### 2. Check Cache
```dart
final memoryCache = ref.read(memoryCacheProvider);
print('Cache keys: ${memoryCache.keys}');
```

### 3. Flutter Analyze
```bash
flutter analyze --no-fatal-infos
```

## 📚 Tài liệu tham khảo

- [ARCHITECTURE.md](lib/docs/ARCHITECTURE.md) - Kiến trúc tổng quan
- [CACHED_PROVIDERS_README.md](lib/docs/CACHED_PROVIDERS_README.md) - Cache system docs
- [Flutter Riverpod](https://riverpod.dev/) - State management

## 🆘 Need Help?

1. Đọc documentation trong `lib/docs/`
2. Search trong codebase với VS Code (Ctrl+Shift+F)
3. Hỏi team lead

## ✅ Checklist cho Developer mới

- [ ] Setup local environment
- [ ] Run app successfully
- [ ] Đọc ARCHITECTURE.md
- [ ] Đọc cached_providers.dart
- [ ] Tạo một feature branch
- [ ] Implement và test một task nhỏ
- [ ] Submit PR đầu tiên

---

**Happy Coding! 🎉**
