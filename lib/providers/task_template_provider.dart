import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_template.dart';
import '../services/task_template_service.dart';

/// Provider for TaskTemplateService
final taskTemplateServiceProvider = Provider<TaskTemplateService>((ref) {
  return TaskTemplateService();
});

/// Provider for company task templates
final companyTaskTemplatesProvider =
    FutureProvider.family<List<TaskTemplate>, String>((ref, companyId) async {
  final service = ref.read(taskTemplateServiceProvider);
  return service.getCompanyTemplates(companyId);
});

/// Provider for active task templates only
final activeTaskTemplatesProvider =
    FutureProvider.family<List<TaskTemplate>, String>((ref, companyId) async {
  final service = ref.read(taskTemplateServiceProvider);
  return service.getActiveTemplates(companyId);
});

/// Provider for templates count
final taskTemplatesCountProvider =
    FutureProvider.family<int, String>((ref, companyId) async {
  final service = ref.read(taskTemplateServiceProvider);
  return service.getTemplatesCount(companyId);
});

/// Provider for active templates count
final activeTaskTemplatesCountProvider =
    FutureProvider.family<int, String>((ref, companyId) async {
  final service = ref.read(taskTemplateServiceProvider);
  return service.getActiveTemplatesCount(companyId);
});
