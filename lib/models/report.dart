/// Report Model
/// Represents a business report with metadata
class Report {
  final String id;
  final String title;
  final String type; // 'financial', 'operational', 'hr', 'custom'
  final String? companyId;
  final String? companyName;
  final DateTime generatedAt;
  final String period; // 'weekly', 'monthly', 'quarterly', 'yearly'
  final String status; // 'ready', 'generating', 'failed'
  final String? fileUrl;
  final Map<String, dynamic>? metadata;

  Report({
    required this.id,
    required this.title,
    required this.type,
    this.companyId,
    this.companyName,
    required this.generatedAt,
    required this.period,
    required this.status,
    this.fileUrl,
    this.metadata,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      companyId: json['company_id'] as String?,
      companyName: json['company_name'] as String?,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      period: json['period'] as String,
      status: json['status'] as String,
      fileUrl: json['file_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'company_id': companyId,
      'company_name': companyName,
      'generated_at': generatedAt.toIso8601String(),
      'period': period,
      'status': status,
      'file_url': fileUrl,
      'metadata': metadata,
    };
  }

  Report copyWith({
    String? id,
    String? title,
    String? type,
    String? companyId,
    String? companyName,
    DateTime? generatedAt,
    String? period,
    String? status,
    String? fileUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      generatedAt: generatedAt ?? this.generatedAt,
      period: period ?? this.period,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
