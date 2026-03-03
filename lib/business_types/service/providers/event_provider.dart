import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../services/event_service.dart';

final eventServiceProvider = Provider((ref) => EventService());

/// All events for a company
final eventsProvider =
    FutureProvider.autoDispose.family<List<Event>, String>(
  (ref, companyId) async {
    final service = ref.read(eventServiceProvider);
    return service.getEvents(companyId);
  },
);

/// Upcoming events
final upcomingEventsProvider =
    FutureProvider.autoDispose.family<List<Event>, String>(
  (ref, companyId) async {
    final service = ref.read(eventServiceProvider);
    return service.getUpcomingEvents(companyId);
  },
);

/// Event stats
final eventStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, companyId) async {
    final service = ref.read(eventServiceProvider);
    return service.getEventStats(companyId);
  },
);

/// Actions for events
class EventActions {
  final Ref _ref;
  final EventService _service;

  EventActions(this._ref)
      : _service = _ref.read(eventServiceProvider);

  Future<Event> createEvent(Event event) async {
    final created = await _service.createEvent(event);
    _ref.invalidate(eventsProvider);
    _ref.invalidate(upcomingEventsProvider);
    _ref.invalidate(eventStatsProvider);
    return created;
  }

  Future<Event> updateEvent(
      String id, Map<String, dynamic> updates) async {
    final updated = await _service.updateEvent(id, updates);
    _ref.invalidate(eventsProvider);
    _ref.invalidate(upcomingEventsProvider);
    _ref.invalidate(eventStatsProvider);
    return updated;
  }

  Future<void> deleteEvent(String id) async {
    await _service.deleteEvent(id);
    _ref.invalidate(eventsProvider);
    _ref.invalidate(upcomingEventsProvider);
    _ref.invalidate(eventStatsProvider);
  }
}

final eventActionsProvider = Provider((ref) => EventActions(ref));
