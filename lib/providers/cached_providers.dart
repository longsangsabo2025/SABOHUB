/// Cached Providers with Real Data
/// Multi-layer caching: Memory → Disk → Network
/// Supports pull-to-refresh and realtime updates
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/management_task.dart';
import '../models/staff.dart';
import '../services/management_task_service.dart';
import '../services/staff_service.dart';
import 'auth_provider.dart';
import 'cache_provider.dart';

// ============================================================================
// SERVICE PROVIDERS
// ============================================================================

/// Management Task Service Provider (requires Ref for auth)
final managementTaskServiceProvider = Provider<ManagementTaskService>((ref) {
  return ManagementTaskService(ref);
});

/// Staff Service Provider
final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService();
});

// ============================================================================
// CACHED TASK PROVIDERS
// ============================================================================

/// Cached Tasks Assigned to Me (Manager)
/// Uses memory cache → disk cache → network fallback
final cachedManagerAssignedTasksProvider =
    FutureProvider.autoDispose<List<ManagementTask>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  // Skip if not authenticated
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'assigned_tasks_$userId';

  // Layer 1: Memory cache
  final cached = memoryCache.get<List<ManagementTask>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Layer 2: Disk cache
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    final diskCached = await persistentCache.getList<ManagementTask>(
      cacheKey,
      (json) => ManagementTask.fromJson(json),
    );
    if (diskCached != null && diskCached.isNotEmpty) {
      // Restore to memory cache
      memoryCache.set(cacheKey, diskCached, config.defaultTTL);
      // Refresh in background
      _refreshAssignedTasksInBackground(ref, cacheKey);
      return diskCached;
    }
  } catch (e) {
    // Ignore disk cache errors
  }

  // Layer 3: Network fetch
  final service = ref.watch(managementTaskServiceProvider);
  final tasks = await service.getTasksAssignedToMe();

  // Cache result
  memoryCache.set(cacheKey, tasks, config.defaultTTL);
  
  // Persist to disk
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    await persistentCache.set(
      cacheKey,
      tasks.map((t) => t.toJson()).toList(),
      config.longTTL,
    );
  } catch (e) {
    // Ignore persistence errors
  }

  return tasks;
});

/// Background refresh for assigned tasks
Future<void> _refreshAssignedTasksInBackground(
    Ref ref, String cacheKey) async {
  try {
    final service = ref.read(managementTaskServiceProvider);
    final tasks = await service.getTasksAssignedToMe();
    
    final memoryCache = ref.read(memoryCacheProvider);
    final config = ref.read(cacheConfigProvider);
    memoryCache.set(cacheKey, tasks, config.defaultTTL);
    
    final persistentCache = await ref.read(persistentCacheProvider.future);
    await persistentCache.set(
      cacheKey,
      tasks.map((t) => t.toJson()).toList(),
      config.longTTL,
    );
  } catch (e) {
    // Silently fail background refresh
  }
}

/// Cached Tasks Created by Me (Manager)
final cachedManagerCreatedTasksProvider =
    FutureProvider.autoDispose<List<ManagementTask>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'created_tasks_$userId';

  // Layer 1: Memory cache
  final cached = memoryCache.get<List<ManagementTask>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Layer 2: Disk cache
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    final diskCached = await persistentCache.getList<ManagementTask>(
      cacheKey,
      (json) => ManagementTask.fromJson(json),
    );
    if (diskCached != null && diskCached.isNotEmpty) {
      memoryCache.set(cacheKey, diskCached, config.defaultTTL);
      return diskCached;
    }
  } catch (e) {
    // Ignore
  }

  // Layer 3: Network fetch
  final service = ref.watch(managementTaskServiceProvider);
  final tasks = await service.getTasksCreatedByMe();

  // Cache
  memoryCache.set(cacheKey, tasks, config.defaultTTL);
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    await persistentCache.set(
      cacheKey,
      tasks.map((t) => t.toJson()).toList(),
      config.longTTL,
    );
  } catch (e) {
    // Ignore
  }

  return tasks;
});

/// Cached CEO Strategic Tasks
final cachedCeoStrategicTasksProvider =
    FutureProvider.autoDispose<List<ManagementTask>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'ceo_strategic_tasks_$userId';

  // Memory cache first
  final cached = memoryCache.get<List<ManagementTask>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Disk cache
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    final diskCached = await persistentCache.getList<ManagementTask>(
      cacheKey,
      (json) => ManagementTask.fromJson(json),
    );
    if (diskCached != null && diskCached.isNotEmpty) {
      memoryCache.set(cacheKey, diskCached, config.defaultTTL);
      return diskCached;
    }
  } catch (e) {
    // Ignore
  }

  // Network fetch
  final service = ref.watch(managementTaskServiceProvider);
  final tasks = await service.getCEOStrategicTasks();

  // Cache
  memoryCache.set(cacheKey, tasks, config.defaultTTL);
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    await persistentCache.set(
      cacheKey,
      tasks.map((t) => t.toJson()).toList(),
      config.longTTL,
    );
  } catch (e) {
    // Ignore
  }

  return tasks;
});

/// Cached Pending Approvals
final cachedPendingApprovalsProvider =
    FutureProvider.autoDispose<List<TaskApproval>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated) {
    return [];
  }
  
  final cacheKey = 'pending_approvals';

  final cached = memoryCache.get<List<TaskApproval>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final service = ref.watch(managementTaskServiceProvider);
  final approvals = await service.getPendingApprovals();

  memoryCache.set(cacheKey, approvals, config.shortTTL); // Short TTL for approvals

  return approvals;
});

/// Cached Task Statistics
final cachedTaskStatisticsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return {};
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'task_stats_$userId';

  final cached = memoryCache.get<Map<String, int>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final service = ref.watch(managementTaskServiceProvider);
  final stats = await service.getTaskStatistics();

  memoryCache.set(cacheKey, stats, config.defaultTTL);

  return stats;
});

/// Cached Company Task Statistics (for CEO dashboard)
final cachedCompanyTaskStatisticsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final companyId = authState.user!.companyId;
  if (companyId == null) return [];
  
  final cacheKey = 'company_task_stats_$companyId';

  final cached = memoryCache.get<List<Map<String, dynamic>>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final service = ref.watch(managementTaskServiceProvider);
  final stats = await service.getCompanyTaskStatistics();

  memoryCache.set(cacheKey, stats, config.defaultTTL);

  return stats;
});

// ============================================================================
// CACHED STAFF PROVIDERS
// ============================================================================

/// Cached Staff List (for Manager view)
final cachedStaffListProvider =
    FutureProvider.autoDispose<List<Staff>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final companyId = authState.user!.companyId;
  final cacheKey = companyId != null ? 'staff_list_$companyId' : 'staff_list_all';

  // Memory cache
  final cached = memoryCache.get<List<Staff>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Disk cache
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    final diskCached = await persistentCache.getList<Staff>(
      cacheKey,
      (json) => Staff.fromJson(json),
    );
    if (diskCached != null && diskCached.isNotEmpty) {
      memoryCache.set(cacheKey, diskCached, config.defaultTTL);
      return diskCached;
    }
  } catch (e) {
    // Ignore
  }

  // Network fetch
  final service = ref.watch(staffServiceProvider);
  final staff = await service.getAllStaff(companyId: companyId);

  // Cache
  memoryCache.set(cacheKey, staff, config.defaultTTL);
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    await persistentCache.set(
      cacheKey,
      staff.map((s) => s.toJson()).toList(),
      config.longTTL,
    );
  } catch (e) {
    // Ignore
  }

  return staff;
});

/// Cached All Staff (for SuperAdmin/CEO)
final cachedAllStaffProvider =
    FutureProvider.autoDispose<List<Staff>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated) {
    return [];
  }
  
  const cacheKey = 'all_staff';

  final cached = memoryCache.get<List<Staff>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final service = ref.watch(staffServiceProvider);
  final staff = await service.getAllStaff();

  memoryCache.set(cacheKey, staff, config.defaultTTL);

  return staff;
});

/// Cached Manager Team Members (same branch)
final cachedManagerTeamMembersProvider =
    FutureProvider.autoDispose<List<Staff>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final companyId = authState.user!.companyId;
  final branchId = authState.user!.branchId;
  final cacheKey = 'team_members_${companyId ?? 'no_company'}_${branchId ?? 'no_branch'}';

  final cached = memoryCache.get<List<Staff>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final service = ref.watch(staffServiceProvider);
  // Filter by both company and branch if available
  final team = await service.getAllStaff(
    companyId: companyId,
    branchId: branchId,
  );

  memoryCache.set(cacheKey, team, config.defaultTTL);

  return team;
});

// ============================================================================
// CACHED DASHBOARD PROVIDERS
// ============================================================================

/// Cached Manager Dashboard KPIs
final cachedManagerDashboardKPIsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return {};
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'manager_kpis_$userId';

  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Calculate KPIs from tasks
  final assignedTasks = await ref.watch(cachedManagerAssignedTasksProvider.future);
  final createdTasks = await ref.watch(cachedManagerCreatedTasksProvider.future);
  
  final now = DateTime.now();
  final kpis = {
    'total_assigned': assignedTasks.length,
    'total_created': createdTasks.length,
    'pending': assignedTasks.where((t) => t.status == TaskStatus.pending).length,
    'in_progress': assignedTasks.where((t) => t.status == TaskStatus.inProgress).length,
    'completed': assignedTasks.where((t) => t.status == TaskStatus.completed).length,
    'overdue': assignedTasks.where((t) => 
      t.dueDate != null && t.dueDate!.isBefore(now) && t.status != TaskStatus.completed
    ).length,
    'completion_rate': assignedTasks.isEmpty ? 0.0 : 
      (assignedTasks.where((t) => t.status == TaskStatus.completed).length / assignedTasks.length * 100).round(),
  };

  memoryCache.set(cacheKey, kpis, config.shortTTL);

  return kpis;
});

/// Cached Staff Stats
final cachedStaffStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return {};
  }
  
  final companyId = authState.user!.companyId;
  final cacheKey = 'staff_stats_$companyId';

  final cached = memoryCache.get<Map<String, int>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final staff = await ref.watch(cachedStaffListProvider.future);
  
  final stats = {
    'total': staff.length,
    'active': staff.where((s) => s.status == 'active').length,
    'inactive': staff.where((s) => s.status == 'inactive').length,
    'managers': staff.where((s) => s.role == 'manager').length,
    'staff': staff.where((s) => s.role == 'staff').length,
  };

  memoryCache.set(cacheKey, stats, config.defaultTTL);

  return stats;
});

/// Cached Manager Recent Activities
final cachedManagerRecentActivitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'recent_activities_$userId';

  final cached = memoryCache.get<List<Map<String, dynamic>>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Get recent task activities
  final assignedTasks = await ref.watch(cachedManagerAssignedTasksProvider.future);
  final createdTasks = await ref.watch(cachedManagerCreatedTasksProvider.future);
  
  final allTasks = [...assignedTasks, ...createdTasks];
  allTasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  
  final activities = allTasks.take(10).map((task) => {
    'type': 'task',
    'id': task.id,
    'title': task.title,
    'status': task.status.name,
    'timestamp': task.updatedAt.toIso8601String(),
  }).toList();

  memoryCache.set(cacheKey, activities, config.shortTTL);

  return activities;
});

// ============================================================================
// REFRESH FUNCTIONS
// ============================================================================

/// Refresh assigned tasks
void refreshManagerAssignedTasks(WidgetRef ref) {
  final authState = ref.read(authProvider);
  if (authState.user != null) {
    final cacheKey = 'assigned_tasks_${authState.user!.id}';
    ref.read(memoryCacheProvider).remove(cacheKey);
  }
  ref.invalidate(cachedManagerAssignedTasksProvider);
}

/// Refresh created tasks
void refreshManagerCreatedTasks(WidgetRef ref) {
  final authState = ref.read(authProvider);
  if (authState.user != null) {
    final cacheKey = 'created_tasks_${authState.user!.id}';
    ref.read(memoryCacheProvider).remove(cacheKey);
  }
  ref.invalidate(cachedManagerCreatedTasksProvider);
}

/// Refresh all management tasks
void refreshAllManagementTasks(WidgetRef ref) {
  refreshManagerAssignedTasks(ref);
  refreshManagerCreatedTasks(ref);
  ref.invalidate(cachedCeoStrategicTasksProvider);
  ref.invalidate(cachedPendingApprovalsProvider);
  ref.invalidate(cachedTaskStatisticsProvider);
  ref.invalidate(cachedCompanyTaskStatisticsProvider);
}

/// Refresh staff list
void refreshStaffList(WidgetRef ref) {
  final authState = ref.read(authProvider);
  if (authState.user?.companyId != null) {
    ref.read(memoryCacheProvider).remove('staff_list_${authState.user!.companyId}');
  }
  ref.invalidate(cachedStaffListProvider);
  ref.invalidate(cachedAllStaffProvider);
  ref.invalidate(cachedManagerTeamMembersProvider);
}

/// Refresh all staff data
void refreshAllStaffData(WidgetRef ref) {
  refreshStaffList(ref);
  ref.invalidate(cachedStaffStatsProvider);
}

/// Refresh all manager data (tasks + staff + KPIs)
void refreshAllManagerData(WidgetRef ref) {
  refreshAllManagementTasks(ref);
  refreshAllStaffData(ref);
  ref.invalidate(cachedManagerDashboardKPIsProvider);
  ref.invalidate(cachedManagerRecentActivitiesProvider);
}

/// Refresh all tasks cache with optional branch filter
void refreshAllTasksCache(WidgetRef ref, String? branchId) {
  refreshAllManagementTasks(ref);
}

/// Invalidate all tasks cache
void invalidateAllTasksCache(WidgetRef ref, String? branchId) {
  refreshAllTasksCache(ref, branchId);
}

// ============================================================================
// REALTIME SUBSCRIPTION PROVIDER
// ============================================================================

/// Realtime task updates subscription
/// Uses simple stream approach for better compatibility
final taskRealtimeProvider = StreamProvider.autoDispose<List<ManagementTask>>((ref) {
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return const Stream.empty();
  }
  
  final supabase = Supabase.instance.client;
  
  // Use simple stream from Supabase
  return supabase
      .from('tasks')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) {
        // Invalidate cache on any change
        ref.invalidate(cachedManagerAssignedTasksProvider);
        ref.invalidate(cachedManagerCreatedTasksProvider);
        ref.invalidate(cachedTaskStatisticsProvider);
        ref.invalidate(cachedManagerDashboardKPIsProvider);
        
        // Return parsed tasks
        return (data as List)
            .map((json) => ManagementTask.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      });
});

/// Simple realtime listener that auto-refreshes on changes
final taskChangeListenerProvider = Provider.autoDispose<void>((ref) {
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return;
  }
  
  final supabase = Supabase.instance.client;
  
  final subscription = supabase
      .from('tasks')
      .stream(primaryKey: ['id'])
      .listen((data) {
        // Auto-refresh on any task change
        ref.invalidate(cachedManagerAssignedTasksProvider);
        ref.invalidate(cachedManagerCreatedTasksProvider);
      });

  ref.onDispose(() {
    subscription.cancel();
  });
});

// ============================================================================
// DRIVER ROLE PROVIDERS
// ============================================================================

/// Driver Delivery Model (for caching)
class DriverDeliveryCache {
  final String id;
  final String deliveryNumber;
  final String status;
  final String? orderNumber;
  final double? totalAmount;
  final String? customerName;
  final String? customerAddress;
  final String? customerPhone;
  final double? latitude;
  final double? longitude;
  final DateTime deliveryDate;
  final DateTime? startedAt;

  DriverDeliveryCache({
    required this.id,
    required this.deliveryNumber,
    required this.status,
    this.orderNumber,
    this.totalAmount,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
    this.latitude,
    this.longitude,
    required this.deliveryDate,
    this.startedAt,
  });

  factory DriverDeliveryCache.fromJson(Map<String, dynamic> json) {
    final order = json['sales_orders'];
    final customer = order?['customers'];
    return DriverDeliveryCache(
      id: json['id'] as String,
      deliveryNumber: json['delivery_number'] as String? ?? 'DL-???',
      status: json['status'] as String,
      orderNumber: order?['order_number'] as String?,
      totalAmount: (order?['total'] as num?)?.toDouble() ?? (json['total_amount'] as num?)?.toDouble(),
      customerName: customer?['name'] as String?,
      customerAddress: customer?['address'] as String?,
      customerPhone: customer?['phone'] as String?,
      latitude: (customer?['lat'] as num?)?.toDouble(),
      longitude: (customer?['lng'] as num?)?.toDouble(),
      deliveryDate: DateTime.parse(json['delivery_date'] as String),
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'delivery_number': deliveryNumber,
    'status': status,
    'sales_orders': {
      'order_number': orderNumber,
      'total_amount': totalAmount,
      'customers': {
        'name': customerName,
        'address': customerAddress,
        'phone': customerPhone,
        'latitude': latitude,
        'longitude': longitude,
      },
    },
    'delivery_date': deliveryDate.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
  };
}

/// Cached Driver Deliveries (today's assigned deliveries)
final cachedDriverDeliveriesProvider =
    FutureProvider.autoDispose<List<DriverDeliveryCache>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final employeeId = authState.user!.id;
  final cacheKey = 'driver_deliveries_$employeeId';

  // Memory cache
  final cached = memoryCache.get<List<DriverDeliveryCache>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Network fetch
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('deliveries')
      .select('''
        *,
        sales_orders(
          order_number,
          total,
          customers(name, address, phone, lat, lng)
        )
      ''')
      .eq('driver_id', employeeId)
      .inFilter('status', ['planned', 'loading', 'in_progress'])
      .order('delivery_date', ascending: true);

  final deliveries = (response as List)
      .map((json) => DriverDeliveryCache.fromJson(json))
      .toList();

  // Cache
  memoryCache.set(cacheKey, deliveries, config.shortTTL);

  return deliveries;
});

/// Cached Driver Delivery History
final cachedDriverDeliveryHistoryProvider =
    FutureProvider.autoDispose<List<DriverDeliveryCache>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final employeeId = authState.user!.id;
  final cacheKey = 'driver_history_$employeeId';

  final cached = memoryCache.get<List<DriverDeliveryCache>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('deliveries')
      .select('''
        *,
        sales_orders(
          order_number,
          total,
          customers(name, address, phone, lat, lng)
        )
      ''')
      .eq('driver_id', employeeId)
      .inFilter('status', ['completed', 'cancelled'])
      .order('delivery_date', ascending: false)
      .limit(50);

  final deliveries = (response as List)
      .map((json) => DriverDeliveryCache.fromJson(json))
      .toList();

  memoryCache.set(cacheKey, deliveries, config.defaultTTL);

  return deliveries;
});

/// Cached Driver Dashboard Stats
final cachedDriverDashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return {};
  }
  
  final employeeId = authState.user!.id;
  final cacheKey = 'driver_stats_$employeeId';

  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final deliveries = await ref.watch(cachedDriverDeliveriesProvider.future);
  
  final stats = {
    'total_today': deliveries.length,
    'in_progress': deliveries.where((d) => d.status == 'in_progress').length,
    'assigned': deliveries.where((d) => d.status == 'assigned').length,
    'total_amount': deliveries.fold<double>(0, (sum, d) => sum + (d.totalAmount ?? 0)),
  };

  memoryCache.set(cacheKey, stats, config.shortTTL);

  return stats;
});

/// Refresh driver deliveries
void refreshDriverDeliveries(WidgetRef ref) {
  final authState = ref.read(authProvider);
  if (authState.user != null) {
    ref.read(memoryCacheProvider).remove('driver_deliveries_${authState.user!.id}');
  }
  ref.invalidate(cachedDriverDeliveriesProvider);
  ref.invalidate(cachedDriverDashboardStatsProvider);
}

/// Refresh driver history
void refreshDriverHistory(WidgetRef ref) {
  final authState = ref.read(authProvider);
  if (authState.user != null) {
    ref.read(memoryCacheProvider).remove('driver_history_${authState.user!.id}');
  }
  ref.invalidate(cachedDriverDeliveryHistoryProvider);
}

/// Refresh all driver data
void refreshAllDriverData(WidgetRef ref) {
  refreshDriverDeliveries(ref);
  refreshDriverHistory(ref);
}

/// Driver realtime listener
final driverDeliveryListenerProvider = Provider.autoDispose<void>((ref) {
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return;
  }
  
  final supabase = Supabase.instance.client;
  
  final subscription = supabase
      .from('deliveries')
      .stream(primaryKey: ['id'])
      .listen((data) {
        ref.invalidate(cachedDriverDeliveriesProvider);
        ref.invalidate(cachedDriverDashboardStatsProvider);
      });

  ref.onDispose(() {
    subscription.cancel();
  });
});

// ============================================================================
// WAREHOUSE ROLE PROVIDERS
// ============================================================================

/// Warehouse Order Model (for caching)
class WarehouseOrderCache {
  final String id;
  final String orderNumber;
  final String status;
  final String? customerName;
  final DateTime orderDate;
  final List<WarehouseOrderItemCache> items;

  WarehouseOrderCache({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.customerName,
    required this.orderDate,
    required this.items,
  });

  factory WarehouseOrderCache.fromJson(Map<String, dynamic> json) {
    final items = (json['sales_order_items'] as List?)
        ?.map((i) => WarehouseOrderItemCache.fromJson(i as Map<String, dynamic>))
        .toList() ?? [];
    return WarehouseOrderCache(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      customerName: (json['customers'] as Map<String, dynamic>?)?['name'] as String?,
      orderDate: DateTime.parse(json['order_date'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'status': status,
    'customers': {'name': customerName},
    'order_date': orderDate.toIso8601String(),
    'sales_order_items': items.map((i) => i.toJson()).toList(),
  };
}

class WarehouseOrderItemCache {
  final String id;
  final String productId;
  final String productName;
  final String? sku;
  final String? unit;
  final int quantity;

  WarehouseOrderItemCache({
    required this.id,
    required this.productId,
    required this.productName,
    this.sku,
    this.unit,
    required this.quantity,
  });

  factory WarehouseOrderItemCache.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    return WarehouseOrderItemCache(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: product?['name'] as String? ?? 'Unknown',
      sku: product?['sku'] as String?,
      unit: product?['unit'] as String? ?? 'pcs',
      quantity: json['quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'products': {'name': productName, 'sku': sku, 'unit': unit},
    'quantity': quantity,
  };
}

/// Cached Warehouse Orders (ready to pick)
final cachedWarehouseOrdersProvider =
    FutureProvider.autoDispose<List<WarehouseOrderCache>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final companyId = authState.user!.companyId;
  if (companyId == null) return [];
  
  final cacheKey = 'warehouse_orders_$companyId';

  final cached = memoryCache.get<List<WarehouseOrderCache>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('sales_orders')
      .select('*, customers(name), sales_order_items(*, products(name, sku, unit))')
      .eq('company_id', companyId)
      .inFilter('status', ['sent_to_warehouse', 'picking'])
      .order('created_at', ascending: true);

  final orders = (response as List)
      .map((json) => WarehouseOrderCache.fromJson(json))
      .toList();

  memoryCache.set(cacheKey, orders, config.shortTTL);

  return orders;
});

/// Cached Warehouse Dashboard Stats
final cachedWarehouseDashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return {};
  }
  
  final companyId = authState.user!.companyId;
  if (companyId == null) return {};
  
  final cacheKey = 'warehouse_stats_$companyId';

  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final orders = await ref.watch(cachedWarehouseOrdersProvider.future);
  
  final stats = {
    'total_orders': orders.length,
    'sent_to_warehouse': orders.where((o) => o.status == 'sent_to_warehouse').length,
    'picking': orders.where((o) => o.status == 'picking').length,
    'total_items': orders.fold<int>(0, (sum, o) => sum + o.items.length),
  };

  memoryCache.set(cacheKey, stats, config.shortTTL);

  return stats;
});

/// Refresh warehouse orders
void refreshWarehouseOrders(WidgetRef ref) {
  final authState = ref.read(authProvider);
  if (authState.user?.companyId != null) {
    ref.read(memoryCacheProvider).remove('warehouse_orders_${authState.user!.companyId}');
  }
  ref.invalidate(cachedWarehouseOrdersProvider);
  ref.invalidate(cachedWarehouseDashboardStatsProvider);
}

/// Warehouse realtime listener
final warehouseOrderListenerProvider = Provider.autoDispose<void>((ref) {
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return;
  }
  
  final supabase = Supabase.instance.client;
  
  final subscription = supabase
      .from('sales_orders')
      .stream(primaryKey: ['id'])
      .listen((data) {
        ref.invalidate(cachedWarehouseOrdersProvider);
        ref.invalidate(cachedWarehouseDashboardStatsProvider);
      });

  ref.onDispose(() {
    subscription.cancel();
  });
});

// ============================================================================
// SHIFT LEADER ROLE PROVIDERS
// ============================================================================

/// Cached Shift Leader Team Members
final cachedShiftLeaderTeamProvider =
    FutureProvider.autoDispose<List<Staff>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final companyId = authState.user!.companyId;
  final branchId = authState.user!.branchId;
  final cacheKey = 'shift_team_${companyId ?? 'all'}_${branchId ?? 'all'}';

  final cached = memoryCache.get<List<Staff>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final service = ref.watch(staffServiceProvider);
  final team = await service.getAllStaff(
    companyId: companyId,
    branchId: branchId,
  );

  // Filter to staff only (not managers)
  final staffOnly = team.where((s) => 
    s.role == 'staff' || s.role == 'STAFF'
  ).toList();

  memoryCache.set(cacheKey, staffOnly, config.defaultTTL);

  return staffOnly;
});

/// Cached Shift Leader Tasks (team tasks)
final cachedShiftLeaderTasksProvider =
    FutureProvider.autoDispose<List<ManagementTask>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'shift_leader_tasks_$userId';

  final cached = memoryCache.get<List<ManagementTask>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Shift leaders see their assigned tasks + tasks they created for staff
  final service = ref.watch(managementTaskServiceProvider);
  final assignedTasks = await service.getTasksAssignedToMe();
  final createdTasks = await service.getTasksCreatedByMe();
  
  final allTasks = [...assignedTasks, ...createdTasks];
  // Remove duplicates
  final uniqueTasks = allTasks.fold<Map<String, ManagementTask>>({}, (map, task) {
    map[task.id] = task;
    return map;
  }).values.toList();
  
  uniqueTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  memoryCache.set(cacheKey, uniqueTasks, config.defaultTTL);

  return uniqueTasks;
});

/// Cached Shift Leader Dashboard Stats
final cachedShiftLeaderDashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return {};
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'shift_leader_stats_$userId';

  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final tasks = await ref.watch(cachedShiftLeaderTasksProvider.future);
  final team = await ref.watch(cachedShiftLeaderTeamProvider.future);
  
  final now = DateTime.now();
  final stats = {
    'team_size': team.length,
    'total_tasks': tasks.length,
    'pending_tasks': tasks.where((t) => t.status == TaskStatus.pending).length,
    'in_progress_tasks': tasks.where((t) => t.status == TaskStatus.inProgress).length,
    'completed_today': tasks.where((t) => 
      t.status == TaskStatus.completed && 
      t.completedAt != null &&
      t.completedAt!.day == now.day
    ).length,
  };

  memoryCache.set(cacheKey, stats, config.shortTTL);

  return stats;
});

/// Refresh shift leader data
void refreshShiftLeaderData(WidgetRef ref) {
  ref.invalidate(cachedShiftLeaderTeamProvider);
  ref.invalidate(cachedShiftLeaderTasksProvider);
  ref.invalidate(cachedShiftLeaderDashboardStatsProvider);
}

// ============================================================================
// STAFF ROLE PROVIDERS (Generic staff, not specific department)
// ============================================================================

/// Cached Staff Attendance (today)
final cachedStaffAttendanceProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return null;
  }
  
  final userId = authState.user!.id;
  final today = DateTime.now();
  final cacheKey = 'staff_attendance_${userId}_${today.year}_${today.month}_${today.day}';

  final cached = memoryCache.get<Map<String, dynamic>?>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final supabase = Supabase.instance.client;
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  final response = await supabase
      .from('attendance')
      .select('*')
      .eq('user_id', userId)
      .gte('check_in', startOfDay.toIso8601String())
      .lt('check_in', endOfDay.toIso8601String())
      .order('check_in', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response != null) {
    memoryCache.set(cacheKey, response, config.shortTTL);
  }

  return response;
});

/// Cached Staff My Tasks
final cachedStaffMyTasksProvider =
    FutureProvider.autoDispose<List<ManagementTask>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'staff_my_tasks_$userId';

  final cached = memoryCache.get<List<ManagementTask>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final service = ref.watch(managementTaskServiceProvider);
  final tasks = await service.getTasksAssignedToMe();

  memoryCache.set(cacheKey, tasks, config.defaultTTL);

  return tasks;
});

/// Cached Staff Dashboard Stats
final cachedStaffDashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return {};
  }
  
  final userId = authState.user!.id;
  final cacheKey = 'staff_dashboard_stats_$userId';

  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final tasks = await ref.watch(cachedStaffMyTasksProvider.future);
  final attendance = await ref.watch(cachedStaffAttendanceProvider.future);
  
  final stats = {
    'total_tasks': tasks.length,
    'pending_tasks': tasks.where((t) => t.status == TaskStatus.pending).length,
    'in_progress_tasks': tasks.where((t) => t.status == TaskStatus.inProgress).length,
    'completed_tasks': tasks.where((t) => t.status == TaskStatus.completed).length,
    'is_checked_in': attendance != null && attendance['check_in'] != null,
    'is_checked_out': attendance != null && attendance['check_out'] != null,
  };

  memoryCache.set(cacheKey, stats, config.shortTTL);

  return stats;
});

/// Refresh staff data
void refreshStaffData(WidgetRef ref) {
  ref.invalidate(cachedStaffAttendanceProvider);
  ref.invalidate(cachedStaffMyTasksProvider);
  ref.invalidate(cachedStaffDashboardStatsProvider);
}

// ============================================================================
// SALES ROLE PROVIDERS (Distribution Sales)
// ============================================================================

/// Cached Sales Routes
final cachedSalesRoutesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final companyId = authState.user!.companyId;
  final employeeId = authState.user!.id;
  final cacheKey = 'sales_routes_${companyId}_$employeeId';

  final cached = memoryCache.get<List<Map<String, dynamic>>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('sales_routes')
      .select('*, employees(full_name)')
      .eq('assigned_to_id', employeeId)
      .eq('status', 'active')
      .order('name');

  final routes = List<Map<String, dynamic>>.from(response as List);
  memoryCache.set(cacheKey, routes, config.defaultTTL);

  return routes;
});

/// Cached Sales Customers
final cachedSalesCustomersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final companyId = authState.user!.companyId;
  if (companyId == null) return [];
  
  final cacheKey = 'sales_customers_$companyId';

  final cached = memoryCache.get<List<Map<String, dynamic>>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('customers')
      .select('*')
      .eq('company_id', companyId)
      .eq('status', 'active')
      .isFilter('deleted_at', null)
      .order('name');

  final customers = List<Map<String, dynamic>>.from(response as List);
  memoryCache.set(cacheKey, customers, config.defaultTTL);

  return customers;
});

/// Cached Sales Orders
final cachedSalesOrdersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return [];
  }
  
  final companyId = authState.user!.companyId;
  final employeeId = authState.user!.id;
  if (companyId == null) return [];
  
  final cacheKey = 'sales_orders_${companyId}_$employeeId';

  final cached = memoryCache.get<List<Map<String, dynamic>>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('sales_orders')
      .select('*, customer:customer_id(*)')
      .eq('company_id', companyId)
      .eq('created_by', employeeId)
      .order('created_at', ascending: false)
      .limit(50);

  final orders = List<Map<String, dynamic>>.from(response as List);
  memoryCache.set(cacheKey, orders, config.shortTTL);

  return orders;
});

/// Cached Sales Dashboard Stats
final cachedSalesDashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return {};
  }
  
  final employeeId = authState.user!.id;
  final cacheKey = 'sales_dashboard_stats_$employeeId';

  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final routes = await ref.watch(cachedSalesRoutesProvider.future);
  final customers = await ref.watch(cachedSalesCustomersProvider.future);
  final orders = await ref.watch(cachedSalesOrdersProvider.future);
  
  final today = DateTime.now();
  final todayOrders = orders.where((o) {
    final createdAt = DateTime.tryParse(o['created_at'] as String? ?? '');
    return createdAt != null && 
           createdAt.year == today.year && 
           createdAt.month == today.month && 
           createdAt.day == today.day;
  }).toList();
  
  final stats = {
    'total_routes': routes.length,
    'total_customers': customers.length,
    'total_orders': orders.length,
    'orders_today': todayOrders.length,
    'revenue_today': todayOrders.fold<double>(0, 
      (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0)),
  };

  memoryCache.set(cacheKey, stats, config.shortTTL);

  return stats;
});

/// Refresh sales data
void refreshSalesData(WidgetRef ref) {
  ref.invalidate(cachedSalesRoutesProvider);
  ref.invalidate(cachedSalesCustomersProvider);
  ref.invalidate(cachedSalesOrdersProvider);
  ref.invalidate(cachedSalesDashboardStatsProvider);
}

/// Sales realtime listener
final salesOrderListenerProvider = Provider.autoDispose<void>((ref) {
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return;
  }
  
  final supabase = Supabase.instance.client;
  
  final subscription = supabase
      .from('sales_orders')
      .stream(primaryKey: ['id'])
      .listen((data) {
        ref.invalidate(cachedSalesOrdersProvider);
        ref.invalidate(cachedSalesDashboardStatsProvider);
      });

  ref.onDispose(() {
    subscription.cancel();
  });
});

// ============================================================================
// SUPER ADMIN ROLE PROVIDERS
// ============================================================================

/// Cached All Companies (for SuperAdmin)
final cachedAllCompaniesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated) {
    return [];
  }
  
  const cacheKey = 'all_companies';

  final cached = memoryCache.get<List<Map<String, dynamic>>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('companies')
      .select('*')
      .order('name');

  final companies = List<Map<String, dynamic>>.from(response as List);
  memoryCache.set(cacheKey, companies, config.defaultTTL);

  return companies;
});

/// Cached Platform Stats (for SuperAdmin)
final cachedPlatformStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated) {
    return {};
  }
  
  const cacheKey = 'platform_stats';

  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  final supabase = Supabase.instance.client;
  
  // Fetch counts
  final companiesCount = await supabase
      .from('companies')
      .select('id')
      .count();
  
  final employeesCount = await supabase
      .from('employees')
      .select('id')
      .eq('is_active', true)
      .count();
  
  final ordersCount = await supabase
      .from('sales_orders')
      .select('id')
      .count();

  final stats = {
    'total_companies': companiesCount.count,
    'total_employees': employeesCount.count,
    'total_orders': ordersCount.count,
  };

  memoryCache.set(cacheKey, stats, config.defaultTTL);

  return stats;
});

/// Refresh super admin data
void refreshSuperAdminData(WidgetRef ref) {
  ref.invalidate(cachedAllCompaniesProvider);
  ref.invalidate(cachedPlatformStatsProvider);
  ref.invalidate(cachedAllStaffProvider);
}

// ============================================================================
// UNIVERSAL REFRESH BY ROLE
// ============================================================================

/// Refresh all data based on user role
void refreshAllDataByRole(WidgetRef ref) {
  final authState = ref.read(authProvider);
  if (authState.user == null) return;
  
  final role = authState.user!.role;
  
  switch (role.name.toUpperCase()) {
    case 'CEO':
      refreshAllManagementTasks(ref);
      refreshAllStaffData(ref);
      break;
    case 'MANAGER':
      refreshAllManagerData(ref);
      break;
    case 'SHIFT_LEADER':
    case 'SHIFTLEADER':
      refreshShiftLeaderData(ref);
      break;
    case 'DRIVER':
      refreshAllDriverData(ref);
      break;
    case 'WAREHOUSE':
      refreshWarehouseOrders(ref);
      break;
    case 'STAFF':
      refreshStaffData(ref);
      break;
    case 'SUPER_ADMIN':
    case 'SUPERADMIN':
      refreshSuperAdminData(ref);
      break;
    default:
      // Generic refresh
      refreshStaffData(ref);
  }
}
