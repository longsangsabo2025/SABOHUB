import 'package:flutter/material.dart';

import '../../models/ai_uploaded_file.dart';

/// Card widget to display a single file in the gallery
class FileCard extends StatelessWidget {
  final AIUploadedFile file;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onProcess;

  const FileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onDelete,
    this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File preview/icon
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: _getFileColor().withValues(alpha: 0.1),
                child: file.isImage
                    ? Image.network(
                        file.fileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFileIcon();
                        },
                      )
                    : _buildFileIcon(),
              ),
            ),

            // File info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File name
                    Text(
                      file.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // File size and date
                    Text(
                      file.fileSizeFormatted,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),

                    // Status badge
                    Row(
                      children: [
                        Expanded(child: _buildStatusBadge()),
                        if (onProcess != null)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onProcess,
                            tooltip: 'Xử lý lại',
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onDelete,
                            color: Colors.red[400],
                            tooltip: 'Xóa',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    return Center(
      child: Icon(
        _getIconData(),
        size: 48,
        color: _getFileColor(),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    IconData icon;
    String label;

    if (file.isUploaded) {
      color = Colors.orange;
      icon = Icons.hourglass_empty;
      label = 'Chờ';
    } else if (file.isProcessing) {
      color = Colors.blue;
      icon = Icons.sync;
      label = 'Đang xử lý';
    } else if (file.isAnalyzed) {
      color = Colors.green;
      icon = Icons.check_circle;
      label = 'Xong';
    } else {
      color = Colors.red;
      icon = Icons.error;
      label = 'Lỗi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData() {
    switch (file.fileType) {
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

  Color _getFileColor() {
    switch (file.fileType) {
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
}
