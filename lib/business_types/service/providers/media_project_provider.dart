import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media_project.dart';

/// Provider: All media projects for a company
final mediaProjectsProvider =
    FutureProvider.family.autoDispose<List<MediaProject>, String>(
  (ref, companyId) async {
    if (companyId.isEmpty) return [];
    final supabase = Supabase.instance.client;

    final data = await supabase
        .from('media_projects')
        .select()
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final projects =
        (data as List).map((e) => MediaProject.fromJson(e)).toList();

    // Fetch content counts per project
    for (final project in projects) {
      try {
        final contentData = await supabase
            .from('content_calendar')
            .select('id, status')
            .eq('company_id', companyId)
            .eq('project_id', project.id)
            .eq('is_active', true);

        project.contentCount = (contentData as List).length;
        project.completedCount = (contentData as List)
            .where((c) => c['status'] == 'published')
            .length;
      } catch (_) {
        // project_id column may not exist yet on older data
      }
    }

    return projects;
  },
);

/// Provider: Project stats overview
final mediaProjectStatsProvider =
    FutureProvider.family.autoDispose<Map<String, int>, String>(
  (ref, companyId) async {
    if (companyId.isEmpty) return {};
    final supabase = Supabase.instance.client;

    final data = await supabase
        .from('media_projects')
        .select('status')
        .eq('company_id', companyId)
        .eq('is_active', true);

    final list = data as List;
    return {
      'total': list.length,
      'active': list.where((e) => e['status'] == 'active').length,
      'planning': list.where((e) => e['status'] == 'planning').length,
      'completed': list.where((e) => e['status'] == 'completed').length,
      'paused': list.where((e) => e['status'] == 'paused').length,
    };
  },
);

/// Actions provider for media projects CRUD
final mediaProjectActionsProvider = Provider<MediaProjectActions>((ref) {
  return MediaProjectActions(ref);
});

class MediaProjectActions {
  final Ref _ref;
  MediaProjectActions(this._ref);

  Future<void> createProject(MediaProject project) async {
    final supabase = Supabase.instance.client;
    await supabase.from('media_projects').insert(project.toJson());
    _ref.invalidate(mediaProjectsProvider);
    _ref.invalidate(mediaProjectStatsProvider);
  }

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    final supabase = Supabase.instance.client;
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabase.from('media_projects').update(data).eq('id', id);
    _ref.invalidate(mediaProjectsProvider);
    _ref.invalidate(mediaProjectStatsProvider);
  }

  Future<void> deleteProject(String id) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('media_projects')
        .update({'is_active': false}).eq('id', id);
    _ref.invalidate(mediaProjectsProvider);
    _ref.invalidate(mediaProjectStatsProvider);
  }
}
