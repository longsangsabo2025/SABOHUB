import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/task_template.dart';
import '../../models/management_task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/management_task_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

final _templatesProvider = FutureProvider<List<TaskTemplate>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = ref.read(currentUserProvider);
  final companyId = user?.companyId;

  var query = supabase.from('task_templates').select('*').eq('is_active', true);
  if (companyId != null) {
    query = query.eq('company_id', companyId);
  }

  final response = await query.order('created_at', ascending: false).limit(100);
  return (response as List).map((j) => TaskTemplate.fromJson(j)).toList();
});

class TaskTemplatesPage extends ConsumerStatefulWidget {
  const TaskTemplatesPage({super.key});

  @override
  ConsumerState<TaskTemplatesPage> createState() => _TaskTemplatesPageState();
}

class _TaskTemplatesPageState extends ConsumerState<TaskTemplatesPage> {
  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(_templatesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Task Templates'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showCreateTemplateDialog,
          ),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) => templates.isEmpty
            ? _buildEmptyState()
            : _buildTemplateList(templates),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.content_copy, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Chưa có template nào',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Tạo template để tiết kiệm thời gian',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Tạo Template'),
            onPressed: _showCreateTemplateDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(List<TaskTemplate> templates) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_templatesProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (ctx, i) => _buildTemplateCard(templates[i]),
      ),
    );
  }

  Widget _buildTemplateCard(TaskTemplate template) {
    final categoryIcon = {
      'media': '📱',
      'billiards': '🎱',
      'arena': '🎮',
      'operations': '⚙️',
      'general': '🏢',
    }[template.category ?? 'general'] ?? '🏢';

    final priorityColor = {
      'critical': Colors.red,
      'high': Colors.orange,
      'medium': Colors.blue,
      'low': Colors.grey,
    }[template.priority] ?? Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTemplateActions(template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(categoryIcon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(template.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(template.priorityLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: priorityColor)),
                  ),
                ],
              ),
              if (template.description != null) ...[
                const SizedBox(height: 8),
                Text(template.description!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (template.recurrencePattern != null)
                    _chip(Icons.repeat, template.recurrenceLabel, Colors.blue),
                  if (template.checklistCount > 0)
                    _chip(Icons.checklist, '${template.checklistCount} bước',
                        Colors.green),
                  if (template.estimatedDuration != null)
                    _chip(Icons.timer, '${template.estimatedDuration} phút',
                        Colors.orange),
                  if (template.assignedUserId != null)
                    _chip(Icons.person, 'Đã giao cố định', Colors.purple)
                  else if (template.assignedRole != null)
                    _chip(Icons.person, template.assignedRole!, Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showTemplateActions(TaskTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: const Text('Tạo task từ template này'),
              subtitle: const Text('Tạo nhiệm vụ mới dựa trên template'),
              onTap: () {
                Navigator.pop(ctx);
                _createTaskFromTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Vô hiệu hóa template'),
              onTap: () async {
                Navigator.pop(ctx);
                await _deactivateTemplate(template.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTaskFromTemplate(TaskTemplate template) async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      final managers = await service.getManagers();

      if (!mounted) return;

      if (managers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có Manager nào để giao việc')),
        );
        return;
      }

      String? selectedManager;
      DateTime? dueDate;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text('Tạo task: ${template.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Giao cho Manager'),
                  items: managers.map((m) {
                    return DropdownMenuItem(
                      value: m['id'] as String,
                      child: Text('${m['full_name']} (${m['company_name'] ?? ''})'),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedManager = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dueDate != null
                      ? 'Hạn: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                      : 'Chọn ngày hạn'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: selectedManager == null
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: const Text('Tạo Task'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true || selectedManager == null) return;

      // Resolve assignee name
      final matchedManager = managers.where((m) => m['id'] == selectedManager).toList();
      final managerName = matchedManager.isNotEmpty ? matchedManager.first['full_name'] as String? : null;
      final managerRole = matchedManager.isNotEmpty ? matchedManager.first['role'] as String? : null;

      await service.createTask(
        title: template.title,
        description: template.description,
        priority: template.priority,
        assignedTo: selectedManager!,
        assignedToName: managerName,
        assignedToRole: managerRole,
        category: template.category,
        recurrence: template.recurrencePattern,
        dueDate: dueDate,
        checklist: template.checklistItems,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo task từ template')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _deactivateTemplate(String id) async {
    try {
      await Supabase.instance.client
          .from('task_templates')
          .update({'is_active': false}).eq('id', id);
      ref.invalidate(_templatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã vô hiệu hóa template')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showCreateTemplateDialog() async {
    final service = ref.read(managementTaskServiceProvider);
    List<Map<String, dynamic>> managers;
    try {
      managers = await service.getManagers();
    } catch (_) {
      managers = [];
    }

    if (!mounted) return;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'medium';
    String? selectedCategory = 'general';
    String? selectedRecurrence;
    String? selectedAssignee;
    final checklistCtrl = TextEditingController();
    final checklistItems = <String>[];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tạo Template mới'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Tên template'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  const SizedBox(height: 12),
                  if (managers.isNotEmpty)
                    DropdownButtonFormField<String?>(
                      value: selectedAssignee,
                      decoration: const InputDecoration(
                        labelText: 'Giao cho (cố định)',
                        helperText: 'Người luôn nhận task từ template này',
                        helperMaxLines: 2,
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Chọn khi tạo task')),
                        ...managers.map((m) => DropdownMenuItem(
                              value: m['id'] as String,
                              child: Text(
                                  '${m['full_name']} (${m['role'] ?? ''})'),
                            )),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedAssignee = v),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(labelText: 'Mảng'),
                          items: TaskCategory.values.map((c) {
                            return DropdownMenuItem(
                                value: c.value, child: Text(c.displayName));
                          }).toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedCategory = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPriority,
                          decoration: const InputDecoration(labelText: 'Ưu tiên'),
                          items: const [
                            DropdownMenuItem(value: 'critical', child: Text('Khẩn cấp')),
                            DropdownMenuItem(value: 'high', child: Text('Cao')),
                            DropdownMenuItem(value: 'medium', child: Text('TB')),
                            DropdownMenuItem(value: 'low', child: Text('Thấp')),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedPriority = v ?? 'medium'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedRecurrence,
                    decoration: const InputDecoration(labelText: 'Lặp lại'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Không lặp')),
                      DropdownMenuItem(value: 'daily', child: Text('Hằng ngày')),
                      DropdownMenuItem(value: 'weekly', child: Text('Hằng tuần')),
                      DropdownMenuItem(value: 'monthly', child: Text('Hằng tháng')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedRecurrence = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: checklistCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Thêm bước checklist'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () {
                          if (checklistCtrl.text.isNotEmpty) {
                            setDialogState(() {
                              checklistItems.add(checklistCtrl.text);
                              checklistCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  ...checklistItems.asMap().entries.map((e) => ListTile(
                        dense: true,
                        leading: Text('${e.key + 1}.',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        title: Text(e.value, style: const TextStyle(fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              setDialogState(() => checklistItems.removeAt(e.key)),
                        ),
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                try {
                  final user = ref.read(currentUserProvider);
                  await Supabase.instance.client.from('task_templates').insert({
                    'title': titleCtrl.text,
                    'description':
                        descCtrl.text.isNotEmpty ? descCtrl.text : null,
                    'category': selectedCategory,
                    'priority': selectedPriority,
                    'recurrence_pattern': selectedRecurrence,
                    if (selectedAssignee != null)
                      'assigned_user_id': selectedAssignee,
                    'checklist_items': checklistItems.isNotEmpty
                        ? checklistItems
                            .asMap()
                            .entries
                            .map((e) => {
                                  'id': '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
                                  'title': e.value,
                                  'is_done': false,
                                })
                            .toList()
                        : null,
                    'is_active': true,
                    'created_by': user?.id,
                    'company_id': user?.companyId,
                  });
                  ref.invalidate(_templatesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã tạo template')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}
