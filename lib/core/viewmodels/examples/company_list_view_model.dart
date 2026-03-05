/// Example: Company List ViewModel
///
/// ĐÂY LÀ TEMPLATE cho tất cả ViewModels trong project.
/// Copy pattern này khi tạo ViewModel mới cho bất kỳ feature nào.
///
/// Architecture: View → ViewModel → Service (→ Repository khi có)
///
/// Rules:
/// - ❌ KHÔNG import 'package:flutter/material.dart'
/// - ❌ KHÔNG reference Widget, BuildContext, Navigator
/// - ✅ Chỉ business logic + state management
/// - ✅ 1 View ↔ 1 ViewModel
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/result.dart';
import '../base_view_model.dart';
import '../../../models/company.dart';
import '../../../services/company_service.dart';
import '../../../providers/auth_provider.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Immutable state cho Company List screen.
///
/// Dùng copyWith() để tạo state mới — KHÔNG mutate trực tiếp.
class CompanyListState {
  final List<Company> companies;
  final String? errorMessage;

  const CompanyListState({
    this.companies = const [],
    this.errorMessage,
  });

  CompanyListState copyWith({
    List<Company>? companies,
    String? errorMessage,
  }) {
    return CompanyListState(
      companies: companies ?? this.companies,
      errorMessage: errorMessage,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VIEWMODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// ViewModel cho Company List.
///
/// Extends [BaseViewModel] → auto-handles loading/error states.
/// Provider sẽ expose `AsyncValue<CompanyListState>` → View chỉ dùng `.when()`.
class CompanyListViewModel extends BaseViewModel<CompanyListState> {
  @override
  Future<CompanyListState> build() async {
    final service = ref.read(companyServiceProvider);
    final userId = ref.read(currentUserProvider)?.id;

    // Dùng .toResult() extension để wrap service call thành Result
    final result = await service.getMyCompanies(userId: userId).toResult();

    return result.when(
      success: (companies) => CompanyListState(companies: companies),
      failure: (error) => CompanyListState(errorMessage: error.userMessage),
    );
  }

  /// Refresh danh sách companies.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future; // Wait for rebuild to complete
  }

  /// Xóa company (soft delete).
  Future<bool> deleteCompany(String companyId) async {
    final service = ref.read(companyServiceProvider);

    // deleteCompany returns Future<void>, wrap in Result
    final result = await service.deleteCompany(companyId).toResult();

    return result.when(
      success: (_) {
        // Remove from local state immediately (optimistic update)
        final current = state.value;
        if (current != null) {
          state = AsyncData(current.copyWith(
            companies:
                current.companies.where((c) => c.id != companyId).toList(),
          ));
        }
        return true;
      },
      failure: (_) => false,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Service provider (reuse existing)
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

/// ViewModel provider — dùng trong View:
///
/// ```dart
/// class CompanyListView extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final state = ref.watch(companyListViewModelProvider);
///     return state.when(
///       data: (data) => ListView.builder(
///         itemCount: data.companies.length,
///         itemBuilder: (_, i) => CompanyCard(company: data.companies[i]),
///       ),
///       loading: () => const ShimmerLoading(),
///       error: (e, _) => ErrorDisplay(error: e, onRetry: () =>
///         ref.read(companyListViewModelProvider.notifier).refresh()),
///     );
///   }
/// }
/// ```
final companyListViewModelProvider =
    AsyncNotifierProvider<CompanyListViewModel, CompanyListState>(
  CompanyListViewModel.new,
);
