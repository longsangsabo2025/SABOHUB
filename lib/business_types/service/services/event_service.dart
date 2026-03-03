import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../utils/app_logger.dart';
import '../models/event.dart';

/// Service for event management — SABO Events
class EventService {
  final _supabase = Supabase.instance.client;

  /// Get all events for a company
  Future<List<Event>> getEvents(String companyId) async {
    try {
      final data = await _supabase
          .from('events')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('start_date', ascending: false);
      return data.map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('EventService.getEvents', e);
      rethrow;
    }
  }

  /// Get upcoming events
  Future<List<Event>> getUpcomingEvents(String companyId) async {
    try {
      final data = await _supabase
          .from('events')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .inFilter('status', ['planning', 'confirmed'])
          .order('start_date');
      return data.map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('EventService.getUpcomingEvents', e);
      rethrow;
    }
  }

  /// Get events by type
  Future<List<Event>> getEventsByType(
      String companyId, EventType type) async {
    try {
      final data = await _supabase
          .from('events')
          .select()
          .eq('company_id', companyId)
          .eq('event_type', type.value)
          .eq('is_active', true)
          .order('start_date', ascending: false);
      return data.map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('EventService.getEventsByType', e);
      rethrow;
    }
  }

  /// Create event
  Future<Event> createEvent(Event event) async {
    try {
      final data = await _supabase
          .from('events')
          .insert(event.toJson())
          .select()
          .single();
      return Event.fromJson(data);
    } catch (e) {
      AppLogger.error('EventService.createEvent', e);
      rethrow;
    }
  }

  /// Update event
  Future<Event> updateEvent(
      String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final data = await _supabase
          .from('events')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Event.fromJson(data);
    } catch (e) {
      AppLogger.error('EventService.updateEvent', e);
      rethrow;
    }
  }

  /// Delete event (soft)
  Future<void> deleteEvent(String id) async {
    try {
      await _supabase
          .from('events')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      AppLogger.error('EventService.deleteEvent', e);
      rethrow;
    }
  }

  /// Get event stats
  Future<Map<String, dynamic>> getEventStats(String companyId) async {
    try {
      final events = await getEvents(companyId);

      int total = events.length;
      int upcoming = 0;
      int active = 0;
      int completed = 0;
      double totalBudget = 0;
      double totalRevenue = 0;
      int totalAttendees = 0;

      for (final e in events) {
        if (e.isUpcoming) upcoming++;
        if (e.isLive) active++;
        if (e.status == EventStatus.completed) completed++;
        totalBudget += e.budget;
        totalRevenue += e.revenue;
        totalAttendees += e.actualAttendees;
      }

      return {
        'total': total,
        'upcoming': upcoming,
        'active': active,
        'completed': completed,
        'total_budget': totalBudget,
        'total_revenue': totalRevenue,
        'total_attendees': totalAttendees,
      };
    } catch (e) {
      AppLogger.error('EventService.getEventStats', e);
      rethrow;
    }
  }
}
