import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance.dart';

/// Provider for AttendanceService
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

/// Attendance Service
/// Handles all attendance-related operations with Supabase
class AttendanceService {
  final _supabase = Supabase.instance.client;

  /// Get all attendance records for a company on a specific date
  ///
  /// [companyId] - Company ID to filter by
  /// [date] - Date to filter by (optional, defaults to today)
  Future<List<AttendanceRecord>> getCompanyAttendance({
    required String companyId,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final startOfDay =
          DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query attendance with user information
      final response = await _supabase
          .from('attendance')
          .select('''
            id,
            user_id,
            store_id,
            shift_id,
            check_in,
            check_out,
            check_in_location,
            check_out_location,
            check_in_photo_url,
            total_hours,
            is_late,
            is_early_leave,
            notes,
            created_at,
            users!inner(
              id,
              name,
              email,
              avatar_url,
              company_id
            ),
            stores(
              id,
              name,
              company_id
            )
          ''')
          .eq('users.company_id', companyId)
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String())
          .order('check_in', ascending: false);

      final records = (response as List).map((json) {
        return AttendanceRecord.fromSupabase(json);
      }).toList();

      return records;
    } catch (e) {
      rethrow;
    }
  }

  /// Get attendance records for a specific user
  ///
  /// [userId] - User ID to filter by
  /// [startDate] - Start date for the range
  /// [endDate] - End date for the range
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
            id,
            user_id,
            store_id,
            shift_id,
            check_in,
            check_out,
            check_in_location,
            check_out_location,
            check_in_photo_url,
            total_hours,
            is_late,
            is_early_leave,
            notes,
            created_at,
            users(
              id,
              name,
              email,
              avatar_url
            ),
            stores(
              id,
              name
            )
          ''')
          .eq('user_id', userId)
          .gte('check_in', start.toIso8601String())
          .lt('check_in', end.toIso8601String())
          .order('check_in', ascending: false);

      final records = (response as List).map((json) {
        return AttendanceRecord.fromSupabase(json);
      }).toList();

      return records;
    } catch (e) {
      rethrow;
    }
  }

  /// Check in for a user
  ///
  /// [userId] - User ID
  /// [storeId] - Store ID
  /// [shiftId] - Shift ID (optional)
  /// [location] - Check-in location (optional)
  /// [photoUrl] - Check-in photo URL (optional)
  Future<AttendanceRecord> checkIn({
    required String userId,
    required String storeId,
    String? shiftId,
    String? location,
    String? photoUrl,
  }) async {
    try {
      final now = DateTime.now();

      final response = await _supabase.from('attendance').insert({
        'user_id': userId,
        'store_id': storeId,
        'shift_id': shiftId,
        'check_in': now.toIso8601String(),
        'check_in_location': location,
        'check_in_photo_url': photoUrl,
        'is_late': false, // TODO: Calculate based on shift start time
      }).select('''
        id,
        user_id,
        store_id,
        shift_id,
        check_in,
        check_out,
        check_in_location,
        check_out_location,
        check_in_photo_url,
        total_hours,
        is_late,
        is_early_leave,
        notes,
        created_at,
        users(
          id,
          name,
          email,
          avatar_url
        ),
        stores(
          id,
          name
        )
      ''').single();

      return AttendanceRecord.fromSupabase(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Check out for a user
  ///
  /// [attendanceId] - Attendance record ID
  /// [location] - Check-out location (optional)
  Future<AttendanceRecord> checkOut({
    required String attendanceId,
    String? location,
  }) async {
    try {
      final now = DateTime.now();

      // Get current attendance record to calculate total hours
      final current = await _supabase
          .from('attendance')
          .select('check_in')
          .eq('id', attendanceId)
          .single();

      final checkInTime = DateTime.parse(current['check_in'] as String);
      final duration = now.difference(checkInTime);
      final totalHours = duration.inMinutes / 60.0;

      final response = await _supabase
          .from('attendance')
          .update({
            'check_out': now.toIso8601String(),
            'check_out_location': location,
            'total_hours': totalHours,
            'is_early_leave': false, // TODO: Calculate based on shift end time
          })
          .eq('id', attendanceId)
          .select('''
        id,
        user_id,
        store_id,
        shift_id,
        check_in,
        check_out,
        check_in_location,
        check_out_location,
        check_in_photo_url,
        total_hours,
        is_late,
        is_early_leave,
        notes,
        created_at,
        users(
          id,
          name,
          email,
          avatar_url
        ),
        stores(
          id,
          name
        )
      ''')
          .single();

      return AttendanceRecord.fromSupabase(response);
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
            id,
            user_id,
            store_id,
            shift_id,
            check_in,
            check_out,
            check_in_location,
            check_out_location,
            check_in_photo_url,
            total_hours,
            is_late,
            is_early_leave,
            notes,
            created_at,
            users(
              id,
              name,
              email,
              avatar_url
            ),
            stores(
              id,
              name
            )
          ''')
          .eq('user_id', userId)
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String())
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return AttendanceRecord.fromSupabase(response);
    } catch (e) {
      return null;
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

      // Recalculate total hours if both check_in and check_out are updated
      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        updates['total_hours'] = duration.inMinutes / 60.0;
      }

      final response = await _supabase
          .from('attendance')
          .update(updates)
          .eq('id', attendanceId)
          .select('''
            id,
            user_id,
            store_id,
            shift_id,
            check_in,
            check_out,
            check_in_location,
            check_out_location,
            check_in_photo_url,
            total_hours,
            is_late,
            is_early_leave,
            notes,
            created_at,
            users(
              id,
              name,
              email,
              avatar_url
            ),
            stores(
              id,
              name
            )
          ''').single();

      return AttendanceRecord.fromSupabase(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String attendanceId) async {
    try {
      await _supabase.from('attendance').delete().eq('id', attendanceId);
    } catch (e) {
      rethrow;
    }
  }
}

/// Attendance record model for displaying in UI
class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? userAvatar;
  final String storeId;
  final String? storeName;
  final String? shiftId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String? checkInLocation;
  final String? checkOutLocation;
  final String? checkInPhotoUrl;
  final double? totalHours;
  final bool isLate;
  final bool isEarlyLeave;
  final String? notes;
  final DateTime createdAt;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.userAvatar,
    required this.storeId,
    this.storeName,
    this.shiftId,
    required this.checkIn,
    this.checkOut,
    this.checkInLocation,
    this.checkOutLocation,
    this.checkInPhotoUrl,
    this.totalHours,
    required this.isLate,
    required this.isEarlyLeave,
    this.notes,
    required this.createdAt,
  });

  factory AttendanceRecord.fromSupabase(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    final store = json['stores'] as Map<String, dynamic>?;

    return AttendanceRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: user?['name'] as String? ?? 'Unknown',
      userEmail: user?['email'] as String?,
      userAvatar: user?['avatar_url'] as String?,
      storeId: json['store_id'] as String,
      storeName: store?['name'] as String?,
      shiftId: json['shift_id'] as String?,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: json['check_out'] != null
          ? DateTime.parse(json['check_out'] as String)
          : null,
      checkInLocation: json['check_in_location'] as String?,
      checkOutLocation: json['check_out_location'] as String?,
      checkInPhotoUrl: json['check_in_photo_url'] as String?,
      totalHours: json['total_hours'] != null
          ? (json['total_hours'] as num).toDouble()
          : null,
      isLate: json['is_late'] as bool? ?? false,
      isEarlyLeave: json['is_early_leave'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to AttendanceStatus based on status
  AttendanceStatus get status {
    if (checkOut == null && checkIn.day != DateTime.now().day) {
      return AttendanceStatus.absent;
    }
    if (isLate) {
      return AttendanceStatus.late;
    }
    return AttendanceStatus.present;
  }

  /// Calculate late minutes (if late)
  int get lateMinutes {
    if (!isLate) return 0;
    // TODO: Calculate based on shift start time
    // For now, assume 8:00 AM is the standard start time
    final standardStart =
        DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 0);
    if (checkIn.isAfter(standardStart)) {
      return checkIn.difference(standardStart).inMinutes;
    }
    return 0;
  }

  /// Calculate hours worked
  double get hoursWorked {
    if (totalHours != null) return totalHours!;
    if (checkOut == null) return 0;
    return checkOut!.difference(checkIn).inMinutes / 60.0;
  }
}
