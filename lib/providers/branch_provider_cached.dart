import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cached_provider.dart';
import '../models/branch.dart';
import 'branch_provider.dart';

// =============================================================================
// CACHED BRANCH PROVIDERS - Facebook-style State Management
// =============================================================================

/// Cached All Branches Provider (15-minute cache)
///
/// Use this instead of `branchesProvider` for list views.
/// Maintains separate cache per company ID.
///
/// Example:
/// ```dart
/// final branchesAsync = ref.watch(cachedBranchesProvider(companyId));
/// ```
final cachedBranchesProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Branch>>,
    AsyncValue<CachedData<List<Branch>>>,
    String?>((ref, companyId) {
  final service = ref.watch(branchServiceProvider);

  final notifier = CachedStateNotifier<List<Branch>>(
    fetchData: () => service.getAllBranches(companyId: companyId),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

/// Cached Active Branches Provider (15-minute cache)
///
/// Filtered list of only active branches.
///
/// Example:
/// ```dart
/// final activeBranchesAsync = ref.watch(cachedActiveBranchesProvider(companyId));
/// ```
final cachedActiveBranchesProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Branch>>,
    AsyncValue<CachedData<List<Branch>>>,
    String?>((ref, companyId) {
  final service = ref.watch(branchServiceProvider);

  final notifier = CachedStateNotifier<List<Branch>>(
    fetchData: () => service.getActiveBranches(companyId: companyId),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

/// Cached Single Branch Provider (15-minute cache)
///
/// Use this instead of `branchProvider` for detail views.
///
/// Example:
/// ```dart
/// final branchAsync = ref.watch(cachedBranchProvider(branchId));
/// ```
final cachedBranchProvider = StateNotifierProvider.family<
    CachedStateNotifier<Branch?>,
    AsyncValue<CachedData<Branch?>>,
    String>((ref, branchId) {
  final service = ref.watch(branchServiceProvider);

  final notifier = CachedStateNotifier<Branch?>(
    fetchData: () => service.getBranchById(branchId),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

/// Cached Branch Stats Provider (5-minute cache)
///
/// Stats change more frequently, so use shorter cache.
///
/// Example:
/// ```dart
/// final statsAsync = ref.watch(cachedBranchStatsProvider(branchId));
/// ```
final cachedBranchStatsProvider = StateNotifierProvider.family<
    CachedStateNotifier<Map<String, dynamic>>,
    AsyncValue<CachedData<Map<String, dynamic>>>,
    String>((ref, branchId) {
  final service = ref.watch(branchServiceProvider);

  final notifier = CachedStateNotifier<Map<String, dynamic>>(
    fetchData: () => service.getBranchStats(branchId),
    cacheDuration: CacheConfig.short, // 5 minutes - stats change frequently
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/// Refresh all branches for a company
///
/// Example:
/// ```dart
/// await branchService.createBranch(newBranch);
/// refreshBranches(ref, companyId);
/// ```
void refreshBranches(WidgetRef ref, String? companyId) {
  ref.read(cachedBranchesProvider(companyId).notifier).refresh();
  ref.read(cachedActiveBranchesProvider(companyId).notifier).refresh();
}

/// Refresh a specific branch
///
/// Example:
/// ```dart
/// await branchService.updateBranch(branchId, updates);
/// refreshBranch(ref, branchId);
/// ```
void refreshBranch(WidgetRef ref, String branchId) {
  ref.read(cachedBranchProvider(branchId).notifier).refresh();
}

/// Refresh branch stats
void refreshBranchStats(WidgetRef ref, String branchId) {
  ref.read(cachedBranchStatsProvider(branchId).notifier).refresh();
}

/// Force invalidate all branches
void invalidateBranches(WidgetRef ref, String? companyId) {
  ref.read(cachedBranchesProvider(companyId).notifier).invalidate();
  ref.read(cachedActiveBranchesProvider(companyId).notifier).invalidate();
}
