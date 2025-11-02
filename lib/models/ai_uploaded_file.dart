/// AI Uploaded File Model
/// Represents a file uploaded for AI analysis
class AIUploadedFile {
  final String id;
  final String assistantId;
  final String companyId;
  final String? uploadedBy;
  final String fileName;
  final String fileType; // 'image', 'pdf', 'doc', 'spreadsheet', 'text'
  final String? mimeType;
  final int fileSize; // in bytes
  final String storagePath; // Supabase Storage path
  final String? openaiFileId; // OpenAI file ID for API
  final String
      processingStatus; // 'pending', 'processing', 'completed', 'failed'
  final String? processingError;
  final String? extractedText;
  final Map<String, dynamic>? analysis;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIUploadedFile({
    required this.id,
    required this.assistantId,
    required this.companyId,
    this.uploadedBy,
    required this.fileName,
    required this.fileType,
    this.mimeType,
    required this.fileSize,
    required this.storagePath,
    this.openaiFileId,
    required this.processingStatus,
    this.processingError,
    this.extractedText,
    this.analysis,
    required this.tags,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase JSON
  factory AIUploadedFile.fromJson(Map<String, dynamic> json) {
    return AIUploadedFile(
      id: json['id'] as String,
      assistantId: json['assistant_id'] as String,
      companyId: json['company_id'] as String,
      uploadedBy: json['uploaded_by'] as String?,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int,
      storagePath: json['storage_path'] as String,
      openaiFileId: json['openai_file_id'] as String?,
      processingStatus: json['processing_status'] as String? ?? 'pending',
      processingError: json['processing_error'] as String?,
      extractedText: json['extracted_text'] as String?,
      analysis: json['analysis'] as Map<String, dynamic>?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assistant_id': assistantId,
      'company_id': companyId,
      'uploaded_by': uploadedBy,
      'file_name': fileName,
      'file_type': fileType,
      'mime_type': mimeType,
      'file_size': fileSize,
      'storage_path': storagePath,
      'openai_file_id': openaiFileId,
      'processing_status': processingStatus,
      'processing_error': processingError,
      'extracted_text': extractedText,
      'analysis': analysis,
      'tags': tags,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get file type display name in Vietnamese
  String get fileTypeLabel {
    switch (fileType) {
      case 'image':
        return 'Hình ảnh';
      case 'pdf':
        return 'PDF';
      case 'doc':
        return 'Tài liệu';
      case 'spreadsheet':
        return 'Bảng tính';
      case 'text':
        return 'Văn bản';
      default:
        return fileType;
    }
  }

  /// Get processing status display name in Vietnamese
  String get statusLabel {
    switch (processingStatus) {
      case 'pending':
        return 'Đang chờ';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'failed':
        return 'Thất bại';
      default:
        return processingStatus;
    }
  }

  /// Get file size in human readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get file extension
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is an image
  bool get isImage => fileType == 'image';

  /// Check if file is a PDF
  bool get isPdf => fileType == 'pdf';

  /// Check if file is a document
  bool get isDocument => fileType == 'doc';

  /// Check if file is a spreadsheet
  bool get isSpreadsheet => fileType == 'spreadsheet';

  /// Check if file is text
  bool get isText => fileType == 'text';

  /// Check if processing is pending
  bool get isPending => processingStatus == 'pending';

  /// Check if currently processing
  bool get isProcessing => processingStatus == 'processing';

  /// Check if processing completed
  bool get isCompleted => processingStatus == 'completed';

  /// Check if processing failed
  bool get isFailed => processingStatus == 'failed';

  /// Check if file has been analyzed
  bool get hasAnalysis => analysis != null && analysis!.isNotEmpty;

  /// Check if file has extracted text
  bool get hasExtractedText =>
      extractedText != null && extractedText!.isNotEmpty;

  /// Get upload date formatted
  String get uploadedDateFormatted {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get public URL for the file in Supabase Storage
  String get storageUrl {
    // Use the Supabase public URL format
    // Format: https://[project-ref].supabase.co/storage/v1/object/public/[bucket]/[path]
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://your-project.supabase.co');
    return '$supabaseUrl/storage/v1/object/public/ai-files/$storagePath';
  }

  AIUploadedFile copyWith({
    String? id,
    String? assistantId,
    String? companyId,
    String? uploadedBy,
    String? fileName,
    String? fileType,
    String? mimeType,
    int? fileSize,
    String? storagePath,
    String? openaiFileId,
    String? processingStatus,
    String? processingError,
    String? extractedText,
    Map<String, dynamic>? analysis,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIUploadedFile(
      id: id ?? this.id,
      assistantId: assistantId ?? this.assistantId,
      companyId: companyId ?? this.companyId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      storagePath: storagePath ?? this.storagePath,
      openaiFileId: openaiFileId ?? this.openaiFileId,
      processingStatus: processingStatus ?? this.processingStatus,
      processingError: processingError ?? this.processingError,
      extractedText: extractedText ?? this.extractedText,
      analysis: analysis ?? this.analysis,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AIUploadedFile(id: $id, fileName: $fileName, status: $processingStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIUploadedFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
