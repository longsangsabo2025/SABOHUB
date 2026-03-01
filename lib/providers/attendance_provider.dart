import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';
import '../services/attendance_service.dart';

// Re-export the real attendanceServiceProvider from attendance_service.dart
export '../services/attendance_service.dart' show attendanceServiceProvider;

/// Provider: Today's attendance for a specific user (real Supabase data)
final userTodayAttendanceProvider =
    FutureProvider.autoDispose.family<AttendanceRecord?, String>((ref, userId) async {
  final service = ref.read(attendanceServiceProvider);
  return service.getTodayAttendance(userId);
});

/// Provider: Attendance history for a specific user (real Supabase data)
final userAttendanceHistoryProvider =
    FutureProvider.autoDispose.family<List<AttendanceRecord>, String>((ref, userId) async {
  final service = ref.read(attendanceServiceProvider);
  return service.getAttendanceHistory(userId);
});
