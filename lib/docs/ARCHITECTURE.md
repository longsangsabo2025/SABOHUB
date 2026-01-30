# SABOHUB Architecture Documentation

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        SABOHUB App                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   Screens    │  │   Widgets    │  │      Layouts         │  │
│  │  (Pages)     │  │  (Components)│  │  (Role-based)        │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
│         │                 │                      │              │
│  ┌──────▼─────────────────▼──────────────────────▼───────────┐  │
│  │                    PROVIDERS (Riverpod)                    │  │
│  │  ┌────────────┐  ┌────────────┐  ┌──────────────────┐     │  │
│  │  │    Auth    │  │   Cached   │  │    Realtime      │     │  │
│  │  │  Provider  │  │  Providers │  │   Listeners      │     │  │
│  │  └────────────┘  └────────────┘  └──────────────────┘     │  │
│  └───────────────────────────┬───────────────────────────────┘  │
│                              │                                   │
│  ┌───────────────────────────▼───────────────────────────────┐  │
│  │                    SERVICES                                │  │
│  │  ┌────────────┐  ┌────────────┐  ┌──────────────────┐     │  │
│  │  │    Staff   │  │    Task    │  │   Notification   │     │  │
│  │  │  Service   │  │  Service   │  │     Service      │     │  │
│  │  └────────────┘  └────────────┘  └──────────────────┘     │  │
│  └───────────────────────────┬───────────────────────────────┘  │
│                              │                                   │
│  ┌───────────────────────────▼───────────────────────────────┐  │
│  │                    CACHE LAYER                             │  │
│  │  ┌────────────────┐  ┌────────────────────────────────┐   │  │
│  │  │  Memory Cache  │  │        Disk Cache              │   │  │
│  │  │  (5 min TTL)   │  │       (1 hour TTL)             │   │  │
│  │  └────────────────┘  └────────────────────────────────┘   │  │
│  └───────────────────────────┬───────────────────────────────┘  │
│                              │                                   │
│  ┌───────────────────────────▼───────────────────────────────┐  │
│  │                    SUPABASE                                │  │
│  │  ┌────────────┐  ┌────────────┐  ┌──────────────────┐     │  │
│  │  │   Auth     │  │  Database  │  │    Realtime      │     │  │
│  │  │            │  │ PostgreSQL │  │    WebSocket     │     │  │
│  │  └────────────┘  └────────────┘  └──────────────────┘     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Folder Structure

```
lib/
├── core/                      # Core utilities
│   ├── navigation/            # Navigation models
│   └── theme/                 # App themes
│
├── layouts/                   # Role-based layouts
│   ├── manager_main_layout.dart
│   ├── driver_main_layout.dart
│   ├── warehouse_main_layout.dart
│   ├── shift_leader_main_layout.dart
│   ├── distribution_manager_layout.dart
│   ├── distribution_sales_layout.dart
│   ├── distribution_driver_layout_refactored.dart
│   ├── distribution_warehouse_layout.dart
│   ├── distribution_finance_layout.dart
│   └── distribution_customer_service_layout.dart
│
├── models/                    # Data models
│   ├── staff.dart
│   ├── management_task.dart
│   └── ...
│
├── pages/                     # Screen pages
│   ├── ceo/
│   ├── manager/
│   ├── driver/
│   ├── warehouse/
│   ├── shift_leader/
│   ├── staff/
│   └── ...
│
├── providers/                 # Riverpod providers
│   ├── auth_provider.dart     # Authentication state
│   ├── cached_providers.dart  # ⭐ Main cached data providers
│   ├── cache_provider.dart    # Cache infrastructure
│   └── ...
│
├── services/                  # Business logic services
│   ├── staff_service.dart
│   ├── management_task_service.dart
│   ├── notification_service.dart
│   └── ...
│
├── utils/                     # Utilities
│   ├── pull_to_refresh.dart   # Refresh utilities
│   ├── dummy_providers.dart   # Backward compatibility
│   └── ...
│
└── widgets/                   # Reusable widgets
    ├── realtime_notification_widgets.dart
    ├── skeleton_loading.dart
    ├── state_displays.dart
    └── ...
```

## 🎭 Role System

SABOHUB supports multiple user roles with dedicated layouts:

| Role | Layout | Description |
|------|--------|-------------|
| **CEO** | CEOMainLayout | Strategic overview, company KPIs |
| **Manager** | ManagerMainLayout | Team management, task assignment |
| **Shift Leader** | ShiftLeaderMainLayout | Shift operations, team supervision |
| **Driver** | DriverMainLayout | Delivery tracking, route management |
| **Warehouse** | WarehouseMainLayout | Picking, packing, inventory |
| **Staff** | StaffMainLayout | Basic employee functions |
| **Sales** | DistributionSalesLayout | Orders, customers, routes |
| **Finance** | DistributionFinanceLayout | Payments, receivables |
| **CSKH** | DistributionCustomerServiceLayout | Customer support |

## 🔄 Cache System

### Multi-Layer Caching

```
Request → Memory Cache → Disk Cache → Network → Response
           (5 min)        (1 hour)
```

### Cache Keys

```dart
// Format: {entity}_{filter_params}
'manager_tasks_assigned_{userId}'
'driver_deliveries_{userId}_{date}'
'warehouse_orders_{companyId}'
```

### Refresh Functions

```dart
// Role-specific
refreshAllManagerData(ref);
refreshAllDriverData(ref);
refreshWarehouseOrders(ref);
refreshShiftLeaderData(ref);
refreshSalesData(ref);
refreshSuperAdminData(ref);

// Universal
refreshAllDataByRole(ref);  // Auto-detects role
```

## 📡 Realtime System

### Notification Bell

```dart
// Available in all layouts
const RealtimeNotificationBell()
```

### Realtime Listeners

```dart
// Driver deliveries
ref.watch(driverDeliveryListenerProvider);

// Warehouse orders
ref.watch(warehouseOrderListenerProvider);

// Sales orders
ref.watch(salesOrderListenerProvider);

// Management tasks
ref.watch(taskChangeListenerProvider);
```

## 🛠️ Key Components

### State Displays

```dart
// Error handling
ErrorDisplay(error: exception, onRetry: () => refresh());

// Empty states
EmptyStateDisplay.noDeliveries();
EmptyStateDisplay.noTasks();
EmptyStateDisplay.searchNoResults('query');

// Loading overlay
LoadingOverlay(isLoading: true, child: content);
```

### Skeleton Loading

```dart
// Dashboard skeleton
const SkeletonDashboard(kpiCount: 4, listItemCount: 5);

// Order card skeleton
const SkeletonOrderCard();

// List skeleton
const SkeletonListItem(hasAvatar: true, hasSubtitle: true);
```

## 📝 Provider Usage Examples

### Basic Data Fetching

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(cachedDriverDeliveriesProvider);
    
    return data.when(
      data: (items) => ListView(...),
      loading: () => const SkeletonOrderList(),
      error: (e, _) => ErrorDisplay(error: e),
    );
  }
}
```

### With Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    refreshAllDataByRole(ref);
    await Future.delayed(const Duration(milliseconds: 300));
  },
  child: content,
)
```

### With Realtime

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Enable realtime
  ref.watch(driverDeliveryListenerProvider);
  
  // Use cached data (auto-refreshes on changes)
  final data = ref.watch(cachedDriverDeliveriesProvider);
  // ...
}
```

## 🔐 Authentication Flow

```
App Start → Check Token → Valid? → Fetch User → Route to Layout
                          │
                          └─ Invalid → Login Screen
```

## 📊 Database Schema (Key Tables)

- `employees` - User/employee information
- `companies` - Company information
- `branches` - Branch/location data
- `management_tasks` - Task management
- `deliveries` - Delivery records
- `sales_orders` - Order information
- `notifications` - User notifications

## 🚀 Getting Started

1. Clone repository
2. Run `flutter pub get`
3. Configure Supabase credentials in `.env`
4. Run `flutter run`

## 📌 Key Files Reference

| File | Purpose |
|------|---------|
| [cached_providers.dart](lib/providers/cached_providers.dart) | Main cached data providers |
| [pull_to_refresh.dart](lib/utils/pull_to_refresh.dart) | Refresh utilities |
| [realtime_notification_widgets.dart](lib/widgets/realtime_notification_widgets.dart) | Notification system |
| [skeleton_loading.dart](lib/widgets/skeleton_loading.dart) | Loading skeletons |
| [state_displays.dart](lib/widgets/state_displays.dart) | Error/Empty displays |
