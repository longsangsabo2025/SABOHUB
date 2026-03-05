import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shareholder.dart';
import '../services/shareholder_service.dart';

/// Shareholder Service Provider (singleton)
final shareholderServiceProvider = Provider<ShareholderService>((ref) {
  return ShareholderService();
});

/// Shareholder summary provider for a given company
/// Returns aggregated shareholder data with year-over-year changes
final shareholderSummaryProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, companyId) async {
    final service = ref.watch(shareholderServiceProvider);
    return await service.getShareholderSummary(companyId: companyId);
  },
);

/// Latest shareholders provider
final latestShareholdersProvider =
    FutureProvider.autoDispose.family<List<Shareholder>, String>(
  (ref, companyId) async {
    final service = ref.watch(shareholderServiceProvider);
    return await service.getLatestShareholders(companyId: companyId);
  },
);

/// Shareholders by year provider
final shareholdersByYearProvider = FutureProvider.autoDispose
    .family<List<Shareholder>, ({String companyId, int year})>(
  (ref, params) async {
    final service = ref.watch(shareholderServiceProvider);
    return await service.getShareholdersByYear(
      companyId: params.companyId,
      year: params.year,
    );
  },
);

/// Shareholders history provider (all years)
final shareholdersHistoryProvider = FutureProvider.autoDispose
    .family<Map<int, List<Shareholder>>, String>(
  (ref, companyId) async {
    final service = ref.watch(shareholderServiceProvider);
    return await service.getShareholdersHistory(companyId: companyId);
  },
);
