import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/management_task.dart';
import '../../models/task_attachment.dart';
import '../../providers/management_task_provider.dart';

/// Dialog for viewing and updating Management Task details
/// Used by Managers to report progress and complete tasks
class ManagementTaskDetailDialog extends ConsumerStatefulWidget {
  final ManagementTask task;

  const ManagementTaskDetailDialog({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<ManagementTaskDetailDialog> createState() =>
      _ManagementTaskDetailDialogState();
}

class _ManagementTaskDetailDialogState
    extends ConsumerState<ManagementTaskDetailDialog> {
  late double _progressValue;
  late TaskStatus _currentStatus;
  bool _isUpdating = false;
  bool _isUploadingFile = false;
  List<TaskAttachment>? _attachments;

  @override
  void initState() {
    super.initState();
    _progressValue = widget.task.progress.toDouble();
    _currentStatus = widget.task.status;
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      final attachments = await service.getTaskAttachments(widget.task.id);
      if (mounted) {
        setState(() => _attachments = attachments);
      }
    } catch (e) {
      print('❌ [ManagementTaskDetailDialog] _loadAttachments error: $e');
    }
  }

  Future<void> _updateProgress() async {
    setState(() => _isUpdating = true);

    try {
      final service = ref.read(managementTaskServiceProvider);
      
      // Determine new status based on progress
      String? newStatus;
      if (_progressValue == 100) {
        newStatus = 'completed';
      } else if (_progressValue > 0 && _currentStatus == TaskStatus.pending) {
        newStatus = 'in_progress';
      }

      await service.updateTaskProgress(
        taskId: widget.task.id,
        progress: _progressValue.toInt(),
        status: newStatus,
      );

      if (mounted) {
        // Refresh the task list
        ref.invalidate(managerAssignedTasksStreamProvider);
        ref.invalidate(managerCreatedTasksStreamProvider);
        
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật tiến độ thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateStatus(TaskStatus newStatus) async {
    setState(() => _isUpdating = true);

    try {
      final service = ref.read(managementTaskServiceProvider);
      
      await service.updateTaskStatus(
        taskId: widget.task.id,
        status: newStatus.value,
      );

      if (mounted) {
        // Refresh the task list
        ref.invalidate(managerAssignedTasksStreamProvider);
        ref.invalidate(managerCreatedTasksStreamProvider);
        
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã chuyển sang: ${newStatus.label}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.critical:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _getStatusColor() {
    switch (widget.task.status) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.overdue:
        return Colors.red;
      case TaskStatus.cancelled:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getPriorityColor().withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: _getPriorityColor(),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết công việc',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.task.priority.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.task.status.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.task.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Description
                    if (widget.task.description != null) ...[
                      _buildSection(
                        'Mô tả',
                        Icons.description,
                        Text(
                          widget.task.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Created by
                    _buildSection(
                      'Người giao việc',
                      Icons.person,
                      Text(
                        widget.task.createdByName ?? 'Không rõ',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Due date
                    if (widget.task.dueDate != null) ...[
                      _buildSection(
                        'Hạn hoàn thành',
                        Icons.calendar_today,
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(widget.task.dueDate!),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: widget.task.dueDate!.isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Progress Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Tiến độ công việc',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Progress slider
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _progressValue,
                                  min: 0,
                                  max: 100,
                                  divisions: 20,
                                  label: '${_progressValue.toInt()}%',
                                  onChanged: widget.task.status == TaskStatus.completed
                                      ? null // Disable if already completed
                                      : (value) {
                                          setState(() => _progressValue = value);
                                        },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  '${_progressValue.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progressValue / 100,
                              minHeight: 10,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // File Attachments Section
                    _buildSection(
                      'File đính kèm',
                      Icons.attach_file,
                      _buildAttachmentsSection(),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    if (widget.task.status != TaskStatus.completed) ...[
                      const Text(
                        'Hành động nhanh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.task.status == TaskStatus.pending)
                            ElevatedButton.icon(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus(TaskStatus.inProgress),
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('Bắt đầu'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          if (widget.task.status == TaskStatus.inProgress)
                            ElevatedButton.icon(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus(TaskStatus.completed),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Hoàn thành'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: 12),
                  if (_progressValue != widget.task.progress.toDouble())
                    ElevatedButton.icon(
                      onPressed: _isUpdating ? null : _updateProgress,
                      icon: _isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: const Text('Lưu tiến độ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: content,
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    if (_attachments == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Button
        OutlinedButton.icon(
          onPressed: _isUploadingFile ? null : _pickAndUploadFile,
          icon: _isUploadingFile
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file, size: 18),
          label: Text(_isUploadingFile ? 'Đang tải lên...' : 'Tải file lên'),
        ),
        
        const SizedBox(height: 12),

        // Attachments List
        if (_attachments!.isEmpty)
          Text(
            'Chưa có file đính kèm',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ..._attachments!.map((attachment) => _buildAttachmentItem(attachment)),
      ],
    );
  }

  Widget _buildAttachmentItem(TaskAttachment attachment) {
    IconData fileIcon;
    Color iconColor;

    if (attachment.isImage) {
      fileIcon = Icons.image;
      iconColor = Colors.blue;
    } else if (attachment.isDocument) {
      fileIcon = Icons.description;
      iconColor = Colors.orange;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(fileIcon, color: iconColor),
        title: Text(
          attachment.fileName,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          '${attachment.formattedSize} • ${DateFormat('dd/MM/yyyy HH:mm').format(attachment.createdAt)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download, size: 18),
              tooltip: 'Tải xuống',
              onPressed: () => _downloadAttachment(attachment),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              tooltip: 'Xóa',
              color: Colors.red,
              onPressed: () => _deleteAttachment(attachment),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
          'jpg', 'jpeg', 'png', 'gif', 'webp',
        ],
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

      // Convert extension to MIME type
      String? mimeType;
      if (file.extension != null) {
        final ext = file.extension!.toLowerCase();
        if (['jpg', 'jpeg'].contains(ext)) {
          mimeType = 'image/jpeg';
        } else if (ext == 'png') {
          mimeType = 'image/png';
        } else if (ext == 'gif') {
          mimeType = 'image/gif';
        } else if (ext == 'webp') {
          mimeType = 'image/webp';
        } else if (ext == 'pdf') {
          mimeType = 'application/pdf';
        } else if (['doc', 'docx'].contains(ext)) {
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        } else if (['xls', 'xlsx'].contains(ext)) {
          mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        } else if (['ppt', 'pptx'].contains(ext)) {
          mimeType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
        } else if (ext == 'txt') {
          mimeType = 'text/plain';
        }
      }

      final service = ref.read(managementTaskServiceProvider);
      await service.uploadTaskAttachment(
        taskId: widget.task.id,
        fileName: file.name,
        fileBytes: file.bytes!,
        fileType: mimeType,
      );

      // Reload attachments
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Tải file lên thành công')),
        );
      }
    } catch (e) {
      print('❌ [ManagementTaskDetailDialog] _pickAndUploadFile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  Future<void> _downloadAttachment(TaskAttachment attachment) async {
    try {
      final url = Uri.parse(attachment.fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Không thể mở URL';
      }
    } catch (e) {
      print('❌ [ManagementTaskDetailDialog] _downloadAttachment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi tải xuống: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAttachment(TaskAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa file "${attachment.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.deleteTaskAttachment(attachment.id, attachment.fileUrl);
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa file')),
        );
      }
    } catch (e) {
      print('❌ [ManagementTaskDetailDialog] _deleteAttachment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi xóa file: ${e.toString()}')),
        );
      }
    }
  }
}
