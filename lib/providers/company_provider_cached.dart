import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cached_provider.dart';
import '../models/store.dart';
import 'company_provider.dart';

// =============================================================================
// CACHED PROVIDERS - Facebook-style State Management
// =============================================================================
// These providers use local caching to prevent data reloading on tab switches.
// Data persists across navigation and refreshes intelligently in background.
// =============================================================================

/// Cached All Stores Provider (15-minute cache)
///
/// Use this instead of `storesProvider` for list views.
/// Benefits:
/// - Instant tab switches (no reload)
/// - Stale-while-revalidate pattern
/// - Pull-to-refresh support
///
/// Example:
/// ```dart
/// final storesAsync = ref.watch(cachedStoresProvider);
/// storesAsync.when(
///   data: (cachedData) {
///     final stores = cachedData.data;
///     // Use stores...
///   },
/// )
/// ```
final cachedStoresProvider = StateNotifierProvider<
    CachedStateNotifier<List<Store>>,
    AsyncValue<CachedData<List<Store>>>>((ref) {
  final service = ref.watch(storeServiceProvider);

  final notifier = CachedStateNotifier<List<Store>>(
    fetchData: () => service.getAllStores(),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

/// Cached Single Store Provider (15-minute cache)
///
/// Use this instead of `storeProvider` for detail views.
/// Maintains a cache per store ID.
///
/// Example:
/// ```dart
/// final storeAsync = ref.watch(cachedStoreProvider(storeId));
/// ```
final cachedStoreProvider = StateNotifierProvider.family<
    CachedStateNotifier<Store?>,
    AsyncValue<CachedData<Store?>>,
    String>((ref, storeId) {
  final service = ref.watch(storeServiceProvider);

  final notifier = CachedStateNotifier<Store?>(
    fetchData: () => service.getStoreById(storeId),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

/// Cached Store Stats Provider (5-minute cache)
///
/// Stats change more frequently, so use shorter cache.
///
/// Example:
/// ```dart
/// final statsAsync = ref.watch(cachedStoreStatsProvider(storeId));
/// ```
final cachedStoreStatsProvider = StateNotifierProvider.family<
    CachedStateNotifier<Map<String, dynamic>>,
    AsyncValue<CachedData<Map<String, dynamic>>>,
    String>((ref, storeId) {
  final service = ref.watch(storeServiceProvider);

  final notifier = CachedStateNotifier<Map<String, dynamic>>(
    fetchData: () => service.getStoreStats(storeId),
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

/// Refresh all stores (call after create/update/delete operations)
///
/// Example:
/// ```dart
/// await storeService.createStore(newStore);
/// refreshStores(ref); // Immediately refresh the list
/// ```
void refreshStores(WidgetRef ref) {
  ref.read(cachedStoresProvider.notifier).refresh();
}

/// Refresh a specific store (call after update operation)
///
/// Example:
/// ```dart
/// await storeService.updateStore(storeId, updates);
/// refreshStore(ref, storeId);
/// ```
void refreshStore(WidgetRef ref, String storeId) {
  ref.read(cachedStoreProvider(storeId).notifier).refresh();
}

/// Force invalidate all stores (clears cache, forces reload)
///
/// Use sparingly - prefer refresh() which keeps old data while loading.
///
/// Example:
/// ```dart
/// invalidateStores(ref); // Nuclear option
/// ```
void invalidateStores(WidgetRef ref) {
  ref.read(cachedStoresProvider.notifier).invalidate();
}

/// Refresh store stats
void refreshStoreStats(WidgetRef ref, String storeId) {
  ref.read(cachedStoreStatsProvider(storeId).notifier).refresh();
}
