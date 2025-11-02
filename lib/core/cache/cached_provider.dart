import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cached State Manager
/// Provides persistent caching for data across tab switches
/// Prevents unnecessary reloads like Facebook/Instagram

/// Cache Duration Configuration
class CacheConfig {
  static const Duration short =
      Duration(minutes: 5); // For frequently changing data
  static const Duration medium =
      Duration(minutes: 15); // For moderately stable data
  static const Duration long = Duration(hours: 1); // For rarely changing data
  static const Duration persistent = Duration(days: 1); // For very stable data
}

/// Cached Data Wrapper
/// Tracks when data was last fetched
class CachedData<T> {
  final T data;
  final DateTime cachedAt;
  final Duration cacheDuration;

  CachedData({
    required this.data,
    required this.cacheDuration,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  /// Check if cache is still valid
  bool get isValid {
    final age = DateTime.now().difference(cachedAt);
    return age < cacheDuration;
  }

  /// Get age of cache in human readable format
  String get ageDescription {
    final age = DateTime.now().difference(cachedAt);
    if (age.inSeconds < 60) return '${age.inSeconds}s ago';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  /// Create a refreshed copy
  CachedData<T> refresh(T newData) {
    return CachedData(
      data: newData,
      cacheDuration: cacheDuration,
    );
  }
}

/// Generic Cached Provider State Notifier
/// Manages cached data with automatic refresh logic
class CachedStateNotifier<T> extends StateNotifier<AsyncValue<CachedData<T>>> {
  final Future<T> Function() _fetchData;
  final Duration _cacheDuration;

  CachedStateNotifier({
    required Future<T> Function() fetchData,
    required Duration cacheDuration,
  })  : _fetchData = fetchData,
        _cacheDuration = cacheDuration,
        super(const AsyncValue.loading());

  /// Initial fetch or force refresh
  Future<void> fetch({bool forceRefresh = false}) async {
    // If we have valid cached data and not forcing refresh, keep it
    if (!forceRefresh) {
      state.whenData((cachedData) {
        if (cachedData.isValid) {
          // Cache is still valid, keep showing it
          return;
        }
      });
    }

    // Start fetching new data
    state = const AsyncValue.loading();

    try {
      final data = await _fetchData();
      state = AsyncValue.data(
        CachedData(
          data: data,
          cacheDuration: _cacheDuration,
        ),
      );
    } catch (error, stackTrace) {
      // Keep old data if available, but show error
      state.whenData((oldData) {
        // We have old data, keep showing it
        state = AsyncValue.data(oldData);
      });

      // If no old data, show error
      if (state is! AsyncData) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Refresh data (shows loading while keeping old data visible)
  Future<void> refresh() async {
    // Get current data to show while refreshing
    final currentData = state.valueOrNull;

    try {
      final data = await _fetchData();
      state = AsyncValue.data(
        CachedData(
          data: data,
          cacheDuration: _cacheDuration,
        ),
      );
    } catch (error, stackTrace) {
      // If refresh fails, keep old data
      if (currentData != null) {
        state = AsyncValue.data(currentData);
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Invalidate cache and force refresh
  Future<void> invalidate() async {
    await fetch(forceRefresh: true);
  }
}

/// Cached Provider Factory
/// Creates cached providers with keepAlive - NO autoDispose
typedef CachedProvider<T>
    = StateNotifierProvider<CachedStateNotifier<T>, AsyncValue<CachedData<T>>>;

CachedProvider<T> createCachedProvider<T>({
  required Future<T> Function() fetch,
  required Duration cacheDuration,
  String? name,
}) {
  return StateNotifierProvider<CachedStateNotifier<T>,
      AsyncValue<CachedData<T>>>(
    (ref) {
      final notifier = CachedStateNotifier<T>(
        fetchData: fetch,
        cacheDuration: cacheDuration,
      );

      // Start initial fetch
      notifier.fetch();

      return notifier;
    },
  );
}

/// Cached Family Provider with KeepAlive
/// Family providers that cache data per parameter
typedef CachedFamilyProvider<T, Param> = AutoDisposeStateNotifierProviderFamily<
    CachedStateNotifier<T>, AsyncValue<CachedData<T>>, Param>;

CachedFamilyProvider<T, Param> createCachedFamilyProvider<T, Param>({
  required Future<T> Function(Param) fetch,
  required Duration cacheDuration,
  String? name,
}) {
  return StateNotifierProvider.autoDispose
      .family<CachedStateNotifier<T>, AsyncValue<CachedData<T>>, Param>(
    (ref, param) {
      final notifier = CachedStateNotifier<T>(
        fetchData: () => fetch(param),
        cacheDuration: cacheDuration,
      );

      // IMPORTANT: Keep alive to prevent auto-dispose on tab switch
      ref.keepAlive();

      // Start initial fetch
      notifier.fetch();

      return notifier;
    },
  );
}

/// Extension to unwrap cached data
extension CachedDataExt<T> on AsyncValue<CachedData<T>> {
  /// Get the actual data, unwrapping from cache
  T? get dataOrNull => valueOrNull?.data;

  /// Get data with default
  T dataOr(T defaultValue) => valueOrNull?.data ?? defaultValue;

  /// Check if cache is valid
  bool get isCacheValid => valueOrNull?.isValid ?? false;

  /// Get cache age
  String get cacheAge => valueOrNull?.ageDescription ?? 'N/A';

  /// Map AsyncValue<CachedData<T>> to AsyncValue<T>
  AsyncValue<T> get unwrapped {
    return when(
      data: (cachedData) => AsyncValue.data(cachedData.data),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  }
}
