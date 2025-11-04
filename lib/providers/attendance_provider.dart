import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';

// Simple Attendance class for staff check-in/out
class Attendance {
  final String id;
  final String userId;
  final String? branchId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final String? notes;

  const Attendance({
    required this.id,
    required this.userId,
    this.branchId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      branchId: json['branch_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String)
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      status: AttendanceStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => AttendanceStatus.present,
      ),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'branch_id': branchId,
      'date': date.toIso8601String(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
  }
}

// Simple Attendance Service (Mock implementation for demo)
class AttendanceService {
  // Mock data storage
  static final List<Attendance> _mockAttendance = [];

  Future<Attendance?> getTodayAttendance(String userId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _mockAttendance
        .where((attendance) =>
            attendance.userId == userId &&
            attendance.date.isAfter(todayStart) &&
            attendance.date.isBefore(todayStart.add(const Duration(days: 1))))
        .firstOrNull;
  }

  Future<Attendance> checkIn({
    required String userId,
    String? branchId,
  }) async {
    final now = DateTime.now();
    final attendance = Attendance(
      id: 'attendance_${now.millisecondsSinceEpoch}',
      userId: userId,
      branchId: branchId,
      date: now,
      checkInTime: now,
      status: AttendanceStatus.present,
    );

    _mockAttendance.add(attendance);

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    return attendance;
  }

  Future<Attendance> checkOut({
    required String userId,
    String? branchId,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Find today's attendance
    final existingIndex = _mockAttendance.indexWhere((attendance) =>
        attendance.userId == userId &&
        attendance.date.isAfter(todayStart) &&
        attendance.date.isBefore(todayStart.add(const Duration(days: 1))));

    if (existingIndex == -1) {
      throw Exception('Chưa điểm danh vào ca hôm nay');
    }

    final existing = _mockAttendance[existingIndex];
    final updated = Attendance(
      id: existing.id,
      userId: existing.userId,
      branchId: existing.branchId,
      date: existing.date,
      checkInTime: existing.checkInTime,
      checkOutTime: now,
      status: existing.status,
      notes: existing.notes,
    );

    _mockAttendance[existingIndex] = updated;

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    return updated;
  }

  Future<List<Attendance>> getAttendanceHistory(String userId,
      {int days = 7}) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _mockAttendance
        .where((attendance) => attendance.userId == userId)
        .toList();
  }
}

// Providers
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final userTodayAttendanceProvider =
    FutureProvider.family<Attendance?, String>((ref, userId) async {
  final service = ref.read(attendanceServiceProvider);
  return service.getTodayAttendance(userId);
});

final userAttendanceHistoryProvider =
    FutureProvider.family<List<Attendance>, String>((ref, userId) async {
  final service = ref.read(attendanceServiceProvider);
  return service.getAttendanceHistory(userId);
});
