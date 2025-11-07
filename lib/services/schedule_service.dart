import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule.dart';

class ScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all schedules for a company
  Future<List<Schedule>> getAllSchedules(String companyId) async {
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('company_id', companyId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => Schedule.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải lịch làm việc: $e');
    }
  }

  // Get schedules by date range
  Future<List<Schedule>> getSchedulesByDateRange(
    String companyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('company_id', companyId)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first)
          .order('date', ascending: true);

      return (response as List)
          .map((json) => Schedule.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải lịch làm việc: $e');
    }
  }

  // Get schedules by employee
  Future<List<Schedule>> getSchedulesByEmployee(
    String companyId,
    String employeeId,
  ) async {
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('company_id', companyId)
          .eq('employee_id', employeeId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => Schedule.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải lịch làm việc của nhân viên: $e');
    }
  }

  // Get today's schedules
  Future<List<Schedule>> getTodaySchedules(String companyId) async {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T').first;
    
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('company_id', companyId)
          .eq('date', todayStr)
          .order('shift_type', ascending: true);

      return (response as List)
          .map((json) => Schedule.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải lịch làm việc hôm nay: $e');
    }
  }

  // Get upcoming schedules (next 7 days)
  Future<List<Schedule>> getUpcomingSchedules(String companyId) async {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('company_id', companyId)
          .gte('date', now.toIso8601String().split('T').first)
          .lte('date', nextWeek.toIso8601String().split('T').first)
          .order('date', ascending: true);

      return (response as List)
          .map((json) => Schedule.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải lịch làm việc sắp tới: $e');
    }
  }

  // Create a new schedule
  Future<Schedule> createSchedule(Schedule schedule) async {
    try {
      // Check for conflicts first
      await _checkScheduleConflict(schedule);
      
      final response = await _supabase
          .from('schedules')
          .insert(schedule.toJson())
          .select()
          .single();

      return Schedule.fromJson(response);
    } catch (e) {
      throw Exception('Lỗi khi tạo lịch làm việc: $e');
    }
  }

  // Create multiple schedules (batch)
  Future<List<Schedule>> createMultipleSchedules(List<Schedule> schedules) async {
    try {
      // Check for conflicts for all schedules
      for (final schedule in schedules) {
        await _checkScheduleConflict(schedule);
      }
      
      final response = await _supabase
          .from('schedules')
          .insert(schedules.map((s) => s.toJson()).toList())
          .select();

      return (response as List)
          .map((json) => Schedule.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tạo nhiều lịch làm việc: $e');
    }
  }

  // Update schedule
  Future<Schedule> updateSchedule(Schedule schedule) async {
    try {
      // Check for conflicts (excluding current schedule)
      await _checkScheduleConflict(schedule, excludeId: schedule.id);
      
      final response = await _supabase
          .from('schedules')
          .update(schedule.toJson())
          .eq('id', schedule.id)
          .select()
          .single();

      return Schedule.fromJson(response);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật lịch làm việc: $e');
    }
  }

  // Update schedule status
  Future<Schedule> updateScheduleStatus(
    String scheduleId,
    ScheduleStatus status, {
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (notes != null) {
        updateData['notes'] = notes;
      }

      final response = await _supabase
          .from('schedules')
          .update(updateData)
          .eq('id', scheduleId)
          .select()
          .single();

      return Schedule.fromJson(response);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái lịch làm việc: $e');
    }
  }

  // Delete schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _supabase
          .from('schedules')
          .delete()
          .eq('id', scheduleId);
    } catch (e) {
      throw Exception('Lỗi khi xóa lịch làm việc: $e');
    }
  }

  // Delete multiple schedules
  Future<void> deleteMultipleSchedules(List<String> scheduleIds) async {
    try {
      await _supabase
          .from('schedules')
          .delete()
          .inFilter('id', scheduleIds);
    } catch (e) {
      throw Exception('Lỗi khi xóa nhiều lịch làm việc: $e');
    }
  }

  // Check for schedule conflicts
  Future<void> _checkScheduleConflict(Schedule schedule, {String? excludeId}) async {
    try {
      var query = _supabase
          .from('schedules')
          .select('id, employee_id, date, shift_type, custom_start_time, custom_end_time')
          .eq('company_id', schedule.companyId)
          .eq('employee_id', schedule.employeeId)
          .eq('date', schedule.date.toIso8601String().split('T').first)
          .neq('status', 'cancelled');

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      final existingSchedules = (response as List)
          .map((json) => Schedule.fromJson(json))
          .toList();

      for (final existing in existingSchedules) {
        if (_checkTimeOverlap(schedule, existing)) {
          throw Exception(
            'Xung đột lịch làm việc: Nhân viên ${schedule.employeeName} đã có ca làm việc khác vào thời gian này'
          );
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi khi kiểm tra xung đột lịch làm việc: $e');
    }
  }

  // Check if two schedules have overlapping times
  bool _checkTimeOverlap(Schedule schedule1, Schedule schedule2) {
    final start1 = schedule1.effectiveStartTime.totalMinutes;
    final end1 = schedule1.effectiveEndTime.totalMinutes;
    final start2 = schedule2.effectiveStartTime.totalMinutes;
    final end2 = schedule2.effectiveEndTime.totalMinutes;

    // Handle overnight shifts
    final adjustedEnd1 = end1 <= start1 ? end1 + 24 * 60 : end1;
    final adjustedEnd2 = end2 <= start2 ? end2 + 24 * 60 : end2;

    return (start1 < adjustedEnd2) && (adjustedEnd1 > start2);
  }

  // Time-off requests management
  
  // Get all time-off requests for a company
  Future<List<TimeOffRequest>> getTimeOffRequests(String companyId) async {
    try {
      final response = await _supabase
          .from('time_off_requests')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TimeOffRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải đơn xin nghỉ phép: $e');
    }
  }

  // Get time-off requests by employee
  Future<List<TimeOffRequest>> getTimeOffRequestsByEmployee(
    String companyId,
    String employeeId,
  ) async {
    try {
      final response = await _supabase
          .from('time_off_requests')
          .select()
          .eq('company_id', companyId)
          .eq('employee_id', employeeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TimeOffRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải đơn xin nghỉ phép của nhân viên: $e');
    }
  }

  // Create time-off request
  Future<TimeOffRequest> createTimeOffRequest(TimeOffRequest request) async {
    try {
      final response = await _supabase
          .from('time_off_requests')
          .insert(request.toJson())
          .select()
          .single();

      return TimeOffRequest.fromJson(response);
    } catch (e) {
      throw Exception('Lỗi khi tạo đơn xin nghỉ phép: $e');
    }
  }

  // Update time-off request status
  Future<TimeOffRequest> updateTimeOffRequestStatus(
    String requestId,
    RequestStatus status, {
    String? approvedBy,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (approvedBy != null) {
        updateData['approved_by'] = approvedBy;
      }
      
      if (rejectionReason != null) {
        updateData['rejection_reason'] = rejectionReason;
      }

      final response = await _supabase
          .from('time_off_requests')
          .update(updateData)
          .eq('id', requestId)
          .select()
          .single();

      return TimeOffRequest.fromJson(response);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái đơn xin nghỉ phép: $e');
    }
  }

  // Delete time-off request
  Future<void> deleteTimeOffRequest(String requestId) async {
    try {
      await _supabase
          .from('time_off_requests')
          .delete()
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Lỗi khi xóa đơn xin nghỉ phép: $e');
    }
  }

  // Get schedule statistics
  Future<Map<String, int>> getScheduleStats(String companyId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      
      // Get today's schedules
      final todayResponse = await _supabase
          .from('schedules')
          .select('status')
          .eq('company_id', companyId)
          .eq('date', today);

      final todaySchedules = todayResponse as List;
      
      // Get this week's schedules
      final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final weekResponse = await _supabase
          .from('schedules')
          .select('status')
          .eq('company_id', companyId)
          .gte('date', startOfWeek.toIso8601String().split('T').first)
          .lte('date', endOfWeek.toIso8601String().split('T').first);

      final weekSchedules = weekResponse as List;

      return {
        'today_total': todaySchedules.length,
        'today_confirmed': todaySchedules.where((s) => s['status'] == 'confirmed').length,
        'today_absent': todaySchedules.where((s) => s['status'] == 'absent').length,
        'week_total': weekSchedules.length,
        'week_confirmed': weekSchedules.where((s) => s['status'] == 'confirmed').length,
        'week_absent': weekSchedules.where((s) => s['status'] == 'absent').length,
      };
    } catch (e) {
      throw Exception('Lỗi khi tải thống kê lịch làm việc: $e');
    }
  }
}