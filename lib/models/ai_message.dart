/// AI Message Model
/// Represents a chat message in the AI conversation
class AIMessage {
  final String id;
  final String assistantId;
  final String companyId;
  final String? userId;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final List<MessageAttachment> attachments;
  final String? openaiMessageId;
  final String? openaiRunId;
  final String? analysisType;
  final Map<String, dynamic>? analysisResults;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double estimatedCost;
  final DateTime createdAt;

  const AIMessage({
    required this.id,
    required this.assistantId,
    required this.companyId,
    this.userId,
    required this.role,
    required this.content,
    required this.attachments,
    this.openaiMessageId,
    this.openaiRunId,
    this.analysisType,
    this.analysisResults,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.estimatedCost,
    required this.createdAt,
  });

  /// Create from Supabase JSON
  factory AIMessage.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List? ?? [];
    final attachments = attachmentsJson
        .map((a) => MessageAttachment.fromJson(a as Map<String, dynamic>))
        .toList();

    return AIMessage(
      id: json['id'] as String,
      assistantId: json['assistant_id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String?,
      role: json['role'] as String,
      content: json['content'] as String,
      attachments: attachments,
      openaiMessageId: json['openai_message_id'] as String?,
      openaiRunId: json['openai_run_id'] as String?,
      analysisType: json['analysis_type'] as String?,
      analysisResults: json['analysis_results'] as Map<String, dynamic>?,
      promptTokens: json['prompt_tokens'] as int? ?? 0,
      completionTokens: json['completion_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assistant_id': assistantId,
      'company_id': companyId,
      'user_id': userId,
      'role': role,
      'content': content,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'openai_message_id': openaiMessageId,
      'openai_run_id': openaiRunId,
      'analysis_type': analysisType,
      'analysis_results': analysisResults,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
      'estimated_cost': estimatedCost,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if this is a user message
  bool get isUser => role == 'user';

  /// Check if this is an assistant message
  bool get isAssistant => role == 'assistant';

  /// Check if this is a system message
  bool get isSystem => role == 'system';

  /// Check if message has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if message has analysis results
  bool get hasAnalysis => analysisResults != null;

  AIMessage copyWith({
    String? id,
    String? assistantId,
    String? companyId,
    String? userId,
    String? role,
    String? content,
    List<MessageAttachment>? attachments,
    String? openaiMessageId,
    String? openaiRunId,
    String? analysisType,
    Map<String, dynamic>? analysisResults,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    double? estimatedCost,
    DateTime? createdAt,
  }) {
    return AIMessage(
      id: id ?? this.id,
      assistantId: assistantId ?? this.assistantId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      openaiMessageId: openaiMessageId ?? this.openaiMessageId,
      openaiRunId: openaiRunId ?? this.openaiRunId,
      analysisType: analysisType ?? this.analysisType,
      analysisResults: analysisResults ?? this.analysisResults,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AIMessage(id: $id, role: $role, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Message Attachment Model
class MessageAttachment {
  final String type; // 'pdf', 'image', 'excel', etc.
  final String url;
  final String name;
  final int size;
  final String? mimeType;

  const MessageAttachment({
    required this.type,
    required this.url,
    required this.name,
    required this.size,
    this.mimeType,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      type: json['type'] as String,
      url: json['url'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
      mimeType: json['mime_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'name': name,
      'size': size,
      'mime_type': mimeType,
    };
  }

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'MessageAttachment(name: $name, type: $type, size: $formattedSize)';
  }
}
