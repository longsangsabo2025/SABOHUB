import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/monthly_pnl.dart';
import '../services/monthly_pnl_service.dart';

/// Monthly P&L Service Provider (singleton)
final monthlyPnlServiceProvider = Provider<MonthlyPnlService>((ref) {
  return MonthlyPnlService();
});

/// Financial summary provider for a given company
/// Returns aggregated financial dashboarddata
final financialSummaryProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, companyId) async {
    final service = ref.watch(monthlyPnlServiceProvider);
    return await service.getFinancialSummary(companyId: companyId);
  },
);

/// P&L history provider (latest 12 months)
final pnlHistoryProvider =
    FutureProvider.autoDispose.family<List<MonthlyPnl>, String>(
  (ref, companyId) async {
    final service = ref.watch(monthlyPnlServiceProvider);
    return await service.getPnlHistory(companyId: companyId, limit: 12);
  },
);

/// P&L by year provider
final pnlByYearProvider =
    FutureProvider.autoDispose.family<List<MonthlyPnl>, ({String companyId, int year})>(
  (ref, params) async {
    final service = ref.watch(monthlyPnlServiceProvider);
    return await service.getPnlByYear(
      companyId: params.companyId,
      year: params.year,
    );
  },
);

/// Latest P&L record provider
final latestPnlProvider =
    FutureProvider.autoDispose.family<MonthlyPnl?, String>(
  (ref, companyId) async {
    final service = ref.watch(monthlyPnlServiceProvider);
    return await service.getLatestPnl(companyId: companyId);
  },
);
