import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ─── Shift Type (schedules table) ───────────────────────────────────────────

enum ScheduleShiftType {
  morning('morning', 'Ca sáng', '07:00 - 14:00'),
  afternoon('afternoon', 'Ca chiều', '14:00 - 22:00'),
  evening('evening', 'Ca tối', '18:00 - 01:00'),
  fullDay('full_day', 'Cả ngày', '08:00 - 17:30');

  const ScheduleShiftType(this.value, this.label, this.timeRange);
  final String value;
  final String label;
  final String timeRange;

  static ScheduleShiftType fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => morning);

  Color get color {
    switch (this) {
      case ScheduleShiftType.morning:
        return AppColors.warning; // amber
      case ScheduleShiftType.afternoon:
        return AppColors.info; // blue
      case ScheduleShiftType.evening:
        return AppColors.primaryDark; // indigo
      case ScheduleShiftType.fullDay:
        return AppColors.success; // teal
    }
  }

  Color get bgColor {
    switch (this) {
      case ScheduleShiftType.morning:
        return AppColors.warningLight;
      case ScheduleShiftType.afternoon:
        return AppColors.infoLight;
      case ScheduleShiftType.evening:
        return Color(0xFFEDE9FE); // light indigo
      case ScheduleShiftType.fullDay:
        return AppColors.successLight;
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleShiftType.morning:
        return Icons.wb_sunny;
      case ScheduleShiftType.afternoon:
        return Icons.wb_twilight;
      case ScheduleShiftType.evening:
        return Icons.nights_stay;
      case ScheduleShiftType.fullDay:
        return Icons.access_time_filled;
    }
  }

  String get emoji {
    switch (this) {
      case ScheduleShiftType.morning:
        return '🌅';
      case ScheduleShiftType.afternoon:
        return '☀️';
      case ScheduleShiftType.evening:
        return '🌙';
      case ScheduleShiftType.fullDay:
        return '📋';
    }
  }

  /// Default start time for each shift type
  TimeOfDay get defaultStart {
    switch (this) {
      case ScheduleShiftType.morning:
        return const TimeOfDay(hour: 7, minute: 0);
      case ScheduleShiftType.afternoon:
        return const TimeOfDay(hour: 14, minute: 0);
      case ScheduleShiftType.evening:
        return const TimeOfDay(hour: 18, minute: 0);
      case ScheduleShiftType.fullDay:
        return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  /// Default end time for each shift type
  TimeOfDay get defaultEnd {
    switch (this) {
      case ScheduleShiftType.morning:
        return const TimeOfDay(hour: 14, minute: 0);
      case ScheduleShiftType.afternoon:
        return const TimeOfDay(hour: 22, minute: 0);
      case ScheduleShiftType.evening:
        return const TimeOfDay(hour: 1, minute: 0);
      case ScheduleShiftType.fullDay:
        return const TimeOfDay(hour: 17, minute: 30);
    }
  }
}

// ─── Schedule Status (CHECK constraint) ─────────────────────────────────────

enum ScheduleItemStatus {
  scheduled('scheduled', 'Đã xếp lịch', AppColors.info),
  confirmed('confirmed', 'Đã xác nhận', AppColors.success),
  absent('absent', 'Vắng mặt', AppColors.error),
  late_('late', 'Đi muộn', AppColors.warning),
  cancelled('cancelled', 'Đã hủy', AppColors.textSecondary);

  const ScheduleItemStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static ScheduleItemStatus fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => scheduled);
}

// ─── Shift Schedule Model (maps to `schedules` table) ───────────────────────

class StaffShiftSchedule {
  final String id;
  final String? employeeId;
  final String? companyId;
  final String? branchId;
  final String employeeName;
  final DateTime date;
  final ScheduleShiftType shiftType;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final ScheduleItemStatus status;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StaffShiftSchedule({
    required this.id,
    this.employeeId,
    this.companyId,
    this.branchId,
    this.employeeName = 'N/A',
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    this.status = ScheduleItemStatus.scheduled,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse "HH:mm:ss" or "HH:mm" to "HH:mm" string
  static String _normalizeTime(String? raw, String fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    final parts = raw.split(':');
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Format TimeOfDay → "HH:mm"
  static String formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Parse "HH:mm" → TimeOfDay
  static TimeOfDay parseTimeOfDay(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  factory StaffShiftSchedule.fromJson(Map<String, dynamic> json) {
    final shiftType =
        ScheduleShiftType.fromString(json['shift_type'] ?? 'morning');
    final defaultStart = formatTimeOfDay(shiftType.defaultStart);
    final defaultEnd = formatTimeOfDay(shiftType.defaultEnd);

    return StaffShiftSchedule(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String?,
      companyId: json['company_id'] as String?,
      branchId: json['branch_id'] as String?,
      employeeName: json['employee_name'] as String? ??
          (json['employees'] != null
              ? (json['employees']['full_name'] ?? 'N/A')
              : 'N/A'),
      date: DateTime.parse(json['date'] as String),
      shiftType: shiftType,
      startTime: _normalizeTime(json['start_time'] as String?, defaultStart),
      endTime: _normalizeTime(json['end_time'] as String?, defaultEnd),
      status: ScheduleItemStatus.fromString(json['status'] ?? 'scheduled'),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'employee_id': employeeId,
      'company_id': companyId,
      'branch_id': branchId,
      'date': _dateStr(date),
      'shift_type': shiftType.value,
      'start_time': startTime,
      'end_time': endTime,
      'status': status.value,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  StaffShiftSchedule copyWith({
    String? id,
    String? employeeId,
    String? companyId,
    String? branchId,
    String? employeeName,
    DateTime? date,
    ScheduleShiftType? shiftType,
    String? startTime,
    String? endTime,
    ScheduleItemStatus? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffShiftSchedule(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// "07:00 - 14:00"
  String get timeRangeDisplay => '$startTime - $endTime';

  /// "🌅 Ca sáng (07:00 - 14:00)"
  String get displayLabel =>
      '${shiftType.emoji} ${shiftType.label} ($timeRangeDisplay)';

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Weekly View Helper ─────────────────────────────────────────────────────

class WeeklyShiftData {
  final DateTime weekStart;
  final List<StaffShiftSchedule> shifts;
  final List<Map<String, dynamic>> employees;

  const WeeklyShiftData({
    required this.weekStart,
    required this.shifts,
    this.employees = const [],
  });

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  List<DateTime> get weekDates =>
      List.generate(7, (i) => weekStart.add(Duration(days: i)));

  /// Get shifts for a specific employee on a specific date
  List<StaffShiftSchedule> getShifts(String employeeId, DateTime date) {
    return shifts
        .where((s) =>
            s.employeeId == employeeId &&
            s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day)
        .toList();
  }

  /// All unique employee IDs from shifts
  List<String> get shiftEmployeeIds =>
      shifts.map((s) => s.employeeId ?? '').toSet().where((id) => id.isNotEmpty).toList();

  /// Merged employee list: employees from service + any extras from shifts
  List<Map<String, dynamic>> get allEmployees {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final emp in employees) {
      final id = emp['id'] as String;
      if (seen.add(id)) result.add(emp);
    }

    // Add employees who have shifts but aren't in the employee list
    for (final shift in shifts) {
      final id = shift.employeeId ?? '';
      if (id.isNotEmpty && seen.add(id)) {
        result.add({
          'id': id,
          'full_name': shift.employeeName,
          'role': '',
        });
      }
    }

    result.sort((a, b) =>
        (a['full_name'] as String).compareTo(b['full_name'] as String));
    return result;
  }

  /// Count shifts for an employee in this week
  int countShiftsForEmployee(String employeeId) =>
      shifts.where((s) => s.employeeId == employeeId).length;
}
