import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_uploaded_file.dart';
import '../../providers/ai_provider.dart';
import 'file_card.dart';

/// Widget to display gallery of uploaded files
class FileGalleryWidget extends ConsumerWidget {
  final String assistantId;
  final String companyId;

  const FileGalleryWidget({
    super.key,
    required this.assistantId,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(uploadedFilesProvider(assistantId));

    return filesAsync.when(
      data: (files) => files.isEmpty
          ? _buildEmptyState(context)
          : _buildFileGrid(context, ref, files),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có file nào',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đính kèm file trong tin nhắn để bắt đầu phân tích',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileGrid(
    BuildContext context,
    WidgetRef ref,
    List<AIUploadedFile> files,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return FileCard(
          file: file,
          onTap: () => _showFileDetails(context, ref, file),
          onDelete: () => _deleteFile(context, ref, file),
          onProcess: file.isUploaded || file.hasError
              ? () => _processFile(context, ref, file)
              : null,
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải danh sách file',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFileDetails(
    BuildContext context,
    WidgetRef ref,
    AIUploadedFile file,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFileDetailsSheet(context, ref, file),
    );
  }

  Widget _buildFileDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    AIUploadedFile file,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(file.fileType),
                      size: 32,
                      color: _getFileColor(file.fileType),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.fileName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${file.fileSizeFormatted} • ${file.uploadedDateFormatted}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Status
                    _buildInfoSection(
                      context,
                      'Trạng thái',
                      _buildStatusChip(file),
                    ),

                    const SizedBox(height: 20),

                    // File info
                    _buildInfoSection(
                      context,
                      'Thông tin file',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Loại file', file.fileTypeLabel),
                          _buildInfoRow('Kích thước', file.fileSizeFormatted),
                          _buildInfoRow('MIME type', file.mimeType ?? 'N/A'),
                          _buildInfoRow(
                              'Ngày upload', file.uploadedDateFormatted),
                        ],
                      ),
                    ),

                    // Extracted text
                    if (file.hasExtractedText) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        context,
                        'Nội dung trích xuất',
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            file.extractedText!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],

                    // Analysis
                    if (file.hasAnalysis) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        context,
                        'Phân tích AI',
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            file.analysisResults.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],

                    // Error
                    if (file.hasError && file.errorMessage != null) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        context,
                        'Lỗi xử lý',
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            file.errorMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[900],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        if (file.isUploaded || file.hasError)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _processFile(context, ref, file);
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Xử lý lại'),
                            ),
                          ),
                        if (file.isUploaded || file.hasError)
                          const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteFile(context, ref, file);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Xóa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AIUploadedFile file) {
    Color color;
    IconData icon;
    String label;

    if (file.isUploaded) {
      color = Colors.orange;
      icon = Icons.hourglass_empty;
      label = 'Đã tải lên';
    } else if (file.isProcessing) {
      color = Colors.blue;
      icon = Icons.sync;
      label = 'Đang xử lý';
    } else if (file.isAnalyzed) {
      color = Colors.green;
      icon = Icons.check_circle;
      label = 'Đã phân tích';
    } else {
      color = Colors.red;
      icon = Icons.error;
      label = 'Lỗi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
        return Icons.description;
      case 'spreadsheet':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType) {
      case 'image':
        return Colors.purple;
      case 'pdf':
        return Colors.red;
      case 'doc':
        return Colors.blue;
      case 'spreadsheet':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _processFile(
    BuildContext context,
    WidgetRef ref,
    AIUploadedFile file,
  ) async {
    try {
      await ref
          .read(fileUploadNotifierProvider.notifier)
          .processFile(file.id, assistantId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang xử lý file...')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xử lý file: $e')),
        );
      }
    }
  }

  void _deleteFile(
    BuildContext context,
    WidgetRef ref,
    AIUploadedFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa file "${file.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(fileUploadNotifierProvider.notifier)
            .deleteFile(file.id, assistantId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa file')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa file: $e')),
          );
        }
      }
    }
  }
}
