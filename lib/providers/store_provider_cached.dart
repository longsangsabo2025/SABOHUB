import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/store.dart';
import '../../services/store_service.dart';
import '../cache/cached_provider.dart';

/// ============================================================================
/// CACHED PROVIDERS - Data persists across tab switches (like Facebook)
/// ============================================================================

/// Store Service Provider (always available, no caching needed)
final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService();
});

/// All Stores Provider - CACHED
/// ✅ Data persists when switching tabs
/// ✅ Auto-refreshes after 15 minutes
/// ✅ Manual refresh available via pull-to-refresh
final cachedStoresProvider = StateNotifierProvider<
    CachedStateNotifier<List<Store>>,
    AsyncValue<CachedData<List<Store>>>>((ref) {
  final service = ref.watch(storeServiceProvider);

  final notifier = CachedStateNotifier<List<Store>>(
    fetchData: () => service.getAllStores(),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  // Start initial fetch
  notifier.fetch();

  return notifier;
});

/// Single Store Provider - CACHED per ID
/// Caches each store individually for quick access
final cachedStoreProvider = StateNotifierProvider.autoDispose.family<
    CachedStateNotifier<Store?>, AsyncValue<CachedData<Store?>>, String>(
  (ref, id) {
    final service = ref.watch(storeServiceProvider);

    final notifier = CachedStateNotifier<Store?>(
      fetchData: () => service.getStoreById(id),
      cacheDuration: CacheConfig.medium,
    );

    // IMPORTANT: Keep alive to prevent disposal on tab switch
    ref.keepAlive();

    notifier.fetch();
    return notifier;
  },
);

/// Store Stats Provider - CACHED per Store
/// Stats update less frequently, so longer cache
final cachedStoreStatsProvider = StateNotifierProvider.autoDispose.family<
    CachedStateNotifier<Map<String, dynamic>>,
    AsyncValue<CachedData<Map<String, dynamic>>>,
    String>(
  (ref, storeId) {
    final service = ref.watch(storeServiceProvider);

    final notifier = CachedStateNotifier<Map<String, dynamic>>(
      fetchData: () => service.getStoreStats(storeId),
      cacheDuration: CacheConfig.short, // 5 minutes for stats
    );

    ref.keepAlive();

    notifier.fetch();
    return notifier;
  },
);

/// ============================================================================
/// STREAM PROVIDERS - Real-time updates
/// These don't need caching as they're always connected
/// ============================================================================

/// Stores Stream Provider - Real-time updates
final storesStreamProvider = StreamProvider<List<Store>>((ref) {
  final service = ref.watch(storeServiceProvider);
  return service.subscribeToStores();
});

/// ============================================================================
/// STATE PROVIDERS - User selections
/// ============================================================================

/// Selected Store Provider
final selectedStoreIdProvider = StateProvider<String?>((ref) => null);

/// ============================================================================
/// UTILITY PROVIDERS - Helper functions
/// ============================================================================

/// Force refresh all stores
/// Call this after create/update/delete operations
void refreshStores(WidgetRef ref) {
  ref.read(cachedStoresProvider.notifier).refresh();
}

/// Force refresh specific store
void refreshStore(WidgetRef ref, String storeId) {
  ref.read(cachedStoreProvider(storeId).notifier).refresh();
  ref.read(cachedStoreStatsProvider(storeId).notifier).refresh();
}

/// Invalidate and force reload (use sparingly)
void invalidateStores(WidgetRef ref) {
  ref.read(cachedStoresProvider.notifier).invalidate();
}
