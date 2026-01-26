// MIGRATED TO REAL PROVIDERS - This file now re-exports from cached_providers.dart
// Keeping backward compatibility for existing imports

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store.dart';

// Re-export from cached_providers.dart
// NOTE: managementTaskServiceProvider is NOT exported here to avoid ambiguous import
// Use 'import management_task_provider.dart' or 'import cached_providers.dart' directly
export '../providers/cached_providers.dart'
    show
        // Task providers (Manager/CEO)
        cachedManagerAssignedTasksProvider,
        cachedManagerCreatedTasksProvider,
        cachedTaskStatisticsProvider,
        cachedCeoStrategicTasksProvider,
        cachedPendingApprovalsProvider,
        cachedCompanyTaskStatisticsProvider,
        // Staff providers
        cachedManagerTeamMembersProvider,
        cachedStaffStatsProvider,
        cachedAllStaffProvider,
        cachedStaffListProvider,
        // Dashboard providers (Manager)
        cachedManagerDashboardKPIsProvider,
        cachedManagerRecentActivitiesProvider,
        // Service providers (only staffServiceProvider, not managementTaskServiceProvider)
        staffServiceProvider,
        // Refresh functions (Manager/CEO)
        refreshStaffList,
        refreshManagerAssignedTasks,
        refreshManagerCreatedTasks,
        refreshAllManagementTasks,
        refreshAllManagerData,
        refreshAllTasksCache,
        invalidateAllTasksCache,
        refreshAllStaffData,
        // Driver providers
        cachedDriverDeliveriesProvider,
        cachedDriverDeliveryHistoryProvider,
        cachedDriverDashboardStatsProvider,
        refreshDriverDeliveries,
        refreshDriverHistory,
        refreshAllDriverData,
        driverDeliveryListenerProvider,
        // Warehouse providers
        cachedWarehouseOrdersProvider,
        cachedWarehouseDashboardStatsProvider,
        refreshWarehouseOrders,
        warehouseOrderListenerProvider,
        // Shift Leader providers
        cachedShiftLeaderTeamProvider,
        cachedShiftLeaderTasksProvider,
        cachedShiftLeaderDashboardStatsProvider,
        refreshShiftLeaderData,
        // Staff providers
        cachedStaffAttendanceProvider,
        cachedStaffMyTasksProvider,
        cachedStaffDashboardStatsProvider,
        refreshStaffData,
        // Sales providers
        cachedSalesRoutesProvider,
        cachedSalesCustomersProvider,
        cachedSalesOrdersProvider,
        cachedSalesDashboardStatsProvider,
        refreshSalesData,
        salesOrderListenerProvider,
        // Super Admin providers
        cachedAllCompaniesProvider,
        cachedPlatformStatsProvider,
        refreshSuperAdminData,
        // Universal refresh
        refreshAllDataByRole;

// Dummy CachedData class (still used by some legacy code)
class CachedData<T> {
  final T data;
  const CachedData(this.data);
}

// Store providers (not yet migrated)
final cachedStoresProvider =
    FutureProvider((ref) async => CachedData<List<Store>>([]));

// Legacy alias providers (remove when no longer used)
final simpleAllTasksProvider =
    FutureProvider((ref) async => <dynamic>[]);
final simpleTaskStatsProvider =
    FutureProvider((ref) async => <String, int>{});

// Dummy refresh for stores (not yet migrated)
void refreshStores(WidgetRef ref) {
  // TODO: Implement proper refresh logic for stores
}
