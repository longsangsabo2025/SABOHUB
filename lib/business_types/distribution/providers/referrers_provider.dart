import 'package:flutter_riverpod/flutter_riverpod.dart';

// =====================================================================
// ReferrersFilterState + ReferrersFilterNotifier
// Extracted from _ReferrerListTab and _CommissionsTab setState vars.
// AutoDispose because it's page-scoped.
// =====================================================================

/// Filter state for the Referrer List tab
class ReferrerListFilterState {
  final String selectedStatus;
  final String searchQuery;

  const ReferrerListFilterState({
    this.selectedStatus = 'active',
    this.searchQuery = '',
  });

  ReferrerListFilterState copyWith({
    String? selectedStatus,
    String? searchQuery,
  }) {
    return ReferrerListFilterState(
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ReferrerListFilterNotifier
    extends Notifier<ReferrerListFilterState> {
  @override
  ReferrerListFilterState build() => const ReferrerListFilterState();

  void setStatusFilter(String value) =>
      state = state.copyWith(selectedStatus: value);

  void setSearchQuery(String value) =>
      state = state.copyWith(searchQuery: value);
}

final referrerListFilterProvider = NotifierProvider<
    ReferrerListFilterNotifier, ReferrerListFilterState>(
  ReferrerListFilterNotifier.new,
);

/// Filter state for the Commissions tab
class CommissionFilterState {
  final String selectedStatus;
  final String? selectedReferrerId;

  const CommissionFilterState({
    this.selectedStatus = 'pending',
    this.selectedReferrerId,
  });

  CommissionFilterState copyWith({
    String? selectedStatus,
    String? Function()? selectedReferrerId,
  }) {
    return CommissionFilterState(
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedReferrerId: selectedReferrerId != null
          ? selectedReferrerId()
          : this.selectedReferrerId,
    );
  }
}

class CommissionFilterNotifier
    extends Notifier<CommissionFilterState> {
  @override
  CommissionFilterState build() => const CommissionFilterState();

  void setStatusFilter(String value) =>
      state = state.copyWith(selectedStatus: value);

  void setSelectedReferrerId(String? value) =>
      state = state.copyWith(selectedReferrerId: () => value);
}

final commissionFilterProvider = NotifierProvider<
    CommissionFilterNotifier, CommissionFilterState>(
  CommissionFilterNotifier.new,
);
