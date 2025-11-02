import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';

/// Analytics Service Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Dashboard KPIs Provider
/// Fetches key performance indicators for CEO dashboard
final dashboardKPIsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getDashboardKPIs();
});

/// Revenue by Period Provider
/// Fetches revenue data for charts based on selected period
final revenueByPeriodProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, period) async {
    final service = ref.watch(analyticsServiceProvider);
    return await service.getRevenueByPeriod(period: period);
  },
);

/// Company Performance Provider
/// Fetches performance metrics for all companies
final companyPerformanceProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getCompanyPerformance();
});

/// Activity Log Provider
/// Fetches recent system activities
final activityLogProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>(
  (ref, limit) async {
    final service = ref.watch(analyticsServiceProvider);
    return await service.getActivityLog(limit: limit);
  },
);

/// Customer Analytics Provider
/// Fetches customer-related metrics
final customerAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getCustomerAnalytics();
});

/// Selected Period Provider
/// State provider for selected analytics period
final selectedPeriodProvider = StateProvider<String>((ref) => 'month');
