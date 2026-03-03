import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/management_task.dart';
import '../../models/task_comment.dart';
import '../../models/task_attachment.dart';
import '../../providers/management_task_provider.dart';
import '../../core/theme/app_colors.dart';
import 'task_badges.dart';

// =============================================================================
// TASK DETAIL SHEET — Full-featured task management for Manager
// Features: Progress, Checklist, Comments, Attachments, Extension Request
// =============================================================================

class TaskDetailSheet extends ConsumerStatefulWidget {
  final ManagementTask task;
  final bool canChangeStatus;
  final bool canUpdateProgress;
  final bool canEditChecklist;
  final bool canAddComments;
  final bool canAddAttachments;
  final bool canRequestExtension;
  final VoidCallback? onTaskUpdated;

  const TaskDetailSheet({
    super.key,
    required this.task,
    this.canChangeStatus = true,
    this.canUpdateProgress = true,
    this.canEditChecklist = true,
    this.canAddComments = true,
    this.canAddAttachments = true,
    this.canRequestExtension = true,
    this.onTaskUpdated,
  });

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentProgress;
  late List<ChecklistItem> _checklist;
  bool _isUpdatingProgress = false;
  bool _isSubmittingComment = false;
  bool _isUploadingFile = false;

  // Controllers
  final _commentController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _linkTitleController = TextEditingController();
  final _extensionReasonController = TextEditingController();
  DateTime? _proposedExtensionDate;

  // Data
  List<TaskComment> _comments = [];
  List<TaskAttachment> _attachments = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentProgress = widget.task.progress;
    _checklist = List.from(widget.task.checklist);
    _loadTaskData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _linkUrlController.dispose();
    _linkTitleController.dispose();
    _extensionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskData() async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      final results = await Future.wait([
        service.getTaskComments(widget.task.id),
        service.getTaskAttachments(widget.task.id),
      ]);

      if (mounted) {
        setState(() {
          _comments = results[0] as List<TaskComment>;
          _attachments = results[1] as List<TaskAttachment>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isOverdue = widget.task.dueDate != null &&
        widget.task.status != TaskStatus.completed &&
        widget.task.dueDate!.isBefore(DateTime.now());

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              _buildHandle(),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        PriorityBadge(widget.task.priority),
                        StatusBadge(
                            isOverdue ? TaskStatus.overdue : widget.task.status),
                        if (widget.task.category != TaskCategory.general)
                          _buildCategoryBadge(widget.task.category),
                      ],
                    ),

                    // Due date warning
                    if (isOverdue) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Text(
                              'Quá hạn ${_formatOverdueDuration(widget.task.dueDate!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2,
                tabs: [
                  Tab(text: 'Chi tiết'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Bình luận'),
                        if (_comments.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_comments.length}',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tệp đính kèm'),
                        if (_attachments.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_attachments.length}',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Thêm'),
                ],
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(dateFormat),
                    _buildCommentsTab(),
                    _buildAttachmentsTab(),
                    _buildMoreTab(),
                  ],
                ),
              ),

              // Bottom action bar
              if (widget.canChangeStatus &&
                  widget.task.status != TaskStatus.completed)
                _buildActionBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD1D5DB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(TaskCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: DETAILS
  // ==========================================================================

  Widget _buildDetailsTab(DateFormat dateFormat) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Description
        if (widget.task.description != null &&
            widget.task.description!.isNotEmpty) ...[
          _buildSectionHeader('Mô tả', Icons.description_outlined),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.task.description!,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Progress slider
        if (widget.canUpdateProgress) ...[
          _buildSectionHeader('Tiến độ', Icons.trending_up_rounded),
          const SizedBox(height: 8),
          _buildProgressSection(),
          const SizedBox(height: 20),
        ],

        // Checklist
        if (_checklist.isNotEmpty || widget.canEditChecklist) ...[
          _buildSectionHeader(
            'Checklist (${_checklist.where((c) => c.isDone).length}/${_checklist.length})',
            Icons.checklist_rounded,
          ),
          const SizedBox(height: 8),
          _buildChecklistSection(),
          const SizedBox(height: 20),
        ],

        // Meta information
        _buildSectionHeader('Thông tin', Icons.info_outline_rounded),
        const SizedBox(height: 8),
        _buildMetaInfo(dateFormat),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_currentProgress%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _getProgressColor(_currentProgress),
                ),
              ),
              if (_isUpdatingProgress)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: _saveProgress,
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Lưu', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: _currentProgress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: _getProgressColor(_currentProgress),
              inactiveColor: const Color(0xFFE5E7EB),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _currentProgress = value.round());
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickProgressButton(0, 'Chưa bắt đầu'),
              _buildQuickProgressButton(25, '25%'),
              _buildQuickProgressButton(50, '50%'),
              _buildQuickProgressButton(75, '75%'),
              _buildQuickProgressButton(100, 'Hoàn thành'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickProgressButton(int value, String label) {
    final isSelected = _currentProgress == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentProgress = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? _getProgressColor(value).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: _getProgressColor(value))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? _getProgressColor(value)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(int progress) {
    if (progress == 0) return const Color(0xFF9CA3AF);
    if (progress < 30) return const Color(0xFFF59E0B);
    if (progress < 70) return const Color(0xFF3B82F6);
    if (progress < 100) return const Color(0xFF8B5CF6);
    return const Color(0xFF10B981);
  }

  Future<void> _saveProgress() async {
    if (_currentProgress == widget.task.progress) return;

    setState(() => _isUpdatingProgress = true);

    try {
      final service = ref.read(managementTaskServiceProvider);
      String? newStatus;

      if (_currentProgress == 100) {
        newStatus = 'completed';
      } else if (_currentProgress > 0 &&
          widget.task.status == TaskStatus.pending) {
        newStatus = 'in_progress';
      }

      await service.updateTaskProgress(
        taskId: widget.task.id,
        progress: _currentProgress,
        status: newStatus,
      );

      widget.onTaskUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật tiến độ: $_currentProgress%'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProgress = false);
    }
  }

  Widget _buildChecklistSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          ..._checklist.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildChecklistItem(item, index);
          }),
          if (widget.canEditChecklist)
            _buildAddChecklistButton(),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item, int index) {
    return InkWell(
      onTap: widget.canEditChecklist ? () => _toggleChecklistItem(item) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: index > 0
              ? const Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5))
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.isDone
                    ? AppColors.success
                    : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: item.isDone
                      ? AppColors.success
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: item.isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                  color: item.isDone
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF374151),
                ),
              ),
            ),
            if (widget.canEditChecklist)
              IconButton(
                onPressed: () => _removeChecklistItem(item),
                icon: const Icon(Icons.close_rounded, size: 16),
                color: const Color(0xFF9CA3AF),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddChecklistButton() {
    return InkWell(
      onTap: _showAddChecklistDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: const Color(0xFFD1D5DB),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
              ),
              child: const Icon(Icons.add, size: 14, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Thêm mục checklist',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleChecklistItem(ChecklistItem item) async {
    HapticFeedback.lightImpact();

    // Optimistic update
    setState(() {
      final index = _checklist.indexWhere((c) => c.id == item.id);
      if (index >= 0) {
        _checklist[index] = item.copyWith(isDone: !item.isDone);
        // Auto-update progress based on checklist
        final done = _checklist.where((c) => c.isDone).length;
        final total = _checklist.length;
        _currentProgress = (done / total * 100).round();
      }
    });

    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.toggleChecklistItem(
        taskId: widget.task.id,
        checklist: _checklist,
        itemId: item.id,
      );
      widget.onTaskUpdated?.call();
    } catch (e) {
      // Revert on error
      setState(() {
        final index = _checklist.indexWhere((c) => c.id == item.id);
        if (index >= 0) {
          _checklist[index] = item; // Revert to original
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _removeChecklistItem(ChecklistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Xóa mục này?', style: TextStyle(fontSize: 16)),
        content: Text('"${item.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _checklist.removeWhere((c) => c.id == item.id);
    });

    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.removeChecklistItem(
        taskId: widget.task.id,
        currentChecklist: _checklist,
        itemId: item.id,
      );
      widget.onTaskUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showAddChecklistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Thêm mục checklist', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập nội dung...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addChecklistItem(value.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addChecklistItem(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _addChecklistItem(String title) async {
    final newItem = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );

    setState(() {
      _checklist.add(newItem);
      // Recalculate progress
      final done = _checklist.where((c) => c.isDone).length;
      final total = _checklist.length;
      _currentProgress = (done / total * 100).round();
    });

    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.addChecklistItem(
        taskId: widget.task.id,
        currentChecklist: _checklist,
        title: title,
      );
      widget.onTaskUpdated?.call();
    } catch (e) {
      // Revert
      setState(() {
        _checklist.removeWhere((c) => c.id == newItem.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Widget _buildMetaInfo(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildMetaRow(Icons.person_outline_rounded, 'Giao cho',
              widget.task.assignedToName ?? '—'),
          _buildMetaRow(Icons.edit_note_rounded, 'Tạo bởi',
              widget.task.createdByName ?? '—'),
          if (widget.task.companyName != null)
            _buildMetaRow(
                Icons.business_rounded, 'Công ty', widget.task.companyName!),
          _buildMetaRow(
            Icons.event_rounded,
            'Hạn',
            widget.task.dueDate != null
                ? DateFormat('dd/MM/yyyy').format(widget.task.dueDate!)
                : '—',
          ),
          _buildMetaRow(Icons.access_time_rounded, 'Tạo lúc',
              dateFormat.format(widget.task.createdAt)),
          if (widget.task.completedAt != null)
            _buildMetaRow(Icons.check_circle_outline_rounded, 'Hoàn thành',
                dateFormat.format(widget.task.completedAt!)),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: COMMENTS
  // ==========================================================================

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? _buildEmptyComments()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (ctx, i) => _buildCommentItem(_comments[i]),
                    ),
        ),
        if (widget.canAddComments) _buildCommentInput(),
      ],
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Chưa có bình luận nào',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thêm ghi chú tiến độ hoặc báo cáo',
            style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(TaskComment comment) {
    // Map role to Vietnamese display name
    String getRoleDisplayName(String? role) {
      switch (role?.toLowerCase()) {
        case 'superadmin':
          return 'Super Admin';
        case 'ceo':
          return 'Giám đốc';
        case 'manager':
          return 'Quản lý';
        case 'shiftleader':
          return 'Trưởng ca';
        case 'staff':
          return 'Nhân viên';
        case 'driver':
          return 'Tài xế';
        case 'warehouse':
          return 'Kho';
        default:
          return role ?? 'Nhân viên';
      }
    }

    // Get role badge color
    Color getRoleBadgeColor(String? role) {
      switch (role?.toLowerCase()) {
        case 'superadmin':
          return const Color(0xFF7C3AED); // Purple
        case 'ceo':
          return const Color(0xFFDC2626); // Red
        case 'manager':
          return const Color(0xFF2563EB); // Blue
        case 'shiftleader':
          return const Color(0xFF059669); // Green
        case 'staff':
          return const Color(0xFF6B7280); // Gray
        case 'driver':
          return const Color(0xFFF59E0B); // Amber
        case 'warehouse':
          return const Color(0xFF8B5CF6); // Violet
        default:
          return const Color(0xFF6B7280);
      }
    }

    final roleColor = getRoleBadgeColor(comment.userRole);
    final hasAvatar = comment.userAvatarUrl != null && comment.userAvatarUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with image or fallback initial
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                backgroundImage: hasAvatar
                    ? NetworkImage(comment.userAvatarUrl!)
                    : null,
                child: hasAvatar
                    ? null
                    : Text(
                        (comment.userName ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: roleColor,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.userName ?? 'Người dùng',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${comment.timeAgo}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        getRoleDisplayName(comment.userRole),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.comment,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Thêm ghi chú...',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            _isSubmittingComment
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      final service = ref.read(managementTaskServiceProvider);
      final newComment = await service.addComment(
        taskId: widget.task.id,
        comment: text,
      );

      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });

      widget.onTaskUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  // ==========================================================================
  // TAB 3: ATTACHMENTS
  // ==========================================================================

  Widget _buildAttachmentsTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : _attachments.isEmpty
                  ? _buildEmptyAttachments()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _attachments.length,
                      itemBuilder: (ctx, i) =>
                          _buildAttachmentItem(_attachments[i]),
                    ),
        ),
        if (widget.canAddAttachments) _buildAttachmentButtons(),
      ],
    );
  }

  Widget _buildEmptyAttachments() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file_rounded,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Chưa có tệp đính kèm',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload file hoặc thêm link',
            style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(TaskAttachment attachment) {
    final isLink = attachment.fileType == 'link' ||
        attachment.fileType == 'youtube' ||
        attachment.fileType == 'google_drive' ||
        attachment.fileType == 'google_docs' ||
        attachment.fileType == 'figma' ||
        attachment.fileType == 'canva';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () => _openAttachment(attachment),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getAttachmentColor(attachment.fileType)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAttachmentIcon(attachment.fileType),
                  size: 20,
                  color: _getAttachmentColor(attachment.fileType),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLink
                          ? _truncateUrl(attachment.fileUrl)
                          : attachment.formattedSize,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                isLink ? Icons.open_in_new_rounded : Icons.download_rounded,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 40)}...';
  }

  IconData _getAttachmentIcon(String? fileType) {
    switch (fileType) {
      case 'youtube':
        return Icons.play_circle_filled;
      case 'google_drive':
        return Icons.folder;
      case 'google_docs':
        return Icons.description;
      case 'figma':
        return Icons.design_services;
      case 'canva':
        return Icons.brush;
      case 'link':
        return Icons.link;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image/png':
      case 'image/jpeg':
      case 'image/jpg':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getAttachmentColor(String? fileType) {
    switch (fileType) {
      case 'youtube':
        return Colors.red;
      case 'google_drive':
      case 'google_docs':
        return const Color(0xFF4285F4);
      case 'figma':
        return const Color(0xFFA259FF);
      case 'canva':
        return const Color(0xFF00C4CC);
      case 'link':
        return const Color(0xFF6B7280);
      case 'pdf':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Future<void> _openAttachment(TaskAttachment attachment) async {
    final uri = Uri.parse(attachment.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở link này')),
        );
      }
    }
  }

  Widget _buildAttachmentButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploadingFile ? null : _pickAndUploadFile,
                icon: _isUploadingFile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(
                  _isUploadingFile ? 'Đang tải...' : 'Tải file',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showAddLinkDialog,
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Thêm link', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể đọc file')),
          );
        }
        return;
      }

      setState(() => _isUploadingFile = true);

      final service = ref.read(managementTaskServiceProvider);
      final attachment = await service.uploadTaskAttachment(
        taskId: widget.task.id,
        fileName: file.name,
        fileBytes: file.bytes!,
        fileType: file.extension,
      );

      setState(() {
        _attachments.insert(0, attachment);
      });

      widget.onTaskUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải file lên thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  void _showAddLinkDialog() {
    _linkUrlController.clear();
    _linkTitleController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Thêm link', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _linkUrlController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'URL *',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkTitleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề (tùy chọn)',
                hintText: 'Tên hiển thị',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final url = _linkUrlController.text.trim();
              if (url.isNotEmpty) {
                _addLinkAttachment(url, _linkTitleController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _addLinkAttachment(String url, String? title) async {
    try {
      setState(() => _isUploadingFile = true);

      final service = ref.read(managementTaskServiceProvider);
      final attachment = await service.addTaskLinkAttachment(
        taskId: widget.task.id,
        linkUrl: url,
        linkTitle: title?.isEmpty == true ? null : title,
      );

      setState(() {
        _attachments.insert(0, attachment);
      });

      widget.onTaskUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm link!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  // ==========================================================================
  // TAB 4: MORE OPTIONS
  // ==========================================================================

  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Request deadline extension
        if (widget.canRequestExtension && widget.task.dueDate != null) ...[
          _buildSectionHeader('Yêu cầu gia hạn', Icons.schedule_rounded),
          const SizedBox(height: 12),
          _buildExtensionRequestSection(),
          const SizedBox(height: 24),
        ],

        // Task notes
        _buildSectionHeader('Ghi chú nhanh', Icons.sticky_note_2_outlined),
        const SizedBox(height: 12),
        _buildQuickNotesSection(),
      ],
    );
  }

  Widget _buildExtensionRequestSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                'Deadline hiện tại: ${DateFormat('dd/MM/yyyy').format(widget.task.dueDate!)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _extensionReasonController,
            decoration: InputDecoration(
              labelText: 'Lý do xin gia hạn *',
              hintText: 'Nhập lý do...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickExtensionDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 10),
                  Text(
                    _proposedExtensionDate != null
                        ? 'Đề xuất: ${DateFormat('dd/MM/yyyy').format(_proposedExtensionDate!)}'
                        : 'Chọn ngày đề xuất *',
                    style: TextStyle(
                      fontSize: 13,
                      color: _proposedExtensionDate != null
                          ? const Color(0xFF374151)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitExtensionRequest,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Gửi yêu cầu'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExtensionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.task.dueDate!.add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _proposedExtensionDate = picked);
    }
  }

  Future<void> _submitExtensionRequest() async {
    final reason = _extensionReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do')),
      );
      return;
    }
    if (_proposedExtensionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày đề xuất')),
      );
      return;
    }

    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.requestDeadlineExtension(
        taskId: widget.task.id,
        reason: reason,
        proposedDate: _proposedExtensionDate!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu gia hạn!'),
            backgroundColor: AppColors.success,
          ),
        );
        _extensionReasonController.clear();
        setState(() => _proposedExtensionDate = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Widget _buildQuickNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildQuickNoteButton(
            '📝 Đang xử lý, sẽ cập nhật sớm',
            'Đang xử lý, sẽ cập nhật tiến độ trong hôm nay.',
          ),
          const SizedBox(height: 8),
          _buildQuickNoteButton(
            '⚠️ Gặp khó khăn',
            'Gặp một số khó khăn khi thực hiện, cần hỗ trợ thêm.',
          ),
          const SizedBox(height: 8),
          _buildQuickNoteButton(
            '✅ Sắp hoàn thành',
            'Tiến độ tốt, dự kiến hoàn thành đúng deadline.',
          ),
          const SizedBox(height: 8),
          _buildQuickNoteButton(
            '🔄 Chờ phản hồi',
            'Đã thực hiện xong phần công việc, chờ phản hồi để tiếp tục.',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNoteButton(String label, String note) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _addQuickNote(note),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _addQuickNote(String note) async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      final newComment = await service.addComment(
        taskId: widget.task.id,
        comment: note,
      );

      setState(() {
        _comments.add(newComment);
      });

      widget.onTaskUpdated?.call();

      // Switch to comments tab
      _tabController.animateTo(1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm ghi chú!')),
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

  // ==========================================================================
  // BOTTOM ACTION BAR
  // ==========================================================================

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.task.status != TaskStatus.inProgress)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus(TaskStatus.inProgress),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label:
                      const Text('Bắt đầu', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (widget.task.status != TaskStatus.inProgress)
              const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _updateStatus(TaskStatus.completed),
                icon: const Icon(Icons.check_rounded, size: 18),
                label:
                    const Text('Hoàn thành', style: TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(TaskStatus newStatus) async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.updateTaskStatus(
        taskId: widget.task.id,
        status: newStatus.value,
      );

      widget.onTaskUpdated?.call();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật: ${newStatus.label}'),
            behavior: SnackBarBehavior.floating,
          ),
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

  String _formatOverdueDuration(DateTime dueDate) {
    final diff = DateTime.now().difference(dueDate);
    if (diff.inDays > 0) return '${diff.inDays} ngày';
    if (diff.inHours > 0) return '${diff.inHours} giờ';
    return '${diff.inMinutes} phút';
  }
}
