import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../utils/app_logger.dart';
import '../models/content.dart';

/// Service for content calendar & content items — SABO Media Production
class ContentService {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // CONTENT CALENDAR
  // ============================================================

  /// Get content calendar for a company (upcoming 30 days by default)
  Future<List<ContentCalendar>> getCalendar(String companyId,
      {DateTime? from, DateTime? to}) async {
    try {
      final fromDate = from ?? DateTime.now().subtract(const Duration(days: 7));
      final toDate = to ?? DateTime.now().add(const Duration(days: 30));

      final data = await _supabase
          .from('content_calendar')
          .select('*, media_channels(name), employees!content_calendar_assigned_to_fkey(full_name)')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .gte('planned_date', fromDate.toIso8601String().split('T').first)
          .lte('planned_date', toDate.toIso8601String().split('T').first)
          .order('planned_date');
      return data.map((e) => ContentCalendar.fromJson(e)).toList();
    } catch (e) {
      // Fallback without joins
      AppLogger.warn('ContentService.getCalendar join failed, retrying without joins: $e');
      try {
        final fromDate = from ?? DateTime.now().subtract(const Duration(days: 7));
        final toDate = to ?? DateTime.now().add(const Duration(days: 30));
        final data = await _supabase
            .from('content_calendar')
            .select()
            .eq('company_id', companyId)
            .eq('is_active', true)
            .gte('planned_date', fromDate.toIso8601String().split('T').first)
            .lte('planned_date', toDate.toIso8601String().split('T').first)
            .order('planned_date');
        return data.map((e) => ContentCalendar.fromJson(e)).toList();
      } catch (e2) {
        AppLogger.error('ContentService.getCalendar', e2);
        rethrow;
      }
    }
  }

  /// Get all content for a company (no date filter)
  Future<List<ContentCalendar>> getAllContent(String companyId) async {
    try {
      final data = await _supabase
          .from('content_calendar')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('planned_date', ascending: false);
      return data.map((e) => ContentCalendar.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('ContentService.getAllContent', e);
      rethrow;
    }
  }

  /// Get content by status (pipeline view)
  Future<List<ContentCalendar>> getContentByStatus(
      String companyId, ContentStatus status) async {
    try {
      final data = await _supabase
          .from('content_calendar')
          .select()
          .eq('company_id', companyId)
          .eq('status', status.value)
          .eq('is_active', true)
          .order('planned_date');
      return data.map((e) => ContentCalendar.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('ContentService.getContentByStatus', e);
      rethrow;
    }
  }

  /// Create content item
  Future<ContentCalendar> createContent(ContentCalendar content) async {
    try {
      final data = await _supabase
          .from('content_calendar')
          .insert(content.toJson())
          .select()
          .single();
      return ContentCalendar.fromJson(data);
    } catch (e) {
      AppLogger.error('ContentService.createContent', e);
      rethrow;
    }
  }

  /// Update content
  Future<ContentCalendar> updateContent(
      String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final data = await _supabase
          .from('content_calendar')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return ContentCalendar.fromJson(data);
    } catch (e) {
      AppLogger.error('ContentService.updateContent', e);
      rethrow;
    }
  }

  /// Update content status (pipeline progression)
  Future<void> updateContentStatus(String id, ContentStatus status) async {
    final updates = <String, dynamic>{
      'status': status.value,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (status == ContentStatus.published) {
      updates['publish_date'] = DateTime.now().toIso8601String();
    }
    await _supabase.from('content_calendar').update(updates).eq('id', id);
  }

  /// Delete content (soft)
  Future<void> deleteContent(String id) async {
    try {
      await _supabase
          .from('content_calendar')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      AppLogger.error('ContentService.deleteContent', e);
      rethrow;
    }
  }

  /// Get content pipeline stats
  Future<Map<String, int>> getPipelineStats(String companyId) async {
    try {
      final allContent = await getAllContent(companyId);
      final stats = <String, int>{};
      for (final status in ContentStatus.values) {
        stats[status.value] =
            allContent.where((c) => c.status == status).length;
      }
      stats['total'] = allContent.length;
      stats['overdue'] = allContent.where((c) => c.isOverdue).length;
      return stats;
    } catch (e) {
      AppLogger.error('ContentService.getPipelineStats', e);
      rethrow;
    }
  }
}
