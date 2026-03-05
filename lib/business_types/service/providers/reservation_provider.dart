import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reservation.dart';
import '../services/reservation_service.dart';
import '../../../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════
// RESERVATION PROVIDERS — Riverpod 3.x patterns
// ═══════════════════════════════════════════════════════════════

/// Service provider — passes companyId from auth
final reservationServiceProvider = Provider<ReservationService>((ref) {
  final user = ref.watch(currentUserProvider);
  return ReservationService(companyId: user?.companyId);
});

/// ─── reservationListProvider ──────────────────────────
/// Fetches reservations by date (default: today)
final reservationListProvider =
    FutureProvider.autoDispose.family<List<Reservation>, DateTime>(
  (ref, date) async {
    final service = ref.read(reservationServiceProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return service.getByDate(date);
  },
);

/// ─── upcomingReservationsProvider ─────────────────────
/// Next 24 hours, pending or confirmed
final upcomingReservationsProvider =
    FutureProvider.autoDispose<List<Reservation>>(
  (ref) async {
    final service = ref.read(reservationServiceProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return service.getUpcoming();
  },
);

/// ─── reservationsByTableProvider ──────────────────────
/// For table-specific view
final reservationsByTableProvider =
    FutureProvider.autoDispose.family<List<Reservation>, String>(
  (ref, tableId) async {
    final service = ref.read(reservationServiceProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return service.getByTable(tableId);
  },
);

/// ─── reservationStatsProvider ─────────────────────────
final reservationStatsProvider =
    FutureProvider.autoDispose<ReservationStats>(
  (ref) async {
    final service = ref.read(reservationServiceProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return ReservationStats.empty();
    return service.getStats();
  },
);

/// ─── ReservationActions ──────────────────────────────
/// Handles mutations and invalidation
class ReservationActions {
  final Ref _ref;
  ReservationActions(this._ref);

  ReservationService get _service => _ref.read(reservationServiceProvider);

  Future<Reservation> create(Reservation reservation) async {
    final created = await _service.createReservation(reservation);
    _invalidate();
    return created;
  }

  Future<Reservation> confirm(String id) async {
    final r = await _service.confirmReservation(id);
    _invalidate();
    return r;
  }

  Future<Reservation> checkIn(String id) async {
    final r = await _service.checkInReservation(id);
    _invalidate();
    return r;
  }

  Future<Reservation> complete(String id) async {
    final r = await _service.completeReservation(id);
    _invalidate();
    return r;
  }

  Future<Reservation> cancel(String id, {String? reason}) async {
    final r = await _service.cancelReservation(id, reason: reason);
    _invalidate();
    return r;
  }

  Future<Reservation> update(
      String id, Map<String, dynamic> updates) async {
    final r = await _service.updateReservation(id, updates);
    _invalidate();
    return r;
  }

  Future<int> autoMarkNoShow() async {
    final count = await _service.autoMarkNoShow();
    if (count > 0) _invalidate();
    return count;
  }

  Future<bool> isDoubleBooked({
    required String tableId,
    required DateTime date,
    required TimeOfDay startTime,
    required int durationMinutes,
    String? excludeReservationId,
  }) {
    return _service.isDoubleBooked(
      tableId: tableId,
      date: date,
      startTime: startTime,
      durationMinutes: durationMinutes,
      excludeReservationId: excludeReservationId,
    );
  }

  void _invalidate() {
    _ref.invalidate(upcomingReservationsProvider);
    _ref.invalidate(reservationStatsProvider);
    // Note: reservationListProvider(date) will be invalidated when the page refreshes
  }
}

final reservationActionsProvider =
    Provider<ReservationActions>((ref) => ReservationActions(ref));
