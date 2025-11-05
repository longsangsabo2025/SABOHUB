import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';
import '../models/task_template.dart';

/// Service for managing task templates (recurring tasks)
class TaskTemplateService {
  final _supabase = supabase.client;

  /// Get all templates for a company
  Future<List<TaskTemplate>> getCompanyTemplates(String companyId) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskTemplate.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch task templates: $e');
    }
  }

  /// Get only active templates
  Future<List<TaskTemplate>> getActiveTemplates(String companyId) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((json) => TaskTemplate.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active templates: $e');
    }
  }

  /// Get templates by recurrence pattern
  Future<List<TaskTemplate>> getTemplatesByRecurrence(
    String companyId,
    String recurrencePattern,
  ) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select()
          .eq('company_id', companyId)
          .eq('recurrence_pattern', recurrencePattern)
          .eq('is_active', true)
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((json) => TaskTemplate.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch templates by recurrence: $e');
    }
  }

  /// Create a new task template
  Future<TaskTemplate> createTemplate(TaskTemplate template) async {
    try {
      final data = template.toJson();
      data.remove('id'); // Let database generate ID
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response =
          await _supabase.from('task_templates').insert(data).select().single();

      return TaskTemplate.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create task template: $e');
    }
  }

  /// Update an existing template
  Future<TaskTemplate> updateTemplate(TaskTemplate template) async {
    try {
      final data = template.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('task_templates')
          .update(data)
          .eq('id', template.id)
          .select()
          .single();

      return TaskTemplate.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update task template: $e');
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _supabase.from('task_templates').delete().eq('id', templateId);
    } catch (e) {
      throw Exception('Failed to delete task template: $e');
    }
  }

  /// Toggle template active status
  Future<TaskTemplate> toggleActive(String templateId, bool isActive) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', templateId)
          .select()
          .single();

      return TaskTemplate.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle template status: $e');
    }
  }

  /// Create template from AI suggestion
  Future<TaskTemplate> createFromAISuggestion({
    required String companyId,
    required String branchId,
    required Map<String, dynamic> suggestion,
    required String createdBy,
  }) async {
    try {
      // Parse priority from suggestion
      final priorityStr =
          (suggestion['priority'] as String?)?.toLowerCase() ?? 'medium';
      String priority = 'medium';
      if (priorityStr.contains('high') || priorityStr.contains('cao')) {
        priority = 'high';
      } else if (priorityStr.contains('low') || priorityStr.contains('thấp')) {
        priority = 'low';
      }

      // Parse category
      final categoryStr =
          (suggestion['category'] as String?)?.toLowerCase() ?? 'operations';
      String category = 'operations';
      if (categoryStr.contains('checklist')) {
        category = 'checklist';
      } else if (categoryStr.contains('sop')) {
        category = 'sop';
      } else if (categoryStr.contains('kpi')) {
        category = 'kpi';
      }

      // Detect recurrence from title/description
      final title = suggestion['title'] as String? ?? '';
      final description = suggestion['description'] as String? ?? '';
      final text = '$title $description'.toLowerCase();

      String recurrencePattern = 'daily'; // Default
      if (text.contains('hằng ngày') ||
          text.contains('mỗi ngày') ||
          text.contains('daily')) {
        recurrencePattern = 'daily';
      } else if (text.contains('hằng tuần') ||
          text.contains('mỗi tuần') ||
          text.contains('weekly')) {
        recurrencePattern = 'weekly';
      } else if (text.contains('hằng tháng') ||
          text.contains('mỗi tháng') ||
          text.contains('monthly')) {
        recurrencePattern = 'monthly';
      }

      // Default scheduled time based on task type
      final hour =
          categoryStr.contains('checklist') || text.contains('vệ sinh') ? 8 : 9;

      final template = TaskTemplate(
        id: '',
        companyId: companyId,
        branchId: branchId,
        title: title,
        description: description,
        category: category,
        priority: priority,
        recurrencePattern: RecurrencePattern.fromString(recurrencePattern),
        scheduledTime: TimeOfDay(hour: hour, minute: 0),
        assignedRole:
            priority == 'high' ? AssignedRole.staff : AssignedRole.any,
        isActive: true,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        aiSuggestionId: suggestion['id'] as String?,
        aiConfidence: 0.85,
      );

      return await createTemplate(template);
    } catch (e) {
      throw Exception('Failed to create template from AI suggestion: $e');
    }
  }

  /// Get template by ID
  Future<TaskTemplate?> getTemplateById(String templateId) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select()
          .eq('id', templateId)
          .maybeSingle();

      if (response == null) return null;
      return TaskTemplate.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch template: $e');
    }
  }

  /// Get templates count by company
  Future<int> getTemplatesCount(String companyId) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select('id')
          .eq('company_id', companyId);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to count templates: $e');
    }
  }

  /// Get active templates count
  Future<int> getActiveTemplatesCount(String companyId) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select('id')
          .eq('company_id', companyId)
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to count active templates: $e');
    }
  }
}
