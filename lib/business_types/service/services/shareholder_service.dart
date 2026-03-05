import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shareholder.dart';
import '../../../utils/app_logger.dart';

/// Service for managing shareholder data
class ShareholderService {
  final _supabase = Supabase.instance.client;

  /// Get shareholders for a company by year
  Future<List<Shareholder>> getShareholdersByYear({
    required String companyId,
    required int year,
  }) async {
    try {
      final response = await _supabase
          .from('company_shareholders')
          .select()
          .eq('company_id', companyId)
          .eq('year', year)
          .order('ownership_percentage', ascending: false);

      return (response as List)
          .map((json) => Shareholder.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching shareholders', e);
      return [];
    }
  }

  /// Get all shareholders history for a company (all years)
  Future<Map<int, List<Shareholder>>> getShareholdersHistory({
    required String companyId,
  }) async {
    try {
      final response = await _supabase
          .from('company_shareholders')
          .select()
          .eq('company_id', companyId)
          .order('year', ascending: false)
          .order('ownership_percentage', ascending: false);

      final shareholders = (response as List)
          .map((json) => Shareholder.fromJson(json))
          .toList();

      // Group by year
      final Map<int, List<Shareholder>> result = {};
      for (final sh in shareholders) {
        result.putIfAbsent(sh.year, () => []);
        result[sh.year]!.add(sh);
      }
      return result;
    } catch (e) {
      AppLogger.error('Error fetching shareholders history', e);
      return {};
    }
  }

  /// Get latest year shareholders
  Future<List<Shareholder>> getLatestShareholders({
    required String companyId,
  }) async {
    try {
      // First, get the max year
      final yearResponse = await _supabase
          .from('company_shareholders')
          .select('year')
          .eq('company_id', companyId)
          .order('year', ascending: false)
          .limit(1);

      if (yearResponse.isEmpty) return [];

      final latestYear = yearResponse[0]['year'] as int;

      // Then get all shareholders for that year
      return await getShareholdersByYear(
        companyId: companyId,
        year: latestYear,
      );
    } catch (e) {
      AppLogger.error('Error fetching latest shareholders', e);
      return [];
    }
  }

  /// Get shareholder summary with year-over-year changes
  Future<Map<String, dynamic>> getShareholderSummary({
    required String companyId,
  }) async {
    try {
      final history = await getShareholdersHistory(companyId: companyId);
      
      if (history.isEmpty) {
        return {
          'hasData': false,
          'shareholders': <Shareholder>[],
          'years': <int>[],
        };
      }

      final years = history.keys.toList()..sort((a, b) => b.compareTo(a));
      final latestYear = years.first;
      final latestShareholders = history[latestYear] ?? [];

      // Calculate total investment
      double totalInvestment = 0;
      double totalDepreciation = 0;
      for (final sh in latestShareholders) {
        totalInvestment += sh.cashInvested;
        totalDepreciation += sh.depreciation;
      }

      // Calculate year-over-year changes if we have previous year data
      List<Map<String, dynamic>> shareholderChanges = [];
      final previousYear = years.length > 1 ? years[1] : null;
      
      for (final sh in latestShareholders) {
        double previousPct = 0;
        if (previousYear != null) {
          final prevShareholder = history[previousYear]?.firstWhere(
            (p) => p.shareholderName == sh.shareholderName,
            orElse: () => Shareholder(
              id: '',
              companyId: companyId,
              shareholderName: sh.shareholderName,
              cashInvested: 0,
              ownershipPercentage: 0,
              year: previousYear,
            ),
          );
          previousPct = prevShareholder?.ownershipPercentage ?? 0;
        }

        shareholderChanges.add({
          'name': sh.shareholderName,
          'cashInvested': sh.cashInvested,
          'currentPct': sh.ownershipPercentage,
          'previousPct': previousPct,
          'change': sh.ownershipPercentage - previousPct,
          'depreciation': sh.depreciation,
          'notes': sh.notes,
        });
      }

      return {
        'hasData': true,
        'latestYear': latestYear,
        'previousYear': previousYear,
        'shareholders': latestShareholders,
        'shareholderChanges': shareholderChanges,
        'totalInvestment': totalInvestment,
        'totalDepreciation': totalDepreciation,
        'years': years,
        'history': history,
      };
    } catch (e) {
      AppLogger.error('Error getting shareholder summary', e);
      return {
        'hasData': false,
        'shareholders': <Shareholder>[],
        'years': <int>[],
      };
    }
  }
}
