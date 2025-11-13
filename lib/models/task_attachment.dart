/// Task Attachment Model
/// For files uploaded to tasks (results, documents, images, etc.)
class TaskAttachment {
  final String id;
  final String taskId;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String? fileType;
  final String uploadedBy;
  final DateTime createdAt;

  // Optional user details
  final String? uploadedByName;

  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.fileType,
    required this.uploadedBy,
    required this.createdAt,
    this.uploadedByName,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: json['file_size'] as int?,
      fileType: json['file_type'] as String?,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      uploadedByName: json['uploaded_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size': fileSize,
      'file_type': fileType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Format file size for display
  String get formattedSize {
    if (fileSize == null) return 'Không rõ';
    
    final bytes = fileSize!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get file extension
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is an image
  bool get isImage {
    final imageExts = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExts.contains(fileExtension);
  }

  /// Check if file is a document
  bool get isDocument {
    final docExts = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];
    return docExts.contains(fileExtension);
  }
}
