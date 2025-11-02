import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cached_provider.dart';
import '../models/staff.dart';
import '../services/staff_service.dart';

/// Staff Service Provider
final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService();
});

/// Cached All Staff Provider
final cachedAllStaffProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Staff>>,
    AsyncValue<CachedData<List<Staff>>>,
    String?>((ref, branchId) {
  final service = ref.read(staffServiceProvider);
  final notifier = CachedStateNotifier<List<Staff>>(
    fetchData: () => service.getAllStaff(branchId: branchId),
    cacheDuration: CacheConfig.medium, // 15 min - Staff data changes moderately
  );
  ref.keepAlive();
  notifier.fetch();
  return notifier;
});

/// Cached Single Staff Provider
final cachedStaffProvider = StateNotifierProvider.family<
    CachedStateNotifier<Staff?>,
    AsyncValue<CachedData<Staff?>>,
    String>((ref, staffId) {
  final service = ref.read(staffServiceProvider);
  final notifier = CachedStateNotifier<Staff?>(
    fetchData: () => service.getStaffById(staffId),
    cacheDuration: CacheConfig.medium, // 15 min
  );
  ref.keepAlive();
  notifier.fetch();
  return notifier;
});

/// Cached Staff By Role Provider
final cachedStaffByRoleProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Staff>>,
    AsyncValue<CachedData<List<Staff>>>,
    ({String role, String? branchId})>((ref, params) {
  final service = ref.read(staffServiceProvider);
  final notifier = CachedStateNotifier<List<Staff>>(
    fetchData: () =>
        service.getStaffByRole(params.role, branchId: params.branchId),
    cacheDuration: CacheConfig.medium, // 15 min
  );
  ref.keepAlive();
  notifier.fetch();
  return notifier;
});

/// Cached Staff Statistics Provider
final cachedStaffStatsProvider = StateNotifierProvider.family<
    CachedStateNotifier<Map<String, dynamic>>,
    AsyncValue<CachedData<Map<String, dynamic>>>,
    String?>((ref, branchId) {
  final service = ref.read(staffServiceProvider);
  final notifier = CachedStateNotifier<Map<String, dynamic>>(
    fetchData: () => service.getStaffStats(branchId: branchId),
    cacheDuration: CacheConfig.short, // 5 min - Stats change frequently
  );
  ref.keepAlive();
  notifier.fetch();
  return notifier;
});

/// Staff Stream Provider (Real-time updates - NOT CACHED)
final staffStreamProvider =
    StreamProvider.family<List<Staff>, String?>((ref, branchId) {
  final service = ref.read(staffServiceProvider);
  return service.subscribeToStaff(branchId: branchId);
});

/// Selected Staff ID Provider (for detail view)
final selectedStaffIdProvider = StateProvider<String?>((ref) => null);

/// Helper: Refresh all staff data
void refreshAllStaffData(WidgetRef ref, {String? branchId}) {
  ref.read(cachedAllStaffProvider(branchId).notifier).fetch();
  ref.read(cachedStaffStatsProvider(branchId).notifier).fetch();
}

/// Helper: Refresh staff list
void refreshStaffList(WidgetRef ref, {String? branchId}) {
  ref.read(cachedAllStaffProvider(branchId).notifier).fetch();
}

/// Helper: Refresh staff stats
void refreshStaffStats(WidgetRef ref, {String? branchId}) {
  ref.read(cachedStaffStatsProvider(branchId).notifier).fetch();
}

/// Helper: Refresh specific staff member
void refreshStaff(WidgetRef ref, String staffId) {
  ref.read(cachedStaffProvider(staffId).notifier).fetch();
}

/// Helper: Refresh staff by role
void refreshStaffByRole(WidgetRef ref, String role, {String? branchId}) {
  ref
      .read(
          cachedStaffByRoleProvider((role: role, branchId: branchId)).notifier)
      .fetch();
}
