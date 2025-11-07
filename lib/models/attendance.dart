import 'package:flutter/material.dart';

enum AttendanceType {
  checkIn('Check-in', Icons.login, Color(0xFF4CAF50)),
  checkOut('Check-out', Icons.logout, Color(0xFFEF4444)),
  breakStart('Bắt đầu nghỉ', Icons.pause, Color(0xFFF59E0B)),
  breakEnd('Kết thúc nghỉ', Icons.play_arrow, Color(0xFF10B981));

  final String label;
  final IconData icon;
  final Color color;
  const AttendanceType(this.label, this.icon, this.color);
}

enum AttendanceStatus {
  present('Có mặt', Color(0xFF10B981)),
  absent('Vắng mặt', Color(0xFFEF4444)),
  late('Muộn giờ', Color(0xFFF59E0B)),
  leftEarly('Về sớm', Color(0xFF8B5CF6)),
  onBreak('Đang nghỉ', Color(0xFF06B6D4)),
  onLeave('Nghỉ phép', Color(0xFF9CA3AF));

  final String label;
  final Color color;
  const AttendanceStatus(this.label, this.color);
}

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final String? scheduleId; // Link to schedule if exists
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final List<BreakRecord> breaks;
  final AttendanceStatus status;
  final String? checkInLocation;
  final String? checkOutLocation;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? notes;
  final int totalWorkedMinutes; // Calculated field
  final int totalBreakMinutes; // Calculated field
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    this.scheduleId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.breaks = const [],
    required this.status,
    this.checkInLocation,
    this.checkOutLocation,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.notes,
    this.totalWorkedMinutes = 0,
    this.totalBreakMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? companyId,
    String? scheduleId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    List<BreakRecord>? breaks,
    AttendanceStatus? status,
    String? checkInLocation,
    String? checkOutLocation,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? notes,
    int? totalWorkedMinutes,
    int? totalBreakMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      companyId: companyId ?? this.companyId,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      breaks: breaks ?? this.breaks,
      status: status ?? this.status,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      notes: notes ?? this.notes,
      totalWorkedMinutes: totalWorkedMinutes ?? this.totalWorkedMinutes,
      totalBreakMinutes: totalBreakMinutes ?? this.totalBreakMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      companyId: json['company_id'] as String,
      scheduleId: json['schedule_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String)
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      breaks: (json['breaks'] as List<dynamic>?)
              ?.map((b) => BreakRecord.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      checkInLocation: json['check_in_location'] as String?,
      checkOutLocation: json['check_out_location'] as String?,
      checkInLatitude: json['check_in_latitude'] as double?,
      checkInLongitude: json['check_in_longitude'] as double?,
      checkOutLatitude: json['check_out_latitude'] as double?,
      checkOutLongitude: json['check_out_longitude'] as double?,
      notes: json['notes'] as String?,
      totalWorkedMinutes: json['total_worked_minutes'] as int? ?? 0,
      totalBreakMinutes: json['total_break_minutes'] as int? ?? 0,
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
      'schedule_id': scheduleId,
      'date': date.toIso8601String().split('T').first,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'breaks': breaks.map((b) => b.toJson()).toList(),
      'status': status.name,
      'check_in_location': checkInLocation,
      'check_out_location': checkOutLocation,
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'notes': notes,
      'total_worked_minutes': totalWorkedMinutes,
      'total_break_minutes': totalBreakMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  bool get isCheckedIn => checkInTime != null && checkOutTime == null;
  bool get isCheckedOut => checkInTime != null && checkOutTime != null;
  bool get isOnBreak => breaks.isNotEmpty && breaks.last.endTime == null;
  
  String get workDurationFormatted {
    if (totalWorkedMinutes == 0) return '0h 0m';
    final hours = totalWorkedMinutes ~/ 60;
    final minutes = totalWorkedMinutes % 60;
    return '${hours}h ${minutes}m';
  }
  
  String get breakDurationFormatted {
    if (totalBreakMinutes == 0) return '0h 0m';
    final hours = totalBreakMinutes ~/ 60;
    final minutes = totalBreakMinutes % 60;
    return '${hours}h ${minutes}m';
  }
  
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

  String? get currentBreakDuration {
    if (!isOnBreak) return null;
    final lastBreak = breaks.last;
    final duration = DateTime.now().difference(lastBreak.startTime).inMinutes;
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    return '${hours}h ${minutes}m';
  }
}

class BreakRecord {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? reason;
  final String? location;
  final double? latitude;
  final double? longitude;

  const BreakRecord({
    required this.id,
    required this.startTime,
    this.endTime,
    this.reason,
    this.location,
    this.latitude,
    this.longitude,
  });

  BreakRecord copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? reason,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return BreakRecord(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reason: reason ?? this.reason,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory BreakRecord.fromJson(Map<String, dynamic> json) {
    return BreakRecord(
      id: json['id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      reason: json['reason'] as String?,
      location: json['location'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'reason': reason,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Helper getters
  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }

  String get durationFormatted {
    final minutes = durationMinutes;
    if (minutes == 0) return 'Đang nghỉ';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}

class AttendanceSummary {
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final int totalScheduledMinutes;
  final int totalWorkedMinutes;
  final int totalBreakMinutes;
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final AttendanceStatus status;

  const AttendanceSummary({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.totalScheduledMinutes,
    required this.totalWorkedMinutes,
    required this.totalBreakMinutes,
    required this.lateMinutes,
    required this.earlyLeaveMinutes,
    required this.status,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      date: DateTime.parse(json['date'] as String),
      totalScheduledMinutes: json['total_scheduled_minutes'] as int? ?? 0,
      totalWorkedMinutes: json['total_worked_minutes'] as int? ?? 0,
      totalBreakMinutes: json['total_break_minutes'] as int? ?? 0,
      lateMinutes: json['late_minutes'] as int? ?? 0,
      earlyLeaveMinutes: json['early_leave_minutes'] as int? ?? 0,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'date': date.toIso8601String().split('T').first,
      'total_scheduled_minutes': totalScheduledMinutes,
      'total_worked_minutes': totalWorkedMinutes,
      'total_break_minutes': totalBreakMinutes,
      'late_minutes': lateMinutes,
      'early_leave_minutes': earlyLeaveMinutes,
      'status': status.name,
    };
  }

  // Helper getters
  double get attendancePercentage {
    if (totalScheduledMinutes == 0) return 0.0;
    return (totalWorkedMinutes / totalScheduledMinutes) * 100;
  }

  String get scheduledHoursFormatted {
    final hours = totalScheduledMinutes ~/ 60;
    final minutes = totalScheduledMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String get workedHoursFormatted {
    final hours = totalWorkedMinutes ~/ 60;
    final minutes = totalWorkedMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String get breakHoursFormatted {
    final hours = totalBreakMinutes ~/ 60;
    final minutes = totalBreakMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  bool get isLate => lateMinutes > 0;
  bool get leftEarly => earlyLeaveMinutes > 0;
  bool get hasPerfectAttendance => !isLate && !leftEarly && status == AttendanceStatus.present;
}
