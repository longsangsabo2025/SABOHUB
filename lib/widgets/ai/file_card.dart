import 'package:flutter/material.dart';
import '../../models/ai_uploaded_file.dart';

/// Card widget for displaying an uploaded AI file
class FileCard extends StatelessWidget {
  final AIUploadedFile file;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onProcess;

  const FileCard({
    super.key,
    required this.file,
    required this.onTap,
    required this.onDelete,
    this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File icon and status
              Row(
                children: [
                  _buildFileIcon(),
                  const Spacer(),
                  _buildStatusBadge(context),
                  SizedBox(width: 4),
                  // Delete button
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // File name
              Text(
                file.fileName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              // File info
              Text(
                '${file.fileTypeLabel} • ${file.fileSizeFormatted}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const Spacer(),
              // Process button
              if (onProcess != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onProcess,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Phân tích'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData icon;
    Color color;
    switch (file.fileType) {
      case 'image':
        icon = Icons.image;
        color = Colors.blue;
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'spreadsheet':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case 'doc':
        icon = Icons.description;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (file.status) {
      case 'analyzed':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        label = 'Đã phân tích';
        break;
      case 'processing':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        label = 'Đang xử lý';
        break;
      case 'error':
        bgColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        label = 'Lỗi';
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        label = 'Đã tải lên';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
