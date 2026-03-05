import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/management_task.dart';
import '../../models/task_comment.dart';
import '../../models/task_attachment.dart';
import '../../providers/management_task_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Full-featured Task Detail Page
/// Shows: info, checklist, comments, attachments
class TaskDetailPage extends ConsumerStatefulWidget {
  final ManagementTask task;

  const TaskDetailPage({super.key, required this.task});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ManagementTask _task;
  final _commentController = TextEditingController();
  final _checklistController = TextEditingController();

  List<TaskComment> _comments = [];
  List<TaskAttachment> _attachments = [];
  bool _loadingComments = true;
  bool _loadingAttachments = true;
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final service = ref.read(managementTaskServiceProvider);
    try {
      final results = await Future.wait([
        service.getTaskComments(_task.id),
        service.getTaskAttachments(_task.id),
      ]);
      if (mounted) {
        setState(() {
          _comments = results[0] as List<TaskComment>;
          _attachments = results[1] as List<TaskAttachment>;
          _loadingComments = false;
          _loadingAttachments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingComments = false;
          _loadingAttachments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _task.category.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_task.isRecurring)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('🔄 ${_task.recurrence}'),
                backgroundColor: Colors.orange.shade50,
                side: BorderSide(color: Colors.orange.shade200),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Task header
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _task.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildPriorityChip(_task.priority),
                  ],
                ),
                if (_task.description != null &&
                    _task.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(Icons.person,
                        _task.assignedToName ?? 'Chưa giao'),
                    _buildInfoChip(Icons.business,
                        _task.companyName ?? 'SABO'),
                    _buildInfoChip(
                        Icons.calendar_today,
                        _task.dueDate != null
                            ? dateFormat.format(_task.dueDate!)
                            : 'Không hạn'),
                    _buildStatusChip(_task.status),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                Row(
                  children: [
                    Text(
                      'Tiến độ: ${_task.progress}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_task.hasChecklist) ...[
                      const SizedBox(width: 12),
                      Text(
                        '(${_task.checklistDone}/${_task.checklistTotal} bước)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _task.progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _task.progress >= 100
                          ? Colors.green
                          : _task.progress >= 50
                              ? Colors.blue
                              : Colors.orange,
                    ),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue.shade700,
              tabs: [
                Tab(
                  icon: Badge(
                    isLabelVisible: _task.hasChecklist,
                    label: Text('${_task.checklistTotal}'),
                    child: const Icon(Icons.checklist),
                  ),
                  text: 'Checklist',
                ),
                Tab(
                  icon: Badge(
                    isLabelVisible: _comments.isNotEmpty,
                    label: Text('${_comments.length}'),
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  text: 'Bình luận',
                ),
                Tab(
                  icon: Badge(
                    isLabelVisible: _attachments.isNotEmpty,
                    label: Text('${_attachments.length}'),
                    child: const Icon(Icons.attach_file),
                  ),
                  text: 'Tệp đính kèm',
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChecklistTab(),
                _buildCommentsTab(),
                _buildAttachmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== CHECKLIST TAB =====
  Widget _buildChecklistTab() {
    return Column(
      children: [
        // Add item bar
        Container(
          padding: EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _checklistController,
                  decoration: InputDecoration(
                    hintText: 'Thêm bước mới...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addChecklistItem(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addChecklistItem,
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                tooltip: 'Thêm',
              ),
            ],
          ),
        ),
        Expanded(
          child: _task.checklist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có checklist',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thêm các bước để theo dõi tiến độ chi tiết',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _task.checklist.length,
                  onReorder: _reorderChecklist,
                  itemBuilder: (context, index) {
                    final item = _task.checklist[index];
                    return _buildChecklistTile(item, key: ValueKey(item.id));
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChecklistTile(ChecklistItem item, {required Key key}) {
    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade50,
        child: Icon(Icons.delete, color: Colors.red.shade700),
      ),
      onDismissed: (_) => _removeChecklistItem(item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          value: item.isDone,
          onChanged: (_) => _toggleChecklistItem(item.id),
          title: Text(
            item.title,
            style: TextStyle(
              decoration: item.isDone ? TextDecoration.lineThrough : null,
              color: item.isDone ? Colors.grey : Theme.of(context).colorScheme.onSurface87,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          secondary: const Icon(Icons.drag_handle, color: Colors.grey),
        ),
      ),
    );
  }

  Future<void> _addChecklistItem() async {
    final text = _checklistController.text.trim();
    if (text.isEmpty) return;

    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.addChecklistItem(
        taskId: _task.id,
        currentChecklist: _task.checklist,
        title: text,
      );

      final newItem = ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text,
      );
      setState(() {
        _task = _task.copyWith(
          checklist: [..._task.checklist, newItem],
        );
      });
      _checklistController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleChecklistItem(String itemId) async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      final updated = _task.checklist.map((c) {
        if (c.id == itemId) return c.copyWith(isDone: !c.isDone);
        return c;
      }).toList();

      setState(() {
        final done = updated.where((c) => c.isDone).length;
        final total = updated.length;
        _task = _task.copyWith(
          checklist: updated,
          progress: total > 0 ? (done / total * 100).round() : 0,
        );
      });

      await service.updateChecklist(taskId: _task.id, checklist: updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeChecklistItem(String itemId) async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.removeChecklistItem(
        taskId: _task.id,
        currentChecklist: _task.checklist,
        itemId: itemId,
      );
      setState(() {
        _task = _task.copyWith(
          checklist: _task.checklist.where((c) => c.id != itemId).toList(),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _reorderChecklist(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final items = List<ChecklistItem>.from(_task.checklist);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    setState(() {
      _task = _task.copyWith(checklist: items);
    });
    final service = ref.read(managementTaskServiceProvider);
    service.updateChecklist(taskId: _task.id, checklist: items);
  }

  // ===== COMMENTS TAB =====
  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: _loadingComments
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bình luận',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return _buildCommentBubble(comment);
                      },
                    ),
        ),
        // Send message bar
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Viết bình luận...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendingComment ? null : _sendComment,
                icon: _sendingComment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send, color: Colors.blue.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBubble(TaskComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              (comment.userName ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comment.comment,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendingComment = true);
    try {
      final service = ref.read(managementTaskServiceProvider);
      final newComment = await service.addComment(
        taskId: _task.id,
        comment: text,
      );
      setState(() {
        _comments.add(newComment);
        _sendingComment = false;
      });
      _commentController.clear();
    } catch (e) {
      setState(() => _sendingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ===== ATTACHMENTS TAB =====
  Widget _buildAttachmentsTab() {
    if (_loadingAttachments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attachments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_file, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Chưa có tệp đính kèm',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'Manager có thể upload file từ trang task của họ',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _attachments.length,
      itemBuilder: (context, index) {
        final file = _attachments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getFileColor(file.fileExtension).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileIcon(file.fileExtension),
                color: _getFileColor(file.fileExtension),
              ),
            ),
            title: Text(
              file.fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${file.formattedSize} • ${DateFormat('dd/MM HH:mm').format(file.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang tải...')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ===== HELPER WIDGETS =====
  Widget _buildPriorityChip(TaskPriority priority) {
    final colors = {
      TaskPriority.critical: Colors.red,
      TaskPriority.high: Colors.orange,
      TaskPriority.medium: Colors.blue,
      TaskPriority.low: Colors.green,
    };
    final color = colors[priority] ?? Colors.grey;
    return Chip(
      label: Text(
        priority.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    final colors = {
      TaskStatus.completed: Colors.green,
      TaskStatus.inProgress: Colors.blue,
      TaskStatus.pending: Colors.orange,
      TaskStatus.overdue: Colors.red,
      TaskStatus.cancelled: Colors.grey,
    };
    final color = colors[status] ?? Colors.grey;
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(
        status.label,
        style: TextStyle(fontSize: 12, color: color),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String ext) {
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
