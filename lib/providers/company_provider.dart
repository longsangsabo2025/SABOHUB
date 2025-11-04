import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company.dart';
import '../services/company_service.dart';

/// Company Service Provider
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

/// All Companies Provider
/// Fetches and caches all companies from Supabase
final companiesProvider = FutureProvider<List<Company>>((ref) async {
  final service = ref.watch(companyServiceProvider);
  return await service.getAllCompanies();
});

/// Single Company Provider
/// Gets a specific company by ID
final companyProvider =
    FutureProvider.family<Company?, String>((ref, id) async {
  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyById(id);
});

/// Company Stats Provider
/// Fetches company statistics (employees, branches, tables, revenue)
final companyStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, companyId) async {
  final service = ref.watch(companyServiceProvider);
  return await service.getCompanyStats(companyId);
});

/// Companies Stream Provider
/// Real-time stream of companies
final companiesStreamProvider = StreamProvider<List<Company>>((ref) {
  final service = ref.watch(companyServiceProvider);
  return service.subscribeToCompanies();
});

/// Selected Company Provider (for multi-company scenarios)
/// Use ref.read(selectedCompanyProvider.notifier).state = value to update
final selectedCompanyProvider = Provider<String?>((ref) => null);
