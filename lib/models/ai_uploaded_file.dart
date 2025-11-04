/// AI Uploaded File Model
/// Represents a file uploaded for AI analysis
class AIUploadedFile {
  final String id;
  final String assistantId;
  final String companyId;
  final String? userId;
  final String fileName;
  final String fileType; // 'image', 'pdf', 'doc', 'spreadsheet', 'text'
  final String? mimeType;
  final int fileSize; // in bytes
  final String fileUrl; // Supabase Storage URL or path
  final String? openaiFileId; // OpenAI file ID for API
  final String status; // 'uploaded', 'processing', 'analyzed', 'error'
  final String? errorMessage;
  final String? extractedText;
  final String? analysisStatus;
  final Map<String, dynamic>? analysisResults;
  final DateTime createdAt;
  final DateTime? analyzedAt;

  const AIUploadedFile({
    required this.id,
    required this.assistantId,
    required this.companyId,
    this.userId,
    required this.fileName,
    required this.fileType,
    this.mimeType,
    required this.fileSize,
    required this.fileUrl,
    this.openaiFileId,
    required this.status,
    this.errorMessage,
    this.extractedText,
    this.analysisStatus,
    this.analysisResults,
    required this.createdAt,
    this.analyzedAt,
  });

  /// Create from Supabase JSON
  factory AIUploadedFile.fromJson(Map<String, dynamic> json) {
    return AIUploadedFile(
      id: json['id'] as String,
      assistantId: json['assistant_id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String?,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int,
      fileUrl: json['file_url'] as String,
      openaiFileId: json['openai_file_id'] as String?,
      status: json['status'] as String? ?? 'uploaded',
      errorMessage: json['error_message'] as String?,
      extractedText: json['extracted_text'] as String?,
      analysisStatus: json['analysis_status'] as String?,
      analysisResults: json['analysis_results'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assistant_id': assistantId,
      'company_id': companyId,
      'user_id': userId,
      'file_name': fileName,
      'file_type': fileType,
      'mime_type': mimeType,
      'file_size': fileSize,
      'file_url': fileUrl,
      'openai_file_id': openaiFileId,
      'status': status,
      'error_message': errorMessage,
      'extracted_text': extractedText,
      'analysis_status': analysisStatus,
      'analysis_results': analysisResults,
      'created_at': createdAt.toIso8601String(),
      'analyzed_at': analyzedAt?.toIso8601String(),
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
    switch (status) {
      case 'uploaded':
        return 'Đã tải lên';
      case 'processing':
        return 'Đang xử lý';
      case 'analyzed':
        return 'Đã phân tích';
      case 'error':
        return 'Lỗi';
      default:
        return status;
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

  /// Check if uploaded
  bool get isUploaded => status == 'uploaded';

  /// Check if currently processing
  bool get isProcessing => status == 'processing';

  /// Check if processing completed
  bool get isAnalyzed => status == 'analyzed';

  /// Check if processing failed
  bool get hasError => status == 'error';

  /// Check if file has been analyzed
  bool get hasAnalysis =>
      analysisResults != null && analysisResults!.isNotEmpty;

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

  AIUploadedFile copyWith({
    String? id,
    String? assistantId,
    String? companyId,
    String? userId,
    String? fileName,
    String? fileType,
    String? mimeType,
    int? fileSize,
    String? fileUrl,
    String? openaiFileId,
    String? status,
    String? errorMessage,
    String? extractedText,
    String? analysisStatus,
    Map<String, dynamic>? analysisResults,
    DateTime? createdAt,
    DateTime? analyzedAt,
  }) {
    return AIUploadedFile(
      id: id ?? this.id,
      assistantId: assistantId ?? this.assistantId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      openaiFileId: openaiFileId ?? this.openaiFileId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      extractedText: extractedText ?? this.extractedText,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      analysisResults: analysisResults ?? this.analysisResults,
      createdAt: createdAt ?? this.createdAt,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }

  @override
  String toString() {
    return 'AIUploadedFile(id: $id, fileName: $fileName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIUploadedFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
