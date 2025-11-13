import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance.dart';

/// Provider for AttendanceService
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

/// Attendance Service - UPDATED FOR NEW SCHEMA
/// Uses branch_id, company_id, and GPS coordinates
class AttendanceService {
  final SupabaseClient _supabase;

  AttendanceService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Check in for a user with GPS location
  ///
  /// ⚠️ CRITICAL: [userId] is EMPLOYEE ID from employees table, NOT auth.user.id
  /// For CEO: userId = auth.user.id (also in employees.user_id)
  /// For Manager/Staff: userId = employees.id (employees.user_id is NULL)
  /// 
  /// [userId] - Employee ID from employees table
  /// [branchId] - Branch ID (NOT store_id!)
  /// [companyId] - Company ID
  /// [location] - Human-readable location string
  /// [latitude] - GPS latitude
  /// [longitude] - GPS longitude
  /// [photoUrl] - Check-in photo URL (optional)
  Future<AttendanceRecord> checkIn({
    required String userId,
    required String branchId,
    required String companyId,
    String? location,
    double? latitude,
    double? longitude,
    String? photoUrl,
  }) async {
    try {
      final now = DateTime.now();

      // VALIDATION: Check if user already checked in today
      final existingToday = await getTodayAttendance(userId);
      if (existingToday != null) {
        throw Exception('Bạn đã chấm công vào rồi! Không thể chấm công 2 lần trong ngày.');
      }

      // Get employee info to populate cached fields
      // FIXED: Query by employee ID, not user_id (which is NULL for employees)
      final employeeResponse = await _supabase
          .from('employees')
          .select('name, role')
          .eq('id', userId)  // ← FIX: Query by employee.id, not user_id
          .maybeSingle();

      final employeeName = employeeResponse?['name'] as String?;
      final employeeRole = employeeResponse?['role'] as String?;

      final response = await _supabase.from('attendance').insert({
        'user_id': userId,
        'branch_id': branchId,
        'company_id': companyId,
        'check_in': now.toIso8601String(),
        'check_in_location': location,
        'check_in_latitude': latitude,
        'check_in_longitude': longitude,
        'check_in_photo_url': photoUrl,
        'employee_name': employeeName,
        'employee_role': employeeRole,
        'is_late': false, // TODO: Calculate based on shift
      }).select('''
        *,
        branches(id, name, address)
      ''').single();
      
      // Note: Không join với users table vì employees không có trong auth.users

      return _fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Check out for a user with GPS location
  Future<AttendanceRecord> checkOut({
    required String attendanceId,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final now = DateTime.now();

      // VALIDATION: Get current record and validate
      final current = await _supabase
          .from('attendance')
          .select('check_in, check_out, user_id')
          .eq('id', attendanceId)
          .maybeSingle();

      if (current == null) {
        throw Exception('Không tìm thấy bản ghi chấm công!');
      }

      if (current['check_in'] == null) {
        throw Exception('Chưa chấm công vào! Vui lòng check-in trước.');
      }

      if (current['check_out'] != null) {
        throw Exception('Đã chấm công ra rồi! Không thể check-out 2 lần.');
      }

      final checkInTime = DateTime.parse(current['check_in'] as String);
      final duration = now.difference(checkInTime);
      final totalHours = duration.inMinutes / 60.0;

      final response = await _supabase
          .from('attendance')
          .update({
            'check_out': now.toIso8601String(),
            'check_out_location': location,
            'check_out_latitude': latitude,
            'check_out_longitude': longitude,
            'total_hours': totalHours,
            'is_early_leave': false, // TODO: Calculate based on shift
          })
          .eq('id', attendanceId)
          .select('''
            *,
            branches(id, name, address)
          ''')
          .single();
      
      // Note: Không join với users table vì employees không có trong auth.users

      return _fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get today's attendance for a user
  Future<AttendanceRecord?> getTodayAttendance(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('attendance')
          .select('''
            *,
            branches(id, name, address)
          ''')
          .eq('user_id', userId)
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String())
          .maybeSingle();
      
      // Note: Không join với users table vì employees không có trong auth.users

      return response != null ? _fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  /// Get attendance records for a specific user in date range
  Future<List<AttendanceRecord>> getUserAttendance({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now().add(const Duration(days: 1));

      final response = await _supabase
          .from('attendance')
          .select('''
            *,
            branches(id, name, address)
          ''')
          .eq('user_id', userId)
          .gte('check_in', start.toIso8601String())
          .lt('check_in', end.toIso8601String())
          .order('check_in', ascending: false);
      
      // Note: Không join với users table vì employees không có trong auth.users

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all attendance records for a company on a specific date
  Future<List<AttendanceRecord>> getCompanyAttendance({
    required String companyId,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final startOfDay =
          DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('attendance')
          .select('''
            *,
            branches(id, name, address)
          ''')
          .eq('company_id', companyId)
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String())
          .order('check_in', ascending: false);
      
      // Note: Không join với users table vì employees không có trong auth.users

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update attendance record
  Future<AttendanceRecord> updateAttendance({
    required String attendanceId,
    DateTime? checkIn,
    DateTime? checkOut,
    bool? isLate,
    bool? isEarlyLeave,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (checkIn != null) updates['check_in'] = checkIn.toIso8601String();
      if (checkOut != null) updates['check_out'] = checkOut.toIso8601String();
      if (isLate != null) updates['is_late'] = isLate;
      if (isEarlyLeave != null) updates['is_early_leave'] = isEarlyLeave;
      if (notes != null) updates['notes'] = notes;

      // Recalculate total hours if both check_in and check_out are present
      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        updates['total_hours'] = duration.inMinutes / 60.0;
      }

      final response = await _supabase
          .from('attendance')
          .update(updates)
          .eq('id', attendanceId)
          .select('''
            *,
            branches(id, name, address)
          ''')
          .single();
      
      // Note: Không join với users table vì employees không có trong auth.users

      return _fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete attendance record (soft delete if column exists)
  Future<void> deleteAttendance(String attendanceId) async {
    try {
      // Try soft delete first
      try {
        await _supabase
            .from('attendance')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', attendanceId);
      } catch (_) {
        // If deleted_at doesn't exist, do hard delete
        await _supabase.from('attendance').delete().eq('id', attendanceId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Helper to convert JSON to AttendanceRecord model
  AttendanceRecord _fromJson(Map<String, dynamic> json) {
    // Extract nested data
    // final branch = json['branches'] as Map<String, dynamic>?; // Available if needed
    final user = json['users'] as Map<String, dynamic>?;
    final userMeta = user?['raw_user_meta_data'] as Map<String, dynamic>?;

    // Get employee name - try multiple sources
    String employeeName = json['employee_name'] as String? ?? 
                          userMeta?['name'] as String? ?? 
                          user?['email'] as String? ?? 
                          'Unknown';

    return AttendanceRecord(
      id: json['id'] as String,
      employeeId: json['user_id'] as String,
      employeeName: employeeName,
      companyId: json['company_id'] as String,
      scheduleId: json['shift_id'] as String?,
      date: DateTime.parse(json['check_in'] as String),
      checkInTime: json['check_in'] != null
          ? DateTime.parse(json['check_in'] as String)
          : null,
      checkOutTime: json['check_out'] != null
          ? DateTime.parse(json['check_out'] as String)
          : null,
      breaks: [], // TODO: Add breaks if needed
      status: _calculateStatus(json),
      checkInLocation: json['check_in_location'] as String?,
      checkOutLocation: json['check_out_location'] as String?,
      checkInLatitude: (json['check_in_latitude'] as num?)?.toDouble(),
      checkInLongitude: (json['check_in_longitude'] as num?)?.toDouble(),
      checkOutLatitude: (json['check_out_latitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['check_out_longitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      totalWorkedMinutes: ((json['total_hours'] as num?) ?? 0 * 60).toInt(),
      totalBreakMinutes: 0, // TODO: Calculate from breaks
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['created_at'] as String), // Use created_at if updated_at missing
    );
  }

  /// Calculate attendance status from JSON data
  AttendanceStatus _calculateStatus(Map<String, dynamic> json) {
    final checkIn = json['check_in'] != null
        ? DateTime.parse(json['check_in'] as String)
        : null;
    final checkOut = json['check_out'] as String?;
    final isLate = json['is_late'] as bool? ?? false;
    final isEarlyLeave = json['is_early_leave'] as bool? ?? false;

    if (checkIn == null) return AttendanceStatus.absent;
    if (checkOut == null && checkIn.day != DateTime.now().day) {
      return AttendanceStatus.absent;
    }
    if (isLate) return AttendanceStatus.late;
    if (isEarlyLeave) return AttendanceStatus.leftEarly;
    if (checkOut == null) return AttendanceStatus.present;
    return AttendanceStatus.present;
  }
}
