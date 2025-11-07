import 'package:flutter/material.dart';

enum ShiftType {
  morning('Ca sáng', TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 14, minute: 0), Color(0xFFFFEB3B)),
  afternoon('Ca chiều', TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 22, minute: 0), Color(0xFF2196F3)),
  night('Ca đêm', TimeOfDay(hour: 22, minute: 0), TimeOfDay(hour: 6, minute: 0), Color(0xFF9C27B0)),
  full('Ca full', TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 17, minute: 0), Color(0xFF4CAF50));

  final String label;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;
  const ShiftType(this.label, this.startTime, this.endTime, this.color);

  String get timeRange => '${startTime.format24Hour} - ${endTime.format24Hour}';
  
  int get durationMinutes {
    int start = startTime.hour * 60 + startTime.minute;
    int end = endTime.hour * 60 + endTime.minute;
    if (end <= start) end += 24 * 60; // Next day
    return end - start;
  }
}

enum ScheduleStatus {
  scheduled('Đã lên lịch', Color(0xFF2196F3)),
  confirmed('Đã xác nhận', Color(0xFF4CAF50)),
  absent('Vắng mặt', Color(0xFFEF4444)),
  late('Muộn giờ', Color(0xFFF59E0B)),
  cancelled('Đã hủy', Color(0xFF6B7280));

  final String label;
  final Color color;
  const ScheduleStatus(this.label, this.color);
}

enum RequestStatus {
  pending('Chờ duyệt', Color(0xFFF59E0B)),
  approved('Đã duyệt', Color(0xFF10B981)),
  rejected('Từ chối', Color(0xFFEF4444));

  final String label;
  final Color color;
  const RequestStatus(this.label, this.color);
}

class Schedule {
  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeeEmail;
  final String? employeePhone;
  final String companyId;
  final DateTime date;
  final ShiftType shiftType;
  final TimeOfDay? customStartTime;
  final TimeOfDay? customEndTime;
  final ScheduleStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const Schedule({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeeEmail,
    this.employeePhone,
    required this.companyId,
    required this.date,
    required this.shiftType,
    this.customStartTime,
    this.customEndTime,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  Schedule copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeEmail,
    String? employeePhone,
    String? companyId,
    DateTime? date,
    ShiftType? shiftType,
    TimeOfDay? customStartTime,
    TimeOfDay? customEndTime,
    ScheduleStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Schedule(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      employeePhone: employeePhone ?? this.employeePhone,
      companyId: companyId ?? this.companyId,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      customStartTime: customStartTime ?? this.customStartTime,
      customEndTime: customEndTime ?? this.customEndTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      employeeEmail: json['employee_email'] as String?,
      employeePhone: json['employee_phone'] as String?,
      companyId: json['company_id'] as String,
      date: DateTime.parse(json['date'] as String),
      shiftType: ShiftType.values.firstWhere(
        (e) => e.name == json['shift_type'],
        orElse: () => ShiftType.full,
      ),
      customStartTime: json['custom_start_time'] != null
          ? _timeFromString(json['custom_start_time'])
          : null,
      customEndTime: json['custom_end_time'] != null
          ? _timeFromString(json['custom_end_time'])
          : null,
      status: ScheduleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ScheduleStatus.scheduled,
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'employee_phone': employeePhone,
      'company_id': companyId,
      'date': date.toIso8601String().split('T').first,
      'shift_type': shiftType.name,
      'custom_start_time': customStartTime?.format24Hour,
      'custom_end_time': customEndTime?.format24Hour,
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  // Helper getters
  TimeOfDay get effectiveStartTime => customStartTime ?? shiftType.startTime;
  TimeOfDay get effectiveEndTime => customEndTime ?? shiftType.endTime;
  
  String get timeRange => '${effectiveStartTime.format24Hour} - ${effectiveEndTime.format24Hour}';
  
  String get dateFormatted {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${weekdays[date.weekday % 7]} ${date.day}/${date.month}';
  }
  
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isPast => date.isBefore(DateTime.now());
}

class TimeOffRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final RequestStatus status;
  final String? approvedBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeOffRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  TimeOffRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    RequestStatus? status,
    String? approvedBy,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeOffRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      companyId: companyId ?? this.companyId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TimeOffRequest.fromJson(Map<String, dynamic> json) {
    return TimeOffRequest(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      companyId: json['company_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String,
      status: RequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      approvedBy: json['approved_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'company_id': companyId,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'reason': reason,
      'status': status.name,
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get dateRange {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return '${startDate.day}/${startDate.month}/${startDate.year}';
    }
    return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}';
  }
  
  int get totalDays => endDate.difference(startDate).inDays + 1;
}

// Helper function for time parsing
TimeOfDay _timeFromString(String timeStr) {
  final parts = timeStr.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
}

// Extension for TimeOfDay formatting
extension TimeOfDayExtension on TimeOfDay {
  String get format24Hour => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  
  int get totalMinutes => hour * 60 + minute;
  
  bool isBefore(TimeOfDay other) => totalMinutes < other.totalMinutes;
  bool isAfter(TimeOfDay other) => totalMinutes > other.totalMinutes;
}