import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/referral_model.dart';
import '../services/referral_service.dart';
import 'auth_provider.dart';

// ──────────────────────────────────────────────
// Service Provider
// ──────────────────────────────────────────────

final referralServiceProvider = Provider<ReferralService>(
  (ref) => ReferralService(),
);

// ──────────────────────────────────────────────
// Referral List State
// ──────────────────────────────────────────────

class ReferralListState {
  final List<Referral> referrals;
  final bool isLoading;
  final String? error;

  const ReferralListState({
    this.referrals = const [],
    this.isLoading = false,
    this.error,
  });

  ReferralListState copyWith({
    List<Referral>? referrals,
    bool? isLoading,
    String? error,
  }) {
    return ReferralListState(
      referrals: referrals ?? this.referrals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ──────────────────────────────────────────────
// Referral List Notifier
// ──────────────────────────────────────────────

class ReferralListNotifier extends Notifier<ReferralListState> {
  @override
  ReferralListState build() {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      Future.microtask(() => loadReferrals());
    }
    return const ReferralListState(isLoading: true);
  }

  ReferralService get _service => ref.read(referralServiceProvider);
  String? get _userId => ref.read(currentUserProvider)?.id;
  String? get _userName => ref.read(currentUserProvider)?.name;
  String? get _companyId => ref.read(currentUserProvider)?.companyId;

  /// Load referrals for current user.
  Future<void> loadReferrals() async {
    final userId = _userId;
    if (userId == null) {
      state = const ReferralListState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final referrals = await _service.getMyReferrals(userId);
      state = ReferralListState(referrals: referrals, isLoading: false);
    } catch (e) {
      state = ReferralListState(error: e.toString(), isLoading: false);
    }
  }

  /// Create a new referral.
  Future<bool> createReferral({
    required String refereeName,
    required String refereePhone,
    required String refereeEmail,
    String? position,
    String? note,
    int rewardAmount = 50,
  }) async {
    final userId = _userId;
    final userName = _userName;
    final companyId = _companyId;
    if (userId == null || userName == null) return false;

    try {
      await _service.createReferral(
        referrerId: userId,
        referrerName: userName,
        refereeName: refereeName,
        refereePhone: refereePhone,
        refereeEmail: refereeEmail,
        position: position,
        companyId: companyId,
        note: note,
        rewardAmount: rewardAmount,
      );
      await loadReferrals();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update referral status (accept / reject).
  Future<bool> updateStatus(String referralId, ReferralStatus status) async {
    try {
      await _service.updateReferralStatus(referralId, status);
      await loadReferrals();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final referralListProvider =
    NotifierProvider<ReferralListNotifier, ReferralListState>(
  () => ReferralListNotifier(),
);

// ──────────────────────────────────────────────
// Referral Stats Provider
// ──────────────────────────────────────────────

final referralStatsProvider = FutureProvider.autoDispose<ReferralStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return ReferralStats.empty();

  final service = ref.read(referralServiceProvider);
  return service.getReferralStats(user.id);
});
