import 'package:equatable/equatable.dart';

/// Document model representing files stored in Google Drive
class Document extends Equatable {
  final String id;
  final String googleDriveFileId;
  final String? googleDriveWebViewLink;
  final String? googleDriveDownloadLink;
  final String fileName;
  final String fileType;
  final int? fileSize;
  final String? fileExtension;
  final String companyId;
  final String uploadedBy;
  final String documentType;
  final String? category;
  final List<String>? tags;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  const Document({
    required this.id,
    required this.googleDriveFileId,
    this.googleDriveWebViewLink,
    this.googleDriveDownloadLink,
    required this.fileName,
    required this.fileType,
    this.fileSize,
    this.fileExtension,
    required this.companyId,
    required this.uploadedBy,
    this.documentType = 'general',
    this.category,
    this.tags,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  });

  /// Create Document from JSON
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      googleDriveFileId: json['google_drive_file_id'] as String,
      googleDriveWebViewLink: json['google_drive_web_view_link'] as String?,
      googleDriveDownloadLink: json['google_drive_download_link'] as String?,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int?,
      fileExtension: json['file_extension'] as String?,
      companyId: json['company_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      documentType: json['document_type'] as String? ?? 'general',
      category: json['category'] as String?,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List) 
          : null,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  /// Convert Document to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'google_drive_file_id': googleDriveFileId,
      'google_drive_web_view_link': googleDriveWebViewLink,
      'google_drive_download_link': googleDriveDownloadLink,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'file_extension': fileExtension,
      'company_id': companyId,
      'uploaded_by': uploadedBy,
      'document_type': documentType,
      'category': category,
      'tags': tags,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  /// Copy with method for immutability
  Document copyWith({
    String? id,
    String? googleDriveFileId,
    String? googleDriveWebViewLink,
    String? googleDriveDownloadLink,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? fileExtension,
    String? companyId,
    String? uploadedBy,
    String? documentType,
    String? category,
    List<String>? tags,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return Document(
      id: id ?? this.id,
      googleDriveFileId: googleDriveFileId ?? this.googleDriveFileId,
      googleDriveWebViewLink: googleDriveWebViewLink ?? this.googleDriveWebViewLink,
      googleDriveDownloadLink: googleDriveDownloadLink ?? this.googleDriveDownloadLink,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
      companyId: companyId ?? this.companyId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      documentType: documentType ?? this.documentType,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Get file size in human readable format
  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = fileSize!.toDouble();
    var unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  /// Get icon based on file type
  String get fileIcon {
    if (fileType.contains('pdf')) return '📄';
    if (fileType.contains('image')) return '🖼️';
    if (fileType.contains('video')) return '🎥';
    if (fileType.contains('audio')) return '🎵';
    if (fileType.contains('word') || fileType.contains('document')) return '📝';
    if (fileType.contains('excel') || fileType.contains('spreadsheet')) return '📊';
    if (fileType.contains('powerpoint') || fileType.contains('presentation')) return '📊';
    if (fileType.contains('zip') || fileType.contains('rar')) return '🗜️';
    return '📎';
  }

  @override
  List<Object?> get props => [
        id,
        googleDriveFileId,
        googleDriveWebViewLink,
        googleDriveDownloadLink,
        fileName,
        fileType,
        fileSize,
        fileExtension,
        companyId,
        uploadedBy,
        documentType,
        category,
        tags,
        description,
        createdAt,
        updatedAt,
        deletedAt,
        isDeleted,
      ];
}

/// Document types enum
enum DocumentType {
  general('general', 'Tổng quát'),
  contract('contract', 'Hợp đồng'),
  invoice('invoice', 'Hóa đơn'),
  report('report', 'Báo cáo'),
  policy('policy', 'Chính sách'),
  procedure('procedure', 'Quy trình'),
  other('other', 'Khác');

  final String value;
  final String label;

  const DocumentType(this.value, this.label);

  static DocumentType fromValue(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.general,
    );
  }
}
