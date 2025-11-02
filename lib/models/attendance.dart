import 'package:flutter/material.dart';

enum AttendanceStatus {
  present('Có mặt', Color(0xFF10B981)),
  late('Đi muộn', Color(0xFFF59E0B)),
  absent('Vắng', Color(0xFFEF4444)),
  onLeave('Nghỉ phép', Color(0xFF3B82F6));

  final String label;
  final Color color;
  const AttendanceStatus(this.label, this.color);
}

class EmployeeAttendance {
  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final DateTime date;
  final DateTime checkIn;
  final DateTime? checkOut;
  final AttendanceStatus status;
  final int lateMinutes;
  final double hoursWorked;
  final String? notes;

  const EmployeeAttendance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.lateMinutes = 0,
    this.hoursWorked = 0,
    this.notes,
  });

  EmployeeAttendance copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? companyId,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    AttendanceStatus? status,
    int? lateMinutes,
    double? hoursWorked,
    String? notes,
  }) {
    return EmployeeAttendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      companyId: companyId ?? this.companyId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      status: status ?? this.status,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      notes: notes ?? this.notes,
    );
  }
}

enum ShiftType {
  morning('Ca sáng', Color(0xFFF59E0B), '06:00-14:00'),
  afternoon('Ca chiều', Color(0xFF3B82F6), '14:00-22:00'),
  night('Ca đêm', Color(0xFF8B5CF6), '22:00-06:00'),
  fullDay('Cả ngày', Color(0xFF10B981), '06:00-22:00');

  final String label;
  final Color color;
  final String timeRange;
  const ShiftType(this.label, this.color, this.timeRange);
}

class EmployeeShift {
  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final DateTime date;
  final ShiftType shiftType;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final bool isCompleted;

  const EmployeeShift({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.isCompleted = false,
  });

  EmployeeShift copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? companyId,
    DateTime? date,
    ShiftType? shiftType,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    bool? isCompleted,
  }) {
    return EmployeeShift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      companyId: companyId ?? this.companyId,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class EmployeePerformance {
  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final DateTime month;
  final int totalShifts;
  final int completedShifts;
  final double attendanceRate;
  final double averageRating;
  final int tasksCompleted;
  final int customerServiced;
  final double revenueGenerated;
  final String? notes;

  const EmployeePerformance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    required this.month,
    required this.totalShifts,
    required this.completedShifts,
    required this.attendanceRate,
    required this.averageRating,
    required this.tasksCompleted,
    required this.customerServiced,
    required this.revenueGenerated,
    this.notes,
  });

  EmployeePerformance copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? companyId,
    DateTime? month,
    int? totalShifts,
    int? completedShifts,
    double? attendanceRate,
    double? averageRating,
    int? tasksCompleted,
    int? customerServiced,
    double? revenueGenerated,
    String? notes,
  }) {
    return EmployeePerformance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      companyId: companyId ?? this.companyId,
      month: month ?? this.month,
      totalShifts: totalShifts ?? this.totalShifts,
      completedShifts: completedShifts ?? this.completedShifts,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      averageRating: averageRating ?? this.averageRating,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      customerServiced: customerServiced ?? this.customerServiced,
      revenueGenerated: revenueGenerated ?? this.revenueGenerated,
      notes: notes ?? this.notes,
    );
  }
}
