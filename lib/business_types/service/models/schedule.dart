import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ─── Shift Type ─────────────────────────────────────────────────────────────

enum ShiftType {
  morning('morning', 'Ca sáng', '06:00 - 14:00'),
  afternoon('afternoon', 'Ca chiều', '14:00 - 22:00'),
  evening('evening', 'Ca tối', '22:00 - 06:00'),
  full('full', 'Ca full', '08:00 - 17:30');

  const ShiftType(this.value, this.label, this.timeRange);
  final String value;
  final String label;
  final String timeRange;

  static ShiftType fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => morning);

  Color get color {
    switch (this) {
      case ShiftType.morning:
        return AppColors.warning;
      case ShiftType.afternoon:
        return AppColors.info;
      case ShiftType.evening:
        return AppColors.primaryDark;
      case ShiftType.full:
        return AppColors.success;
    }
  }

  IconData get icon {
    switch (this) {
      case ShiftType.morning:
        return Icons.wb_sunny;
      case ShiftType.afternoon:
        return Icons.wb_twilight;
      case ShiftType.evening:
        return Icons.nights_stay;
      case ShiftType.full:
        return Icons.access_time_filled;
    }
  }

  /// Default start time for each shift type
  TimeOfDay get defaultStart {
    switch (this) {
      case ShiftType.morning:
        return const TimeOfDay(hour: 6, minute: 0);
      case ShiftType.afternoon:
        return const TimeOfDay(hour: 14, minute: 0);
      case ShiftType.evening:
        return const TimeOfDay(hour: 22, minute: 0);
      case ShiftType.full:
        return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  /// Default end time for each shift type
  TimeOfDay get defaultEnd {
    switch (this) {
      case ShiftType.morning:
        return const TimeOfDay(hour: 14, minute: 0);
      case ShiftType.afternoon:
        return const TimeOfDay(hour: 22, minute: 0);
      case ShiftType.evening:
        return const TimeOfDay(hour: 6, minute: 0);
      case ShiftType.full:
        return const TimeOfDay(hour: 17, minute: 30);
    }
  }
}

// ─── Schedule Status ────────────────────────────────────────────────────────

enum ScheduleStatus {
  draft('draft', 'Nháp', AppColors.statusDraft),
  published('published', 'Đã phát hành', AppColors.success),
  modified('modified', 'Đã chỉnh sửa', AppColors.warning);

  const ScheduleStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static ScheduleStatus fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => draft);
}

// ─── Shift Schedule ─────────────────────────────────────────────────────────

class ShiftSchedule {
  final String id;
  final String employeeId;
  final String employeeName;
  final String? branchId;
  final String? companyId;
  final DateTime date;
  final ShiftType shiftType;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isOff; // Ngày nghỉ
  final String? note;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ShiftSchedule({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.branchId,
    this.companyId,
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    this.isOff = false,
    this.note,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// Parse "HH:mm" to TimeOfDay
  static TimeOfDay _parseTime(String? time, TimeOfDay fallback) {
    if (time == null || time.isEmpty) return fallback;
    final parts = time.split(':');
    if (parts.length != 2) return fallback;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? fallback.hour,
      minute: int.tryParse(parts[1]) ?? fallback.minute,
    );
  }

  /// Format TimeOfDay to "HH:mm"
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) {
    final shiftType = ShiftType.fromString(json['shift_type'] ?? 'morning');
    return ShiftSchedule(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String? ??
          (json['employees'] != null
              ? (json['employees']['full_name'] ?? 'N/A')
              : 'N/A'),
      branchId: json['branch_id'] as String?,
      companyId: json['company_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      shiftType: shiftType,
      startTime: _parseTime(
          json['start_time'] as String?, shiftType.defaultStart),
      endTime:
          _parseTime(json['end_time'] as String?, shiftType.defaultEnd),
      isOff: json['is_off'] as bool? ?? false,
      note: json['note'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'branch_id': branchId,
      'company_id': companyId,
      'date': date.toIso8601String().split('T').first,
      'shift_type': shiftType.value,
      'start_time': formatTime(startTime),
      'end_time': formatTime(endTime),
      'is_off': isOff,
      'note': note,
      'created_by': createdBy,
    };
  }

  ShiftSchedule copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? branchId,
    String? companyId,
    DateTime? date,
    ShiftType? shiftType,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isOff,
    String? note,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftSchedule(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      branchId: branchId ?? this.branchId,
      companyId: companyId ?? this.companyId,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isOff: isOff ?? this.isOff,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Formatted time range display: "06:00 - 14:00"
  String get timeRangeFormatted =>
      '${formatTime(startTime)} - ${formatTime(endTime)}';

  /// Display label: "Ca sáng (06:00 - 14:00)" or "Nghỉ"
  String get displayLabel =>
      isOff ? 'Nghỉ' : '${shiftType.label} ($timeRangeFormatted)';
}

// ─── Weekly Schedule ────────────────────────────────────────────────────────

class WeeklySchedule {
  final DateTime weekStart;
  final List<ShiftSchedule> shifts;
  final ScheduleStatus status;

  const WeeklySchedule({
    required this.weekStart,
    required this.shifts,
    this.status = ScheduleStatus.draft,
  });

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  /// Get shifts for a specific date
  List<ShiftSchedule> getShiftsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return shifts
        .where((s) =>
            s.date.year == dateOnly.year &&
            s.date.month == dateOnly.month &&
            s.date.day == dateOnly.day)
        .toList();
  }

  /// Get shifts for a specific employee
  List<ShiftSchedule> getShiftsForEmployee(String employeeId) {
    return shifts.where((s) => s.employeeId == employeeId).toList();
  }

  /// Get shift for a specific employee on a specific date
  ShiftSchedule? getShiftForEmployeeOnDate(
      String employeeId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final matching = shifts.where((s) =>
        s.employeeId == employeeId &&
        s.date.year == dateOnly.year &&
        s.date.month == dateOnly.month &&
        s.date.day == dateOnly.day);
    return matching.isNotEmpty ? matching.first : null;
  }

  /// All unique employee IDs in this week
  List<String> get employeeIds =>
      shifts.map((s) => s.employeeId).toSet().toList();

  /// All unique employee entries (id + name pairs)
  List<({String id, String name})> get employees {
    final seen = <String>{};
    final result = <({String id, String name})>[];
    for (final shift in shifts) {
      if (seen.add(shift.employeeId)) {
        result.add((id: shift.employeeId, name: shift.employeeName));
      }
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Dates in this week (Mon-Sun)
  List<DateTime> get weekDates =>
      List.generate(7, (i) => weekStart.add(Duration(days: i)));

  WeeklySchedule copyWith({
    DateTime? weekStart,
    List<ShiftSchedule>? shifts,
    ScheduleStatus? status,
  }) {
    return WeeklySchedule(
      weekStart: weekStart ?? this.weekStart,
      shifts: shifts ?? this.shifts,
      status: status ?? this.status,
    );
  }
}
