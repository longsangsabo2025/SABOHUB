import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project.dart';

/// Get all projects for a company
final companyProjectsProvider = FutureProvider.family<List<Project>, String>((ref, companyId) async {
  final sb = Supabase.instance.client;
  
  final response = await sb
      .from('projects')
      .select('''
        *,
        manager:employees!projects_manager_id_fkey(full_name),
        companies(name)
      ''')
      .eq('company_id', companyId)
      .order('created_at', ascending: false);
  
  return (response as List).map((json) => Project.fromJson(json)).toList();
});

/// Get project with sub-projects
final projectWithSubProjectsProvider = FutureProvider.family<Project, String>((ref, projectId) async {
  final sb = Supabase.instance.client;
  
  // Get project
  final projectResponse = await sb
      .from('projects')
      .select('''
        *,
        manager:employees!projects_manager_id_fkey(full_name),
        companies(name)
      ''')
      .eq('id', projectId)
      .single();
  
  // Get sub-projects
  final subProjectsResponse = await sb
      .from('sub_projects')
      .select('''
        *,
        assignee:employees!sub_projects_assigned_to_fkey(full_name)
      ''')
      .eq('project_id', projectId)
      .order('sort_order');
  
  final subProjects = (subProjectsResponse as List)
      .map((json) => SubProject.fromJson(json))
      .toList();
  
  return Project.fromJson(projectResponse).copyWith(subProjects: subProjects);
});

/// Get all projects for multiple companies (for CEO view)
final allProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final sb = Supabase.instance.client;
  
  final response = await sb
      .from('projects')
      .select('''
        *,
        manager:employees!projects_manager_id_fkey(full_name),
        companies(name)
      ''')
      .order('created_at', ascending: false);
  
  return (response as List).map((json) => Project.fromJson(json)).toList();
});

/// Project Service for CRUD operations
class ProjectService {
  final _sb = Supabase.instance.client;

  /// Create a new project
  Future<Project> createProject({
    required String companyId,
    required String name,
    String? description,
    ProjectPriority priority = ProjectPriority.medium,
    DateTime? startDate,
    DateTime? endDate,
    String? managerId,
    String? createdBy,
  }) async {
    final response = await _sb
        .from('projects')
        .insert({
          'company_id': companyId,
          'name': name,
          'description': description,
          'priority': priority.name,
          'start_date': startDate?.toIso8601String().split('T')[0],
          'end_date': endDate?.toIso8601String().split('T')[0],
          'manager_id': managerId,
          'created_by': createdBy,
        })
        .select('''
          *,
          manager:employees!projects_manager_id_fkey(full_name),
          companies(name)
        ''')
        .single();
    
    return Project.fromJson(response);
  }

  /// Update project
  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _sb.from('projects').update(updates).eq('id', projectId);
  }

  /// Delete project (cascades to sub-projects)
  Future<void> deleteProject(String projectId) async {
    await _sb.from('projects').delete().eq('id', projectId);
  }

  /// Create sub-project
  Future<SubProject> createSubProject({
    required String projectId,
    required String name,
    String? description,
    ProjectPriority priority = ProjectPriority.medium,
    DateTime? startDate,
    DateTime? endDate,
    String? assignedTo,
    String? createdBy,
  }) async {
    // Get max sort_order
    final maxOrderResponse = await _sb
        .from('sub_projects')
        .select('sort_order')
        .eq('project_id', projectId)
        .order('sort_order', ascending: false)
        .limit(1);
    
    final maxOrder = (maxOrderResponse as List).isEmpty 
        ? 0 
        : (maxOrderResponse[0]['sort_order'] as int) + 1;
    
    final response = await _sb
        .from('sub_projects')
        .insert({
          'project_id': projectId,
          'name': name,
          'description': description,
          'priority': priority.name,
          'start_date': startDate?.toIso8601String().split('T')[0],
          'end_date': endDate?.toIso8601String().split('T')[0],
          'assigned_to': assignedTo,
          'created_by': createdBy,
          'sort_order': maxOrder,
        })
        .select('''
          *,
          assignee:employees!sub_projects_assigned_to_fkey(full_name)
        ''')
        .single();
    
    return SubProject.fromJson(response);
  }

  /// Update sub-project
  Future<void> updateSubProject(String subProjectId, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _sb.from('sub_projects').update(updates).eq('id', subProjectId);
  }

  /// Delete sub-project
  Future<void> deleteSubProject(String subProjectId) async {
    await _sb.from('sub_projects').delete().eq('id', subProjectId);
  }

  /// Update project progress based on sub-projects
  Future<void> recalculateProjectProgress(String projectId) async {
    final subProjects = await _sb
        .from('sub_projects')
        .select('progress')
        .eq('project_id', projectId);
    
    if ((subProjects as List).isEmpty) return;
    
    final total = subProjects.fold<int>(0, (sum, sp) => sum + (sp['progress'] as int));
    final avgProgress = (total / subProjects.length).round();
    
    await updateProject(projectId, {'progress': avgProgress});
  }
}

/// Provider for ProjectService
final projectServiceProvider = Provider<ProjectService>((ref) => ProjectService());
