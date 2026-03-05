import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reservation.dart';
import '../../../utils/app_logger.dart';

/// ═══════════════════════════════════════════════════════════════
/// RESERVATION SERVICE — CRUD cho hệ thống Đặt Bàn
/// ═══════════════════════════════════════════════════════════════
///
/// Strategy:
/// - Attempt Supabase `reservations` table first
/// - Gracefully fallback to in-memory list if table doesn't exist
/// - Auto-mark no_show for past unconfirmed reservations
///
/// ⚠️ EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!
/// Caller PHẢI truyền companyId từ authProvider.
class ReservationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String? companyId;

  ReservationService({this.companyId});

  // ── In-memory fallback storage ──
  static final List<Reservation> _localStore = [];
  static bool _useLocal = false;

  String _getCompanyId([String? override]) {
    final cid = override ?? companyId;
    if (cid == null) throw Exception('Company ID is required');
    return cid;
  }

  // ─────────────────────────────────────────────────────────────
  // CHECK TABLE EXISTS
  // ─────────────────────────────────────────────────────────────
  Future<bool> _checkTableExists() async {
    if (_useLocal) return false;
    try {
      await _supabase.from('reservations').select('id').limit(1);
      return true;
    } catch (e) {
      AppLogger.info('ReservationService: reservations table not found, using local store');
      _useLocal = true;
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────
  Future<Reservation> createReservation(Reservation reservation) async {
    try {
      final cid = _getCompanyId(reservation.companyId);
      final data = reservation.toJson();
      data['company_id'] = cid;

      final tableExists = await _checkTableExists();
      if (tableExists) {
        final response = await _supabase
            .from('reservations')
            .insert(data)
            .select()
            .single();
        AppLogger.info('ReservationService.create: OK (Supabase)');
        return Reservation.fromJson(response);
      } else {
        // Local fallback
        final now = DateTime.now();
        final local = reservation.copyWith(
          id: 'local_${now.millisecondsSinceEpoch}',
          companyId: cid,
          createdAt: now,
        );
        _localStore.add(local);
        AppLogger.info('ReservationService.create: OK (local)');
        return local;
      }
    } catch (e) {
      AppLogger.error('ReservationService.create', e);
      throw Exception('Không thể tạo đặt bàn: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────
  Future<Reservation> updateReservation(
      String id, Map<String, dynamic> updates) async {
    try {
      final tableExists = await _checkTableExists();
      if (tableExists) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        final response = await _supabase
            .from('reservations')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        AppLogger.info('ReservationService.update: $id OK');
        return Reservation.fromJson(response);
      } else {
        final idx = _localStore.indexWhere((r) => r.id == id);
        if (idx == -1) throw Exception('Reservation not found: $id');
        var r = _localStore[idx];
        r = r.copyWith(
          status: updates['status'] != null
              ? ReservationStatus.fromString(updates['status'])
              : null,
          customerName: updates['customer_name'] as String?,
          customerPhone: updates['customer_phone'] as String?,
          note: updates['note'] as String?,
          cancelReason: updates['cancel_reason'] as String?,
          updatedAt: DateTime.now(),
        );
        _localStore[idx] = r;
        AppLogger.info('ReservationService.update: $id OK (local)');
        return r;
      }
    } catch (e) {
      AppLogger.error('ReservationService.update', e);
      throw Exception('Không thể cập nhật đặt bàn: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────────────────────
  Future<Reservation> cancelReservation(String id, {String? reason}) async {
    return updateReservation(id, {
      'status': ReservationStatus.cancelled.value,
      'cancel_reason': reason ?? 'Hủy bởi quản lý',
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CONFIRM
  // ─────────────────────────────────────────────────────────────
  Future<Reservation> confirmReservation(String id) async {
    return updateReservation(id, {
      'status': ReservationStatus.confirmed.value,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CHECK-IN (Seat)
  // ─────────────────────────────────────────────────────────────
  Future<Reservation> checkInReservation(String id) async {
    return updateReservation(id, {
      'status': ReservationStatus.checkedIn.value,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // COMPLETE
  // ─────────────────────────────────────────────────────────────
  Future<Reservation> completeReservation(String id) async {
    return updateReservation(id, {
      'status': ReservationStatus.completed.value,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // GET BY DATE (single day)
  // ─────────────────────────────────────────────────────────────
  Future<List<Reservation>> getByDate(DateTime date,
      {String? overrideCompanyId}) async {
    try {
      final cid = _getCompanyId(overrideCompanyId);
      final dateStr = _dateStr(date);

      final tableExists = await _checkTableExists();
      if (tableExists) {
        final response = await _supabase
            .from('reservations')
            .select()
            .eq('company_id', cid)
            .eq('reservation_date', dateStr)
            .order('start_time', ascending: true)
            .limit(200);
        return (response as List)
            .map((j) => Reservation.fromJson(j))
            .toList();
      } else {
        return _localStore
            .where((r) =>
                r.companyId == cid && _dateStr(r.reservationDate) == dateStr)
            .toList()
          ..sort((a, b) => a.startTimeFormatted.compareTo(b.startTimeFormatted));
      }
    } catch (e) {
      AppLogger.error('ReservationService.getByDate', e);
      throw Exception('Không thể tải đặt bàn: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GET BY DATE RANGE
  // ─────────────────────────────────────────────────────────────
  Future<List<Reservation>> getByDateRange(DateTime from, DateTime to,
      {String? overrideCompanyId}) async {
    try {
      final cid = _getCompanyId(overrideCompanyId);

      final tableExists = await _checkTableExists();
      if (tableExists) {
        final response = await _supabase
            .from('reservations')
            .select()
            .eq('company_id', cid)
            .gte('reservation_date', _dateStr(from))
            .lte('reservation_date', _dateStr(to))
            .order('reservation_date', ascending: true)
            .order('start_time', ascending: true)
            .limit(500);
        return (response as List)
            .map((j) => Reservation.fromJson(j))
            .toList();
      } else {
        final fromD = DateTime(from.year, from.month, from.day);
        final toD = DateTime(to.year, to.month, to.day, 23, 59, 59);
        return _localStore
            .where((r) =>
                r.companyId == cid &&
                !r.reservationDate.isBefore(fromD) &&
                !r.reservationDate.isAfter(toD))
            .toList()
          ..sort((a, b) {
            final dc = a.reservationDate.compareTo(b.reservationDate);
            return dc != 0
                ? dc
                : a.startTimeFormatted.compareTo(b.startTimeFormatted);
          });
      }
    } catch (e) {
      AppLogger.error('ReservationService.getByDateRange', e);
      throw Exception('Không thể tải đặt bàn: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GET BY TABLE
  // ─────────────────────────────────────────────────────────────
  Future<List<Reservation>> getByTable(String tableId,
      {String? overrideCompanyId}) async {
    try {
      final cid = _getCompanyId(overrideCompanyId);

      final tableExists = await _checkTableExists();
      if (tableExists) {
        final response = await _supabase
            .from('reservations')
            .select()
            .eq('company_id', cid)
            .eq('table_or_room_id', tableId)
            .order('reservation_date', ascending: false)
            .limit(100);
        return (response as List)
            .map((j) => Reservation.fromJson(j))
            .toList();
      } else {
        return _localStore
            .where((r) => r.companyId == cid && r.tableOrRoomId == tableId)
            .toList();
      }
    } catch (e) {
      AppLogger.error('ReservationService.getByTable', e);
      throw Exception('Không thể tải đặt bàn theo bàn: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GET UPCOMING (next 24 hours)
  // ─────────────────────────────────────────────────────────────
  Future<List<Reservation>> getUpcoming({String? overrideCompanyId}) async {
    try {
      final cid = _getCompanyId(overrideCompanyId);
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(hours: 24));

      final tableExists = await _checkTableExists();
      if (tableExists) {
        final response = await _supabase
            .from('reservations')
            .select()
            .eq('company_id', cid)
            .gte('reservation_date', _dateStr(now))
            .lte('reservation_date', _dateStr(tomorrow))
            .inFilter('status', ['pending', 'confirmed'])
            .order('reservation_date', ascending: true)
            .order('start_time', ascending: true)
            .limit(100);
        final list = (response as List)
            .map((j) => Reservation.fromJson(j))
            .toList();
        // Filter: only upcoming start times
        return list.where((r) => r.startDateTime.isAfter(now)).toList();
      } else {
        return _localStore
            .where((r) =>
                r.companyId == cid &&
                r.startDateTime.isAfter(now) &&
                r.startDateTime.isBefore(tomorrow) &&
                (r.status == ReservationStatus.pending ||
                    r.status == ReservationStatus.confirmed))
            .toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      }
    } catch (e) {
      AppLogger.error('ReservationService.getUpcoming', e);
      throw Exception('Không thể tải đặt bàn sắp tới: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // AUTO MARK NO-SHOW
  // ─────────────────────────────────────────────────────────────
  /// Marks reservations as no_show if past start time + 30 min and still pending/confirmed
  Future<int> autoMarkNoShow({String? overrideCompanyId}) async {
    try {
      final cid = _getCompanyId(overrideCompanyId);
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(minutes: 30));
      int count = 0;

      final todayReservations = await getByDate(now, overrideCompanyId: cid);
      for (final r in todayReservations) {
        if ((r.status == ReservationStatus.pending ||
                r.status == ReservationStatus.confirmed) &&
            r.startDateTime.isBefore(cutoff)) {
          await updateReservation(r.id, {
            'status': ReservationStatus.noShow.value,
          });
          count++;
        }
      }

      if (count > 0) {
        AppLogger.info('ReservationService.autoMarkNoShow: $count marked');
      }
      return count;
    } catch (e) {
      AppLogger.error('ReservationService.autoMarkNoShow', e);
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CHECK DOUBLE BOOKING
  // ─────────────────────────────────────────────────────────────
  /// Returns true if the table/time slot is already booked
  Future<bool> isDoubleBooked({
    required String tableId,
    required DateTime date,
    required TimeOfDay startTime,
    required int durationMinutes,
    String? excludeReservationId,
    String? overrideCompanyId,
  }) async {
    try {
      final reservations =
          await getByDate(date, overrideCompanyId: overrideCompanyId);
      final newStart = DateTime(
          date.year, date.month, date.day, startTime.hour, startTime.minute);
      final newEnd = newStart.add(Duration(minutes: durationMinutes));

      for (final r in reservations) {
        if (r.tableOrRoomId != tableId) continue;
        if (excludeReservationId != null && r.id == excludeReservationId) {
          continue;
        }
        if (r.status == ReservationStatus.cancelled ||
            r.status == ReservationStatus.noShow) {
          continue;
        }

        final existStart = r.startDateTime;
        final existEnd = r.endDateTime;

        // Overlap check: newStart < existEnd && newEnd > existStart
        if (newStart.isBefore(existEnd) && newEnd.isAfter(existStart)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('ReservationService.isDoubleBooked', e);
      return false; // Assume not booked on error
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GET STATS
  // ─────────────────────────────────────────────────────────────
  Future<ReservationStats> getStats({String? overrideCompanyId}) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final all = await getByDateRange(weekStart, now,
          overrideCompanyId: overrideCompanyId);
      return ReservationStats.fromReservations(all);
    } catch (e) {
      AppLogger.error('ReservationService.getStats', e);
      return ReservationStats.empty();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────
  String _dateStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
