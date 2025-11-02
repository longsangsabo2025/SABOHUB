import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cached_provider.dart';
import 'analytics_provider.dart';

// =============================================================================
// CACHED ANALYTICS PROVIDERS - Facebook-style State Management
// =============================================================================
// Analytics data changes frequently (real-time metrics)
// Use SHORT cache (5 minutes) for most providers
// =============================================================================

/// Cached Dashboard KPIs Provider (5-minute cache)
///
/// KPIs change frequently, so use short cache duration.
///
/// Example:
/// ```dart
/// final kpisAsync = ref.watch(cachedDashboardKPIsProvider);
/// ```
final cachedDashboardKPIsProvider = StateNotifierProvider<
    CachedStateNotifier<Map<String, dynamic>>,
    AsyncValue<CachedData<Map<String, dynamic>>>>((ref) {
  final service = ref.watch(analyticsServiceProvider);

  final notifier = CachedStateNotifier<Map<String, dynamic>>(
    fetchData: () => service.getDashboardKPIs(),
    cacheDuration: CacheConfig.short, // 5 minutes - real-time metrics
  );

  ref.keepAlive(); // Prevents disposal on tab switch
  notifier.fetch();

  return notifier;
});

/// Cached Revenue by Period Provider (5-minute cache)
///
/// Revenue charts need fresh data but can cache briefly.
/// Maintains separate cache per period (day/week/month/year).
///
/// Example:
/// ```dart
/// final revenueAsync = ref.watch(cachedRevenueByPeriodProvider('month'));
/// ```
final cachedRevenueByPeriodProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Map<String, dynamic>>>,
    AsyncValue<CachedData<List<Map<String, dynamic>>>>,
    String>((ref, period) {
  final service = ref.watch(analyticsServiceProvider);

  final notifier = CachedStateNotifier<List<Map<String, dynamic>>>(
    fetchData: () => service.getRevenueByPeriod(period: period),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

/// Cached Company Performance Provider (15-minute cache)
///
/// Company performance is more stable, can cache longer.
///
/// Example:
/// ```dart
/// final perfAsync = ref.watch(cachedCompanyPerformanceProvider);
/// ```
final cachedCompanyPerformanceProvider = StateNotifierProvider<
    CachedStateNotifier<List<Map<String, dynamic>>>,
    AsyncValue<CachedData<List<Map<String, dynamic>>>>>((ref) {
  final service = ref.watch(analyticsServiceProvider);

  final notifier = CachedStateNotifier<List<Map<String, dynamic>>>(
    fetchData: () => service.getCompanyPerformance(),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

/// Cached Activity Log Provider (5-minute cache)
///
/// Activity log needs to be relatively fresh.
/// Maintains separate cache per limit.
///
/// Example:
/// ```dart
/// final activitiesAsync = ref.watch(cachedActivityLogProvider(10));
/// ```
final cachedActivityLogProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Map<String, dynamic>>>,
    AsyncValue<CachedData<List<Map<String, dynamic>>>>,
    int>((ref, limit) {
  final service = ref.watch(analyticsServiceProvider);

  final notifier = CachedStateNotifier<List<Map<String, dynamic>>>(
    fetchData: () => service.getActivityLog(limit: limit),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

/// Cached Customer Analytics Provider (15-minute cache)
///
/// Customer metrics are moderately stable.
///
/// Example:
/// ```dart
/// final customerAsync = ref.watch(cachedCustomerAnalyticsProvider);
/// ```
final cachedCustomerAnalyticsProvider = StateNotifierProvider<
    CachedStateNotifier<Map<String, dynamic>>,
    AsyncValue<CachedData<Map<String, dynamic>>>>((ref) {
  final service = ref.watch(analyticsServiceProvider);

  final notifier = CachedStateNotifier<Map<String, dynamic>>(
    fetchData: () => service.getCustomerAnalytics(),
    cacheDuration: CacheConfig.medium, // 15 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/// Refresh dashboard KPIs
///
/// Call this after operations that affect metrics.
///
/// Example:
/// ```dart
/// await taskService.completeTask(taskId);
/// refreshDashboardKPIs(ref);
/// ```
void refreshDashboardKPIs(WidgetRef ref) {
  ref.read(cachedDashboardKPIsProvider.notifier).refresh();
}

/// Refresh revenue data for a specific period
void refreshRevenue(WidgetRef ref, String period) {
  ref.read(cachedRevenueByPeriodProvider(period).notifier).refresh();
}

/// Refresh company performance metrics
void refreshCompanyPerformance(WidgetRef ref) {
  ref.read(cachedCompanyPerformanceProvider.notifier).refresh();
}

/// Refresh activity log
void refreshActivityLog(WidgetRef ref, int limit) {
  ref.read(cachedActivityLogProvider(limit).notifier).refresh();
}

/// Refresh customer analytics
void refreshCustomerAnalytics(WidgetRef ref) {
  ref.read(cachedCustomerAnalyticsProvider.notifier).refresh();
}

/// Refresh all analytics (use sparingly - triggers multiple API calls)
void refreshAllAnalytics(WidgetRef ref) {
  refreshDashboardKPIs(ref);
  refreshCompanyPerformance(ref);
  refreshCustomerAnalytics(ref);
  // Activity log will auto-refresh based on usage
}
