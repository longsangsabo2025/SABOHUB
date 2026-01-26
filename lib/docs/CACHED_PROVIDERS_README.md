# Cached Providers System - SABOHUB

## 📋 Overview

Hệ thống cached providers mới thay thế hoàn toàn các dummy providers cũ, cung cấp:

- ✅ **Multi-layer caching**: Memory → Disk → Network
- ✅ **Pull-to-refresh support**: RefreshIndicator integration
- ✅ **Realtime updates**: Supabase Realtime subscriptions
- ✅ **Auto-dispose**: Prevent memory leaks
- ✅ **Authentication-aware**: Requires valid auth state
- ✅ **Role-based**: Different providers for each role

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CACHED PROVIDERS                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │ Memory Cache│ → │ Disk Cache  │ → │ Network (API)   │   │
│  │   (5 min)   │   │  (1 hour)   │   │                 │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                   REALTIME LISTENER                          │
│  Supabase Realtime → Auto-invalidate cache → UI updates     │
└─────────────────────────────────────────────────────────────┘
```

## 🎭 Supported Roles

| Role | Providers | Realtime |
|------|-----------|----------|
| **CEO** | Tasks, Staff, Company Stats | ✅ |
| **Manager** | Tasks, Team, KPIs | ✅ |
| **Shift Leader** | Team Tasks, Staff | ✅ |
| **Driver** | Deliveries, History | ✅ |
| **Warehouse** | Orders, Stock | ✅ |
| **Staff** | Attendance, Tasks | ✅ |
| **Sales** | Routes, Customers, Orders | ✅ |
| **Super Admin** | Companies, Platform Stats | ✅ |

## 📦 Files

| File | Purpose |
|------|---------|
| `lib/providers/cached_providers.dart` | **Main file** - All cached providers |
| `lib/providers/cache_provider.dart` | Cache infrastructure (Memory + Disk) |
| `lib/utils/pull_to_refresh.dart` | Pull-to-refresh utilities |
| `lib/utils/dummy_providers.dart` | Re-exports (backward compatibility) |

## 🔌 Available Providers by Role

### CEO/Manager Providers

| Provider | Description |
|----------|-------------|
| `cachedManagerAssignedTasksProvider` | Tasks assigned to me |
| `cachedManagerCreatedTasksProvider` | Tasks I created |
| `cachedCeoStrategicTasksProvider` | CEO strategic tasks |
| `cachedPendingApprovalsProvider` | Pending approvals |
| `cachedTaskStatisticsProvider` | Task stats |
| `cachedCompanyTaskStatisticsProvider` | Company stats |
| `cachedManagerDashboardKPIsProvider` | KPIs |
| `cachedManagerRecentActivitiesProvider` | Activities |

### Driver Providers

| Provider | Description |
|----------|-------------|
| `cachedDriverDeliveriesProvider` | Today's deliveries |
| `cachedDriverDeliveryHistoryProvider` | Past deliveries |
| `cachedDriverDashboardStatsProvider` | Driver stats |
| `driverDeliveryListenerProvider` | Realtime listener |

### Warehouse Providers

| Provider | Description |
|----------|-------------|
| `cachedWarehouseOrdersProvider` | Orders to pick |
| `cachedWarehouseDashboardStatsProvider` | Warehouse stats |
| `warehouseOrderListenerProvider` | Realtime listener |

### Shift Leader Providers

| Provider | Description |
|----------|-------------|
| `cachedShiftLeaderTeamProvider` | Team members |
| `cachedShiftLeaderTasksProvider` | Team tasks |
| `cachedShiftLeaderDashboardStatsProvider` | Stats |

### Staff Providers

| Provider | Description |
|----------|-------------|
| `cachedStaffAttendanceProvider` | Today's attendance |
| `cachedStaffMyTasksProvider` | My tasks |
| `cachedStaffDashboardStatsProvider` | Stats |

### Sales Providers

| Provider | Description |
|----------|-------------|
| `cachedSalesRoutesProvider` | My routes |
| `cachedSalesCustomersProvider` | Customers |
| `cachedSalesOrdersProvider` | My orders |
| `cachedSalesDashboardStatsProvider` | Sales stats |
| `salesOrderListenerProvider` | Realtime listener |

### Super Admin Providers

| Provider | Description |
|----------|-------------|
| `cachedAllCompaniesProvider` | All companies |
| `cachedPlatformStatsProvider` | Platform stats |

### Staff/Employee Providers

| Provider | Description |
|----------|-------------|
| `cachedStaffListProvider` | Staff list (by company) |
| `cachedAllStaffProvider` | All staff |
| `cachedManagerTeamMembersProvider` | Team members |
| `cachedStaffStatsProvider` | Staff statistics |

## 🔄 Refresh Functions

```dart
// By Role
refreshAllDataByRole(ref);          // Auto-detect role and refresh

// Manager/CEO
refreshAllManagementTasks(ref);
refreshAllStaffData(ref);
refreshAllManagerData(ref);

// Driver
refreshDriverDeliveries(ref);
refreshDriverHistory(ref);
refreshAllDriverData(ref);

// Warehouse
refreshWarehouseOrders(ref);

// Shift Leader
refreshShiftLeaderData(ref);

// Staff
refreshStaffData(ref);

// Sales
refreshSalesData(ref);

// Super Admin
refreshSuperAdminData(ref);
```

## 📱 Usage Examples

### Basic Usage

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-select based on role
    final authState = ref.watch(authProvider);
    
    switch (authState.user?.role) {
      case SaboRole.driver:
        return _buildDriverDashboard(ref);
      case SaboRole.warehouse:
        return _buildWarehouseDashboard(ref);
      default:
        return _buildStaffDashboard(ref);
    }
  }
  
  Widget _buildDriverDashboard(WidgetRef ref) {
    final deliveries = ref.watch(cachedDriverDeliveriesProvider);
    return deliveries.when(
      data: (list) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### Universal Refresh

```dart
// In any screen, refresh all data for current role
RefreshIndicator(
  onRefresh: () async {
    refreshAllDataByRole(ref);
    await Future.delayed(Duration(milliseconds: 300));
  },
  child: YourContent(),
)
```

### Enable Realtime for Role

```dart
class DriverScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Enable realtime
    ref.watch(driverDeliveryListenerProvider);
    
    // Data will auto-refresh when changes occur
    final deliveries = ref.watch(cachedDriverDeliveriesProvider);
    // ...
  }
}
```

## ⚠️ Important Notes

1. **Authentication Required**: All providers return empty data if not authenticated
2. **Role-specific**: Use the correct providers for each role
3. **Realtime Listeners**: Enable once per screen, not per widget
4. **Cache TTL**: Short TTL for volatile data, long TTL for stable data
5. **Background Refresh**: Disk cache triggers background refresh on hit

## 🔧 Migration Guide

### From Old Dummy Providers

All imports remain the same! The `dummy_providers.dart` now re-exports from `cached_providers.dart`.

```dart
// This still works
import '../utils/dummy_providers.dart';

// But now returns REAL data!
final tasks = ref.watch(cachedManagerAssignedTasksProvider);
```

## 📊 Cache TTL Configuration

| Data Type | Memory TTL | Disk TTL |
|-----------|------------|----------|
| Dashboard Stats | 2 min | N/A |
| Task Lists | 5 min | 1 hour |
| Staff Lists | 5 min | 1 hour |
| Deliveries | 2 min | N/A |
| Orders | 2 min | N/A |
| Attendance | 2 min | N/A |
