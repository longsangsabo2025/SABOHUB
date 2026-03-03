import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import '../services/analytics_tracking_service.dart';
import 'auth_provider.dart';

/// Analytics Service Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Dashboard KPIs Provider
/// Fetches key performance indicators for CEO dashboard
final dashboardKPIsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getDashboardKPIs();
});

/// Revenue by Period Provider
/// Fetches revenue data for charts based on selected period
final revenueByPeriodProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, period) async {
    final service = ref.watch(analyticsServiceProvider);
    return await service.getRevenueByPeriod(period: period);
  },
);

/// Company Performance Provider
/// Fetches performance metrics for all companies
final companyPerformanceProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getCompanyPerformance();
});

/// Activity Log Provider
/// Fetches recent system activities
final activityLogProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, limit) async {
    final service = ref.watch(analyticsServiceProvider);
    return await service.getActivityLog(limit: limit);
  },
);

/// Customer Analytics Provider
/// Fetches customer-related metrics
final customerAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getCustomerAnalytics();
});

/// Selected Period Provider
/// State provider for selected analytics period
final selectedPeriodProvider =
    NotifierProvider<_SelectedPeriodNotifier, String>(
        () => _SelectedPeriodNotifier());

class _SelectedPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'month';

  void set(String period) {
    state = period;
  }
}

// =============================================================================
// Event Tracking Providers (analytics_events table)
// =============================================================================

/// Provider that auto-initializes analytics tracking with current user
final analyticsTrackingInitProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    analyticsTracking.setUser(
      userId: user.id,
      companyId: user.companyId ?? '',
    );
  } else {
    analyticsTracking.clearUser();
  }
});

/// Provider for CEO analytics event tracking summary
final analyticsTrackingSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, companyId) async {
    return analyticsTracking.getCompanySummary(companyId: companyId);
  },
);
