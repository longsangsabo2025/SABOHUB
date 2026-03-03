import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/content.dart';
import '../services/content_service.dart';

final contentServiceProvider = Provider((ref) => ContentService());

/// Content calendar (next 30 days)
final contentCalendarProvider =
    FutureProvider.autoDispose.family<List<ContentCalendar>, String>(
  (ref, companyId) async {
    final service = ref.read(contentServiceProvider);
    return service.getCalendar(companyId);
  },
);

/// All content items (no date filter)
final allContentProvider =
    FutureProvider.autoDispose.family<List<ContentCalendar>, String>(
  (ref, companyId) async {
    final service = ref.read(contentServiceProvider);
    return service.getAllContent(companyId);
  },
);

/// Content pipeline stats
final contentPipelineStatsProvider =
    FutureProvider.autoDispose.family<Map<String, int>, String>(
  (ref, companyId) async {
    final service = ref.read(contentServiceProvider);
    return service.getPipelineStats(companyId);
  },
);

/// Actions for content
class ContentActions {
  final Ref _ref;
  final ContentService _service;

  ContentActions(this._ref)
      : _service = _ref.read(contentServiceProvider);

  Future<ContentCalendar> createContent(ContentCalendar content) async {
    final created = await _service.createContent(content);
    _invalidateAll();
    return created;
  }

  Future<ContentCalendar> updateContent(
      String id, Map<String, dynamic> updates) async {
    final updated = await _service.updateContent(id, updates);
    _invalidateAll();
    return updated;
  }

  Future<void> updateStatus(String id, ContentStatus status) async {
    await _service.updateContentStatus(id, status);
    _invalidateAll();
  }

  Future<void> deleteContent(String id) async {
    await _service.deleteContent(id);
    _invalidateAll();
  }

  void _invalidateAll() {
    _ref.invalidate(contentCalendarProvider);
    _ref.invalidate(allContentProvider);
    _ref.invalidate(contentPipelineStatsProvider);
  }
}

final contentActionsProvider = Provider((ref) => ContentActions(ref));
