import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company.dart';
import '../utils/app_logger.dart';
import 'auth_provider.dart';
import 'company_provider.dart';

/// Notifier that holds the currently selected subsidiary for corporation CEO/Manager.
class SelectedSubsidiaryNotifier extends Notifier<Company?> {
  @override
  Company? build() => null;

  void select(Company? company) {
    state = company;
  }

  void clear() {
    state = null;
  }
}

/// Provider that holds the currently selected subsidiary for corporation CEO/Manager.
/// When non-null, role_based_dashboard routes to that subsidiary's layout.
/// When null, default layout for the role is shown.
final selectedSubsidiaryProvider =
    NotifierProvider<SelectedSubsidiaryNotifier, Company?>(
  () => SelectedSubsidiaryNotifier(),
);

/// Accessible companies for the current user.
/// - CEO: fetches via [companiesProvider] (by owner_id/created_by)
/// - Manager (corporation): fetches ONLY subsidiaries belonging to the same corporation group
///   (matched by owner_id/created_by of the corporation the manager belongs to)
/// - Others: returns empty (no company switching allowed)
final accessibleCompaniesProvider =
    FutureProvider.autoDispose<List<Company>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return [];

  final role = user.role;
  final businessType = user.businessType;

  // CEO always uses companiesProvider (already scoped by owner)
  if (role.toString().contains('ceo')) {
    final ceoCompanies = ref.watch(companiesProvider);
    return ceoCompanies.when(
      data: (list) => list,
      loading: () => <Company>[],
      error: (_, __) => <Company>[],
    );
  }

  // Manager under corporation → fetch ONLY companies in the same corporation group
  // Security: We find the corporation's owner_id, then only show companies
  // that share that owner_id. This prevents managers from seeing companies
  // belonging to other corporations/groups.
  if (role.toString().contains('manager') &&
      businessType != null &&
      businessType.isCorporation) {
    try {
      final supabase = Supabase.instance.client;
      final corpId = user.companyId;
      if (corpId == null) return [];

      // Step 1: Get the corporation to find its owner_id
      final corpResponse = await supabase
          .from('companies')
          .select('owner_id, created_by')
          .eq('id', corpId)
          .maybeSingle();

      if (corpResponse == null) return [];

      final ownerId = corpResponse['owner_id'] as String?;
      final createdBy = corpResponse['created_by'] as String?;

      // Build OR filter to find all companies in the same group
      final filters = <String>[];
      if (ownerId != null) {
        filters.add('owner_id.eq.$ownerId');
        filters.add('created_by.eq.$ownerId');
      }
      if (createdBy != null && createdBy != ownerId) {
        filters.add('owner_id.eq.$createdBy');
        filters.add('created_by.eq.$createdBy');
      }

      if (filters.isEmpty) return [];

      // Step 2: Fetch only companies belonging to the same owner/creator
      final response = await supabase
          .from('companies')
          .select('*')
          .or(filters.join(','))
          .isFilter('deleted_at', null)
          .order('name', ascending: true);

      final companies = (response as List)
          .map((json) => Company.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info(
        'accessibleCompaniesProvider',
        'Manager ${user.name} (corp: $corpId) → found ${companies.length} group companies',
      );

      return companies;
    } catch (e) {
      AppLogger.error('accessibleCompaniesProvider', e);
      return [];
    }
  }

  return [];
});
