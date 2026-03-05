import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// RESERVATION MODEL — Đặt Bàn / Đặt Phòng
// ═══════════════════════════════════════════════════════════════

enum ReservationType {
  table('table', 'Bàn', Icons.table_restaurant),
  room('room', 'Phòng', Icons.meeting_room),
  billiardTable('billiard', 'Bàn bi-da', Icons.sports),
  karaoke('karaoke', 'Phòng karaoke', Icons.mic);

  const ReservationType(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  static ReservationType fromString(String s) {
    return ReservationType.values.firstWhere(
      (e) => e.value == s || e.name == s,
      orElse: () => ReservationType.table,
    );
  }
}

enum ReservationStatus {
  pending('pending', 'Đang chờ', Colors.orange),
  confirmed('confirmed', 'Đã xác nhận', Colors.blue),
  checkedIn('checked_in', 'Đã đến', Colors.green),
  completed('completed', 'Hoàn thành', Colors.teal),
  cancelled('cancelled', 'Đã hủy', Colors.red),
  noShow('no_show', 'Không đến', Colors.grey);

  const ReservationStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static ReservationStatus fromString(String s) {
    return ReservationStatus.values.firstWhere(
      (e) => e.value == s || e.name == s,
      orElse: () => ReservationStatus.pending,
    );
  }
}

class Reservation {
  final String id;
  final String? companyId;
  final String? branchId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final ReservationType type;
  final ReservationStatus status;
  final DateTime reservationDate;
  final TimeOfDay startTime;
  final int durationMinutes;
  final int guestCount;
  final String? tableOrRoomId;
  final String? tableOrRoomName;
  final String? note;
  final String? cancelReason;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reservation({
    required this.id,
    this.companyId,
    this.branchId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.type,
    required this.status,
    required this.reservationDate,
    required this.startTime,
    this.durationMinutes = 60,
    this.guestCount = 1,
    this.tableOrRoomId,
    this.tableOrRoomName,
    this.note,
    this.cancelReason,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// Thời gian bắt đầu dạng DateTime
  DateTime get startDateTime => DateTime(
        reservationDate.year,
        reservationDate.month,
        reservationDate.day,
        startTime.hour,
        startTime.minute,
      );

  /// Thời gian kết thúc dự kiến
  DateTime get endDateTime =>
      startDateTime.add(Duration(minutes: durationMinutes));

  /// Format thời gian bắt đầu => "14:30"
  String get startTimeFormatted =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

  /// Format khoảng thời gian => "14:30 - 16:30"
  String get timeRangeFormatted {
    final end = endDateTime;
    return '$startTimeFormatted - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  /// Format thời lượng => "1h 30m"
  String get durationFormatted {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  /// Đã qua thời gian đặt chưa?
  bool get isPast => startDateTime.isBefore(DateTime.now());

  /// Có thể hủy?
  bool get isCancellable =>
      status == ReservationStatus.pending ||
      status == ReservationStatus.confirmed;

  /// Có thể check-in?
  bool get isCheckInAble => status == ReservationStatus.confirmed;

  // ───────────── fromJson ─────────────
  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Parse start_time "HH:mm" or "HH:mm:ss"
    TimeOfDay parseTime(String? raw) {
      if (raw == null || raw.isEmpty) return const TimeOfDay(hour: 0, minute: 0);
      final parts = raw.split(':');
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      );
    }

    return Reservation(
      id: json['id'] ?? '',
      companyId: json['company_id'],
      branchId: json['branch_id'],
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerEmail: json['customer_email'],
      type: ReservationType.fromString(json['type'] ?? ''),
      status: ReservationStatus.fromString(json['status'] ?? ''),
      reservationDate: json['reservation_date'] != null
          ? DateTime.tryParse(json['reservation_date']) ?? DateTime.now()
          : DateTime.now(),
      startTime: parseTime(json['start_time'] as String?),
      durationMinutes: json['duration_minutes'] ?? 60,
      guestCount: json['guest_count'] ?? 1,
      tableOrRoomId: json['table_or_room_id'],
      tableOrRoomName: json['table_or_room_name'],
      note: json['note'],
      cancelReason: json['cancel_reason'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  // ───────────── toJson ─────────────
  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'branch_id': branchId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_email': customerEmail,
        'type': type.value,
        'status': status.value,
        'reservation_date': reservationDate.toIso8601String().split('T').first,
        'start_time': startTimeFormatted,
        'duration_minutes': durationMinutes,
        'guest_count': guestCount,
        'table_or_room_id': tableOrRoomId,
        'table_or_room_name': tableOrRoomName,
        'note': note,
        'cancel_reason': cancelReason,
        'created_by': createdBy,
      };

  // ───────────── copyWith ─────────────
  Reservation copyWith({
    String? id,
    String? companyId,
    String? branchId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    ReservationType? type,
    ReservationStatus? status,
    DateTime? reservationDate,
    TimeOfDay? startTime,
    int? durationMinutes,
    int? guestCount,
    String? tableOrRoomId,
    String? tableOrRoomName,
    String? note,
    String? cancelReason,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      type: type ?? this.type,
      status: status ?? this.status,
      reservationDate: reservationDate ?? this.reservationDate,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      guestCount: guestCount ?? this.guestCount,
      tableOrRoomId: tableOrRoomId ?? this.tableOrRoomId,
      tableOrRoomName: tableOrRoomName ?? this.tableOrRoomName,
      note: note ?? this.note,
      cancelReason: cancelReason ?? this.cancelReason,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Reservation($id, $customerName, ${type.label}, ${status.label}, $startTimeFormatted)';
}

// ═══════════════════════════════════════════════════════════════
// RESERVATION STATS
// ═══════════════════════════════════════════════════════════════

class ReservationStats {
  final int todayTotal;
  final int todayConfirmed;
  final int todayPending;
  final int todayCancelled;
  final int todayCheckedIn;
  final int todayCompleted;
  final int weekTotal;

  const ReservationStats({
    this.todayTotal = 0,
    this.todayConfirmed = 0,
    this.todayPending = 0,
    this.todayCancelled = 0,
    this.todayCheckedIn = 0,
    this.todayCompleted = 0,
    this.weekTotal = 0,
  });

  factory ReservationStats.fromReservations(List<Reservation> all) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    final today = all.where((r) =>
        r.reservationDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
        r.reservationDate.isBefore(todayEnd));

    final week = all.where((r) =>
        r.reservationDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        r.reservationDate.isBefore(todayEnd));

    return ReservationStats(
      todayTotal: today.length,
      todayConfirmed:
          today.where((r) => r.status == ReservationStatus.confirmed).length,
      todayPending:
          today.where((r) => r.status == ReservationStatus.pending).length,
      todayCancelled:
          today.where((r) => r.status == ReservationStatus.cancelled).length,
      todayCheckedIn:
          today.where((r) => r.status == ReservationStatus.checkedIn).length,
      todayCompleted:
          today.where((r) => r.status == ReservationStatus.completed).length,
      weekTotal: week.length,
    );
  }

  factory ReservationStats.empty() => const ReservationStats();
}
